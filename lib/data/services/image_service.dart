import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/paths/app_paths.dart';
import '../../domain/models/settings.dart';
import 'permission_service.dart';

/// 图片来源
enum ImageSourceKind { camera, gallery }

/// 图片服务：拍照 / 相册选图 → 可压缩 → 存入 App 私有目录，数据库只存相对路径。
class ImageService {
  ImageService({
    required this.paths,
    this.permissions = const PermissionService(),
    required this.settingsReader,
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  final AppPaths paths;
  final PermissionService permissions;
  final AppSettings Function() settingsReader;
  final ImagePicker _picker;
  final Random _random = Random();

  /// 拍照（拍完由 UI 预览确认 / 重拍）。
  Future<List<String>> pickFromCamera() async {
    if (!await permissions.ensureCamera()) {
      throw const ImagePickException('未获得相机权限，请在系统设置中开启后重试');
    }
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return <String>[];
    return <String>[await importFile(File(file.path))];
  }

  /// 相册选图，支持多选。
  Future<List<String>> pickFromGallery({bool multiple = true}) async {
    if (!await permissions.ensureGallery()) {
      throw const ImagePickException('未获得相册权限，请在系统设置中开启后重试');
    }
    if (multiple) {
      final files = await _picker.pickMultiImage();
      final result = <String>[];
      for (final file in files) {
        result.add(await importFile(File(file.path)));
      }
      return result;
    }
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return <String>[];
    return <String>[await importFile(File(file.path))];
  }

  /// 把外部文件导入到 images 目录，按设置决定是否压缩。
  Future<String> importFile(File source) async {
    await paths.ensure();
    final settings = settingsReader();
    final fileName = _generateFileName();
    final destination = File(p.join(paths.imagesDirPath, fileName));

    if (settings.compressImage && _isSupportedForCompress(source.path)) {
      try {
        final result = await FlutterImageCompress.compressAndGetFile(
          source.absolute.path,
          destination.path,
          quality: settings.compressQuality.clamp(10, 100),
          minWidth: 1600,
          minHeight: 1600,
        );
        if (result != null) {
          return paths.imageRelativePath(p.basename(result.path));
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('图片压缩失败，回退原图复制: $error');
        }
      }
    }

    await source.copy(destination.path);
    return paths.imageRelativePath(fileName);
  }

  Future<void> deleteByRelativePath(String relativePath) async {
    final file = paths.fileFor(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteMany(List<String> relativePaths) async {
    for (final relative in relativePaths) {
      try {
        await deleteByRelativePath(relative);
      } catch (_) {
        // 单个文件删除失败不影响其它文件
      }
    }
  }

  /// images 目录下全部图片文件。
  Future<List<File>> listImageFiles() async {
    final dir = paths.imagesDir;
    if (!await dir.exists()) return <File>[];
    final entities = await dir.list(followLinks: false).toList();
    return entities
        .whereType<File>()
        .where((f) => !p.basename(f.path).startsWith('.'))
        .toList();
  }

  bool _isSupportedForCompress(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.heic';
  }

  String _generateFileName() {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final salt = _random.nextInt(1 << 20);
    return 'img_${stamp}_$salt.jpg';
  }
}

class ImagePickException implements Exception {
  const ImagePickException(this.message);

  final String message;

  @override
  String toString() => message;
}