import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Android 清单回归测试。
///
/// 背景：Flutter 模板只把 `INTERNET` 权限声明在 `src/debug` 与 `src/profile`
/// 清单里，`src/main` 里没有。因此 `flutter run` 调试时联网一切正常，
/// 而 release 包（CI 打出的 APK）一联网就报
/// `SocketException: Failed host lookup` —— 症状很像「没网」，极难排查。
///
/// 本测试锁死 `src/main` 必须显式声明联网权限，避免再次回归。
void main() {
  test('main 清单必须声明 INTERNET 权限（release 包联网依赖）', () {
    final file = File('android/app/src/main/AndroidManifest.xml');
    expect(
      file.existsSync(),
      isTrue,
      reason: '未找到 main AndroidManifest.xml，请确认工作目录为项目根目录',
    );

    final content = file.readAsStringSync();
    expect(
      content.contains('android.permission.INTERNET'),
      isTrue,
      reason: 'release 包缺少 INTERNET 权限时，所有网络请求都会 DNS 解析失败；'
          '该权限必须写在 src/main 清单中（debug/profile 清单不会合并进 release 包）',
    );
  });

  test('main 清单必须声明通知与存储相关权限', () {
    final content =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final permission in <String>[
      'android.permission.POST_NOTIFICATIONS',
      'android.permission.CAMERA',
      'android.permission.READ_MEDIA_IMAGES',
    ]) {
      expect(
        content.contains(permission),
        isTrue,
        reason: '缺少 $permission：相应功能在 release 包中会被系统拒绝',
      );
    }
  });
}
