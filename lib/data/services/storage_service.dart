import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/paths/app_paths.dart';
import '../../domain/models/views.dart';
import '../db/database.dart';

/// 存储统计：图片占用、数据库大小、孤儿图片清理。
class StorageService {
  StorageService({
    required this.paths,
    required this.dbProvider,
    required this.imageService,
  });

  final AppPaths paths;
  final AppDatabase Function() dbProvider;
  final dynamic imageService;

  Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<int> _fileSize(String path) async {
    final file = File(path);
    return await file.exists() ? file.length() : 0;
  }

  /// 数据库中引用到的所有图片相对路径。
  Future<Set<String>> referencedImagePaths() async {
    final db = dbProvider();
    final rows = await db.select(db.itemImages).get();
    final notes = await db.select(db.bulletNotes).get();
    return <String>{
      ...rows.map((e) => e.relativePath),
      ...notes
          .map((e) => e.imagePath)
          .whereType<String>()
          .where((e) => e.isNotEmpty),
    };
  }

  Future<List<File>> orphanImageFiles() async {
    final referenced = await referencedImagePaths();
    final referencedNames =
        referenced.map((e) => p.basename(e.replaceAll('\\', '/'))).toSet();
    final files = await _listImageFiles();
    return files
        .where((f) => !referencedNames.contains(p.basename(f.path)))
        .toList();
  }

  Future<List<File>> _listImageFiles() async {
    final dir = paths.imagesDir;
    if (!await dir.exists()) return <File>[];
    final entities = await dir.list(followLinks: false).toList();
    return entities.whereType<File>().toList();
  }

  Future<StorageStats> stats() async {
    final db = dbProvider();
    final dbBytes = await _fileSize(paths.dbFilePath) +
        await _fileSize(paths.dbWalPath) +
        await _fileSize(paths.dbShmPath);
    final imageFiles = await _listImageFiles();
    var imageBytes = 0;
    for (final file in imageFiles) {
      imageBytes += await file.length();
    }
    final orphans = await orphanImageFiles();
    var orphanBytes = 0;
    for (final file in orphans) {
      orphanBytes += await file.length();
    }
    final itemCount = (await db.select(db.items).get()).length;
    final noteCount = (await db.select(db.bulletNotes).get()).length;
    final tagCount = (await db.select(db.tags).get()).length;
    return StorageStats(
      dbBytes: dbBytes,
      imageBytes: imageBytes,
      imageCount: imageFiles.length,
      orphanCount: orphans.length,
      orphanBytes: orphanBytes,
      itemCount: itemCount,
      noteCount: noteCount,
      tagCount: tagCount,
    );
  }

  /// 清理无引用图片；dryRun=true 时只统计不删除。
  Future<int> cleanOrphans({bool dryRun = false}) async {
    final orphans = await orphanImageFiles();
    if (dryRun) return orphans.length;
    var removed = 0;
    for (final file in orphans) {
      try {
        await file.delete();
        removed++;
      } catch (_) {
        // 忽略单文件失败
      }
    }
    return removed;
  }

  Future<int> tempDirBytes() => _dirSize(paths.tempDir);
}