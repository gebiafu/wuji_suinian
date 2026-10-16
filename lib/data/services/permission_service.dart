import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限封装：按需申请，不启动一次性索要全部权限。
class PermissionService {
  const PermissionService();

  Future<bool> ensureCamera() => _request(Permission.camera);

  /// 相册：Android 13+ 使用 photos，旧版本使用 storage。
  Future<bool> ensureGallery() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final photos = await _request(Permission.photos);
      if (photos) return true;
      return _request(Permission.storage);
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final photos = await _request(Permission.photos);
      if (photos) return true;
      return _request(Permission.storage);
    }
    return true;
  }

  Future<bool> ensureNotification() => _request(Permission.notification);

  Future<bool> _request(Permission permission) async {
    if (kIsWeb) return false;
    try {
      var status = await permission.status;
      if (status.isGranted || status.isLimited || status.isProvisional) {
        return true;
      }
      if (status.isPermanentlyDenied) return false;
      status = await permission.request();
      return status.isGranted || status.isLimited || status.isProvisional;
    } catch (_) {
      // 桌面 / 测试环境不支持权限 API，直接放行由上层兜底。
      return true;
    }
  }

  Future<void> openSettingsPage() async {
    try {
      await openAppSettings();
    } catch (_) {
      // ignore
    }
  }
}