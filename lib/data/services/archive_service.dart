import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import '../../core/paths/app_paths.dart';
import '../../core/utils/hash_utils.dart';
import '../../core/utils/time_utils.dart';
import '../db/database.dart';

/// 导出包结构说明（manifest.json）
class ArchiveManifest {
  const ArchiveManifest({
    this.app = 'wuji_suinian',
    this.version = 1,
    this.exportedAt = 0,
    this.dbMd5 = '',
    this.itemCount = 0,
    this.noteCount = 0,
    this.imageCount = 0,
  });

  final String app;
  final int version;
  final int exportedAt;
  final String dbMd5;
  final int itemCount;
  final int noteCount;
  final int imageCount;

  Map<String, Object?> toJson() => <String, Object?>{
        'app': app,
        'version': version,
        'exportedAt': exportedAt,
        'dbMd5': dbMd5,
        'itemCount': itemCount,
        'noteCount': noteCount,
        'imageCount': imageCount,
      };

  static ArchiveManifest fromJson(Map<String, Object?> json) => ArchiveManifest(
        app: json['app'] as String? ?? 'wuji_suinian',
        version: (json['version'] as num?)?.toInt() ?? 1,
        exportedAt: (json['exportedAt'] as num?)?.toInt() ?? 0,
        dbMd5: json['dbMd5'] as String? ?? '',
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
        noteCount: (json['noteCount'] as num?)?.toInt() ?? 0,
        imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
      );
}

class ArchiveImportOutcome {
  const ArchiveImportOutcome({
    required this.success,
    required this.message,
    this.manifest,
    this.restoredImages = 0,
    this.localBackupPath,
  });

  final bool success;
  final String message;
  final ArchiveManifest? manifest;
  final int restoredImages;
  final String? localBackupPath;
}

/// 导出 / 导入 ZIP（db + 图片），WebDAV 之外的兜底备份方案。
class ArchiveService {
  ArchiveService({required this.paths});

  final AppPaths paths;

  static const String dbEntryName = 'db/${AppConstants.dbFileName}';

  static const String manifestEntryName = 'manifest.json';

  /// 打包成 zip：`<targetDir>/wuji_suinian_yyyyMMdd_HHmmss.zip`
  Future<File> exportArchive({
    required AppDatabase db,
    String? targetDirPath,
  }) async {
    await db.checkpoint();
    await paths.ensure();

    final dbFile = File(paths.dbFilePath);
    final dbBytes = await dbFile.readAsBytes();
    final dbMd5 = HashUtils.md5OfBytes(dbBytes);

    final itemCount = (await db.select(db.items).get()).length;
    final noteCount = (await db.select(db.bulletNotes).get()).length;

    final archive = Archive();
    archive.addFile(
      ArchiveFile('db/${p.basename(paths.dbFilePath)}', dbBytes.length, dbBytes),
    );

    var imageCount = 0;
    final imagesDir = paths.imagesDir;
    if (await imagesDir.exists()) {
      final files = (await imagesDir.list().toList()).whereType<File>();
      for (final file in files) {
        final bytes = await file.readAsBytes();
        archive.addFile(
          ArchiveFile('asset/images/${p.basename(file.path)}', bytes.length, bytes),
        );
        imageCount++;
      }
    }

    final manifest = ArchiveManifest(
      exportedAt: TimeUtils.nowMs(),
      dbMd5: dbMd5,
      itemCount: itemCount,
      noteCount: noteCount,
      imageCount: imageCount,
    );
    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    archive.addFile(
      ArchiveFile(manifestEntryName, manifestBytes.length, manifestBytes),
    );

    final encoded = ZipEncoder().encode(archive);
    final dirPath = targetDirPath ?? paths.exportDirPath;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final fileName =
        'wuji_suinian_${TimeUtils.compactStamp(DateTime.now())}.zip';
    final outFile = File(p.join(dir.path, fileName));
    await outFile.writeAsBytes(encoded, flush: true);
    return outFile;
  }

