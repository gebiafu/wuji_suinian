import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/services/image_service.dart';

/// 本地图片（数据库只存相对路径）
class LocalImage extends ConsumerWidget {
  const LocalImage({
    super.key,
    required this.relativePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 10,
    this.placeholderIcon = Icons.image_outlined,
  });

  final String relativePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paths = ref.watch(appPathsProvider);
    final file = paths.fileFor(relativePath);
    final exists = file.existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: exists
          ? Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              cacheWidth: width == null ? null : (width! * 2).round(),
              errorBuilder: (context, error, stack) => _placeholder(context),
            )
          : _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: theme.colorScheme.outline),
    );
  }
}

/// 大图浏览：左右滑动 + 双指缩放
class ImageGalleryViewer extends StatefulWidget {
  const ImageGalleryViewer({
    super.key,
    required this.relativePaths,
    this.initialIndex = 0,
  });

  final List<String> relativePaths;
  final int initialIndex;

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.relativePaths.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.relativePaths.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: LocalImage(
                relativePath: widget.relativePaths[index],
                fit: BoxFit.contain,
                radius: 0,
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> showImageSourceSheet(
  BuildContext context, {
  required Future<void> Function(ImageSourceKind kind) onPick,
}) async {
  final kind = await showModalBottomSheet<ImageSourceKind>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(context, ImageSourceKind.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('从相册选择'),
            onTap: () => Navigator.pop(context, ImageSourceKind.gallery),
          ),
        ],
      ),
    ),
  );
  if (kind != null) {
    await onPick(kind);
  }
}

/// 图片选择 / 预览字段（新增、编辑物品）
class ImagePickerField extends ConsumerStatefulWidget {
  const ImagePickerField({
    super.key,
    required this.relativePaths,
    required this.onChanged,
    this.maxImages = 9,
  });

  final List<String> relativePaths;
  final ValueChanged<List<String>> onChanged;
  final int maxImages;

  @override
  ConsumerState<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends ConsumerState<ImagePickerField> {
  bool _busy = false;

  Future<void> _pick(ImageSourceKind kind) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(imageServiceProvider);
      final picked = kind == ImageSourceKind.camera
          ? await service.pickFromCamera()
          : await service.pickFromGallery(multiple: true);
      if (picked.isEmpty) return;
      final next = <String>[...widget.relativePaths, ...picked];
      widget.onChanged(next.take(widget.maxImages).toList());
    } on ImagePickException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('选择图片失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              for (var i = 0; i < widget.relativePaths.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => ImageGalleryViewer(
                              relativePaths: widget.relativePaths,
                              initialIndex: i,
                            ),
                          ),
                        ),
                        child: LocalImage(
                          relativePath: widget.relativePaths[i],
                          width: 92,
                          height: 92,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: InkWell(
                          onTap: () {
                            final next = List<String>.of(widget.relativePaths)
                              ..removeAt(i);
                            // 本地文件的实际删除在保存时统一处理，
                            // 避免用户误删后取消编辑导致图片丢失
                            widget.onChanged(next);
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.relativePaths.length < widget.maxImages)
                InkWell(
                  onTap: () => showImageSourceSheet(context, onPick: _pick),
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '最多 ${widget.maxImages} 张；图片原始文件保存在 App 私有目录，'
          '数据库中只记录路径（可多选、可滑动预览）',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}