import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

/// 本地目录规划。
///
/// 数据库：`<root>/db/app.db`
/// 原图：  `<root>/asset/images/xxx.jpg` （数据库中只存相对路径，不存 blob）
class AppPaths {
  AppPaths({required this.rootDir});

  final Directory rootDir;

  String get rootPath => rootDir.path;

  String get dbDirPath => p.join(rootPath, 'db');
  String get dbFilePath => p.join(dbDirPath, AppConstants.dbFileName);
  String get dbWalPath => '$dbFilePath-wal';
  String get dbShmPath => '$dbFilePath-shm';

  String get imagesDirPath => p.join(rootPath, 'asset', 'images');
  String get imageRelativePrefix => p.join('asset', 'images');

  String get tempDirPath => p.join(rootPath, 'temp');
  String get exportDirPath => p.join(rootPath, 'export');
  String get conflictDirPath => p.join(rootPath, 'conflict');
  String get restoreBackupDirPath => p.join(rootPath, 'restore_backup');

  Directory get imagesDir => Directory(imagesDirPath);
  Directory get tempDir => Directory(tempDirPath);
  Directory get exportDir => Directory(exportDirPath);
  Directory get conflictDir => Directory(conflictDirPath);

  File get dbFile => File(dbFilePath);

  /// 相对路径（入库）→ 绝对路径文件
  File fileFor(String relativePath) => File(p.join(rootPath, relativePath));

  /// 绝对路径 → 相对路径（入库）
  String relativize(String absolutePath) =>
      p.relative(absolutePath, from: rootPath).replaceAll('\\', '/');

  /// 图片文件名 → 入库相对路径
  String imageRelativePath(String fileName) =>
      p.join(imageRelativePrefix, fileName).replaceAll('\\', '/');

  Future<void> ensure() async {
    for (final dir in <Directory>[
      rootDir,
      Directory(dbDirPath),
      imagesDir,
      tempDir,
      exportDir,
      conflictDir,
      Directory(restoreBackupDirPath),
    ]) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  static Future<AppPaths> resolve({String? rootOverride}) async {
    final String rootPath;
    if (rootOverride != null) {
      rootPath = rootOverride;
    } else {
      final docs = await getApplicationDocumentsDirectory();
      rootPath = p.join(docs.path, 'wuji_suinian');
    }
    final paths = AppPaths(rootDir: Directory(rootPath));
    await paths.ensure();
    return paths;
  }
}