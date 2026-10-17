"""物记碎念 · 应用图标光栅化脚本（纯标准库，无 PIL/numpy 依赖）。

把 design/app_icon.svg 的设计用 SDF（带符号距离场）+ 4x 超采样抗锯齿
渲染成 PNG，并生成：
  - assets/app_icon.png                       512（关于页展示）
  - android/app/src/main/res/mipmap-mdpi/ic_launcher.png      48
  - android/app/src/main/res/mipmap-hdpi/ic_launcher.png      72
  - android/app/src/main/res/mipmap-xhdpi/ic_launcher.png     96
  - android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png    144
  - android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png   192

用法：python design/render_icon.py
"""
import math
import os
import struct
import zlib

# ---------------------------------------------------------------- 设计参数（512 坐标系，与 app_icon.svg 一致）
BG_TOP = (62, 148, 138)     # #3E948A
BG_BOTTOM = (34, 86, 79)    # #22564F
WHITE = (255, 255, 255)
HANDLE = (42, 107, 100)     # #2A6B64

CANVAS = 512
SS = 4  # 超采样倍数


def rounded_rect_sdf(x, y, cx, cy, hw, hh, r):
    dx = abs(x - cx) - (hw - r)
    dy = abs(y - cy) - (hh - r)
    dxm = dx if dx > 0 else 0.0
    dym = dy if dy > 0 else 0.0
    outside = math.hypot(dxm, dym)
    inside = min(max(dx, dy), 0.0)
    return outside + inside - r


def circle_sdf(x, y, cx, cy, r):
    return math.hypot(x - cx, y - cy) - r


def sample(x, y):
    """返回 (r, g, b)。图层顺序：背景 → 盒盖 → 盒身 → 把手 → 气泡 → 点。"""
    # 背景：圆角方形 + 135° 线性渐变
    if rounded_rect_sdf(x, y, 256, 256, 256, 256, 118) > 0:
        return None  # 画布外（透明区域，用角落色填 0）
    t = (x + y) / 1024.0
    r = BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t
    g = BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t
    b = BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t

    # 盒盖 / 盒身
    if rounded_rect_sdf(x, y, 232, 302, 116, 34, 18) <= 0 or \
       rounded_rect_sdf(x, y, 232, 384, 99, 44, 16) <= 0:
        r, g, b = WHITE
    # 抽屉把手
    if rounded_rect_sdf(x, y, 232, 384, 34, 8, 8) <= 0:
        r, g, b = HANDLE
    # 气泡（含尾巴圆）
    if rounded_rect_sdf(x, y, 356, 170, 62, 46, 28) <= 0 or \
       circle_sdf(x, y, 306, 226, 13) <= 0:
        r, g, b = WHITE
    # 气泡三点
    for dx in (-24.0, 0.0, 24.0):
        if circle_sdf(x, y, 356 + dx, 170, 9) <= 0:
            r, g, b = HANDLE
    return r, g, b


def render(size):
    """以 SS 倍超采样渲染 size×size 图标，返回 RGB 行列表。"""
    scale = CANVAS / size
    rows = []
    for py in range(size):
        row = bytearray()
        for px in range(size):
            ar = ag = ab = 0.0
            hit = 0
            for sy in range(SS):
                for sx in range(SS):
                    x = (px + (sx + 0.5) / SS) * scale
                    y = (py + (sy + 0.5) / SS) * scale
                    c = sample(x, y)
                    if c is not None:
                        ar += c[0]
                        ag += c[1]
                        ab += c[2]
                        hit += 1
            if hit == 0:
                row += bytes((0, 0, 0))
            else:
                row += bytes(
                    (int(ar / hit + 0.5), int(ag / hit + 0.5), int(ab / hit + 0.5))
                )
        rows.append(row)
    return rows


def write_png(path, rows, size):
    raw = b''.join(b'\x00' + bytes(row) for row in rows)

    def chunk(tag, data):
        body = tag + data
        return (
            struct.pack('>I', len(data))
            + body
            + struct.pack('>I', zlib.crc32(body) & 0xFFFFFFFF)
        )

    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(raw, 9))
    png += chunk(b'IEND', b'')
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'wb') as f:
        f.write(png)
    print(f'  {path}  {size}x{size}  {len(png)} bytes')


def resize_area(rows, src_size, dst_size):
    """面积平均缩放（box filter），用于 512 → 小尺寸。"""
    scale = src_size / dst_size
    out = []
    for dy in range(dst_size):
        y0 = dy * scale
        y1 = y0 + scale
        iy0 = int(y0)
        iy1 = min(src_size, int(math.ceil(y1)))
        row = bytearray()
        for dx in range(dst_size):
            x0 = dx * scale
            x1 = x0 + scale
            ix0 = int(x0)
            ix1 = min(src_size, int(math.ceil(x1)))
            rs = gs = bs = n = 0
            for sy in range(iy0, iy1):
                srow = rows[sy]
                for sx in range(ix0, ix1):
                    o = sx * 3
                    rs += srow[o]
                    gs += srow[o + 1]
                    bs += srow[o + 2]
                    n += 1
            row += bytes((rs // n, gs // n, bs // n))
        out.append(row)
    return out


def main():
    print('渲染 512x512 主图（4x 超采样）…')
    base = render(512)

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    write_png(os.path.join(root, 'assets', 'app_icon.png'), base, 512)

    targets = [
        ('mipmap-mdpi', 48),
        ('mipmap-hdpi', 72),
        ('mipmap-xhdpi', 96),
        ('mipmap-xxhdpi', 144),
        ('mipmap-xxxhdpi', 192),
    ]
    print('生成各分辨率 launcher 图标…')
    for folder, size in targets:
        small = resize_area(base, 512, size)
        write_png(
            os.path.join(root, 'android', 'app', 'src', 'main', 'res', folder, 'ic_launcher.png'),
            small,
            size,
        )
    print('完成。')


if __name__ == '__main__':
    main()