  /// 读取 zip 元信息（不写盘），用于导入前二次确认。
  Future<ArchiveImportOutcome> inspect(File zipFile) async {
    try {
      final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
      final manifestFile = archive.files.firstWhere(
        (f) => f.isFile && p.basename(f.name) == manifestEntryName,
        orElse: () => ArchiveFile('', 0, <int>[]),
      );
      if (manifestFile.name.isEmpty) {
        return const ArchiveImportOutcome(
          success: false,
          message: '压缩包缺少 manifest.json，无法识别为有效备份包',
        );
      }
      final manifest = ArchiveManifest.fromJson(
        Map<String, Object?>.from(
          jsonDecode(utf8.decode(_contentOf(manifestFile))) as Map<dynamic, dynamic>,
        ),
      );
      return ArchiveImportOutcome(
        success: true,
        message: '备份包有效',
        manifest: manifest,
      );
    } catch (error) {
      return ArchiveImportOutcome(
        success: false,
        message: '压缩包解析失败：$error',
      );
    }
  }

  /// 导入（覆盖本地）：
  /// 1. 校验 manifest 与 db md5，校验失败拒绝导入
  /// 2. 先把当前 db 备份到 restore_backup 目录
  /// 3. 覆盖 db 与图片目录
  ///
  /// 调用方必须在调用前关闭数据库连接，调用后重新加载数据库。
  Future<ArchiveImportOutcome> importArchive(File zipFile) async {
    final inspectResult = await inspect(zipFile);
    if (!inspectResult.success) return inspectResult;
    final manifest = inspectResult.manifest!;

    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    final dbEntry = archive.files.firstWhere(
      (f) => f.isFile && p.basename(f.name) == p.basename(paths.dbFilePath),
      orElse: () => ArchiveFile('', 0, <int>[]),
    );
    if (dbEntry.name.isEmpty) {
      return const ArchiveImportOutcome(
        success: false,
        message: '压缩包中缺少数据库文件',
      );
    }

    final dbBytes = _contentOf(dbEntry);
    final actualMd5 = HashUtils.md5OfBytes(dbBytes);
    if (manifest.dbMd5.isNotEmpty && actualMd5 != manifest.dbMd5) {
      return ArchiveImportOutcome(
        success: false,
        message: 'md5 校验失败（期望 ${manifest.dbMd5}，实际 $actualMd5），已拒绝导入以保护数据',
      );
    }

    await paths.ensure();

    // 1. 先备份当前本地数据
    String? localBackupPath;
    final currentDb = File(paths.dbFilePath);
    if (await currentDb.exists()) {
      final backupFile = File(p.join(
        paths.restoreBackupDirPath,
        'app_before_import_${TimeUtils.compactStamp(DateTime.now())}.db',
      ));
      await currentDb.copy(backupFile.path);
      localBackupPath = backupFile.path;
    }

    // 2. 覆盖数据库（WAL / SHM 必须一起清掉，否则残留旧事务）
    await currentDb.writeAsBytes(dbBytes, flush: true);
    for (final leftover in <String>[paths.dbWalPath, paths.dbShmPath]) {
      final file = File(leftover);
      if (await file.exists()) await file.delete();
    }

    // 3. 还原图片
    var restoredImages = 0;
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final normalized = entry.name.replaceAll('\\', '/');
      if (!normalized.contains('asset/images/')) continue;
      final fileName = p.basename(normalized);
      final outFile = File(p.join(paths.imagesDirPath, fileName));
      await outFile.writeAsBytes(_contentOf(entry), flush: true);
      restoredImages++;
    }

    return ArchiveImportOutcome(
      success: true,
      message: '导入完成：物品 ${manifest.itemCount} 条、碎念 ${manifest.noteCount} 条、图片 $restoredImages 张',
      manifest: manifest,
      restoredImages: restoredImages,
      localBackupPath: localBackupPath,
    );
  }

  List<int> _contentOf(ArchiveFile file) => file.content;
}