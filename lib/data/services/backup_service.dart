import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/paths/app_paths.dart';
import '../../core/utils/hash_utils.dart';
import '../../core/utils/time_utils.dart';
import '../../domain/models/backup_models.dart';
import '../../domain/models/settings.dart';
import '../db/database.dart';
import 'webdav/remote_store.dart';
import 'webdav/sync_policy.dart';

/// 单文件同步基准记录
class SyncFileStamp {
  const SyncFileStamp({required this.size, required this.modified});
  final int size;
  final int modified;

  Map<String, Object?> toJson() => <String, Object?>{
        'size': size,
        'modified': modified,
      };

  static SyncFileStamp fromJson(Map<String, Object?> json) => SyncFileStamp(
        size: (json['size'] as num?)?.toInt() ?? 0,
        modified: (json['modified'] as num?)?.toInt() ?? 0,
      );
}

/// 同步状态：记录上次同步后的内容指纹，用于判断哪一端发生了修改。
class SyncState {
  const SyncState({
    this.lastSyncAt,
    this.dbMd5,
    this.dbModifiedMs,
    this.images = const <String, SyncFileStamp>{},
  });

  final int? lastSyncAt;
  final String? dbMd5;
  final int? dbModifiedMs;
  final Map<String, SyncFileStamp> images;

  Map<String, Object?> toJson() => <String, Object?>{
        'lastSyncAt': lastSyncAt,
        'dbMd5': dbMd5,
        'dbModifiedMs': dbModifiedMs,
        'images': images.map((key, value) => MapEntry(key, value.toJson())),
      };

  static SyncState fromJson(Map<String, Object?> json) {
    final rawImages = json['images'];
    final images = <String, SyncFileStamp>{};
    if (rawImages is Map) {
      rawImages.forEach((key, value) {
        if (value is Map) {
          images['$key'] = SyncFileStamp.fromJson(
            Map<String, Object?>.from(value),
          );
        }
      });
    }
    return SyncState(
      lastSyncAt: (json['lastSyncAt'] as num?)?.toInt(),
      dbMd5: json['dbMd5'] as String?,
      dbModifiedMs: (json['dbModifiedMs'] as num?)?.toInt(),
      images: images,
    );
  }
}

/// 快照清单
class SnapshotManifest {
  const SnapshotManifest({
    required this.createdAt,
    required this.dbMd5,
    required this.dbSize,
    this.itemCount = 0,
    this.noteCount = 0,
    this.images = const <String, SyncFileStamp>{},
  });

  final int createdAt;
  final String dbMd5;
  final int dbSize;
  final int itemCount;
  final int noteCount;
  final Map<String, SyncFileStamp> images;

  int get imageCount => images.length;

  Map<String, Object?> toJson() => <String, Object?>{
        'createdAt': createdAt,
        'dbMd5': dbMd5,
        'dbSize': dbSize,
        'itemCount': itemCount,
        'noteCount': noteCount,
        'images': images.map((key, value) => MapEntry(key, value.toJson())),
      };

  static SnapshotManifest fromJson(Map<String, Object?> json) {
    final rawImages = json['images'];
    final images = <String, SyncFileStamp>{};
    if (rawImages is Map) {
      rawImages.forEach((key, value) {
        if (value is Map) {
          images['$key'] =
              SyncFileStamp.fromJson(Map<String, Object?>.from(value));
        }
      });
    }
    return SnapshotManifest(
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      dbMd5: json['dbMd5'] as String? ?? '',
      dbSize: (json['dbSize'] as num?)?.toInt() ?? 0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      noteCount: (json['noteCount'] as num?)?.toInt() ?? 0,
      images: images,
    );
  }
}

/// WebDAV 备份 / 恢复 / 同步核心服务。
///
/// 远端目录结构（对应需求文档）：
/// ```
/// <remoteDir>/db/app.db          最新正式备份
/// <remoteDir>/db/app.db.tmp      上传中间文件（上传完成 + 校验后再 MOVE 覆盖正式文件）
/// <remoteDir>/md5/app.db.md5     数据库 md5 校验文件
/// <remoteDir>/images/**          全量图片目录
/// <remoteDir>/snapshots/<id>/    历史快照（db + md5 + manifest）
/// <remoteDir>/state/sync_state.json  同步状态（判断哪端更新）
/// ```
class BackupService {
  BackupService({
    required this.paths,
    required this.dbProvider,
    required this.remoteStoreFactory,
    required this.settingsReader,
    this.logger,
  });

  final AppPaths paths;
  final AppDatabase Function() dbProvider;
  final Future<RemoteStore> Function() remoteStoreFactory;
  final AppSettings Function() settingsReader;

  /// 同步日志落库回调（由上层写入 backup_records 表）。
  final Future<void> Function(BackupReport report)? logger;

  static const String dbPath = 'db/app.db';
  static const String dbTmpPath = 'db/app.db.tmp';
  static const String md5Path = 'md5/app.db.md5';
  static const String imagesDir = 'images';
  static const String snapshotsDir = 'snapshots';
  static const String statePath = 'state/sync_state.json';

  // ------------------------------------------------------------ 公共入口

  /// 连接测试
  Future<void> ping() async {
    final remote = await remoteStoreFactory();
    await remote.ping();
  }

  Future<void> _ensureStructure(RemoteStore remote) async {
    for (final dir in <String>[
      'db',
      'md5',
      imagesDir,
      snapshotsDir,
      'state',
    ]) {
      await remote.ensureDir(dir);
    }
  }

  /// 手动备份：db + 全量图片 + md5 文件 + 快照。
  Future<BackupReport> backup({bool createSnapshot = true}) async {
    final startedAt = DateTime.now();
    try {
      final remote = await remoteStoreFactory();
      await _ensureStructure(remote);

      final db = dbProvider();
      await db.checkpoint();

      final imageResult = await _uploadImages(remote, state: null);

      final dbBytes = await paths.dbFile.readAsBytes();
      final dbMd5 = HashUtils.md5OfBytes(dbBytes);
      await _uploadDatabase(remote, dbBytes);
      await remote.upload(
        md5Path,
        utf8.encode(dbMd5),
        contentType: 'text/plain; charset=utf-8',
      );

      String? snapshotId;
      if (createSnapshot) {
        snapshotId = await _writeSnapshot(
          remote,
          dbBytes: dbBytes,
          dbMd5: dbMd5,
          stamps: imageResult.stamps,
        );
        await pruneSnapshots(settingsReader().snapshotKeep);
      }

      final state = SyncState(
        lastSyncAt: TimeUtils.nowMs(),
        dbMd5: dbMd5,
        dbModifiedMs: TimeUtils.nowMs(),
        images: imageResult.stamps,
      );
      await _writeState(remote, state);

      final report = BackupReport(
        type: 'backup',
        success: true,
        message: snapshotId == null
            ? '备份完成'
            : '备份完成，已生成快照 $snapshotId',
        uploadedFiles: imageResult.uploaded + 1,
        skippedFiles: imageResult.skipped,
        totalBytes: imageResult.bytes + dbBytes.length,
        snapshotId: snapshotId,
        startedAt: startedAt,
        finishedAt: DateTime.now(),
      );
      await logger?.call(report);
      return report;
    } catch (error) {
      final report = BackupReport(
        type: 'backup',
        success: false,
        message: '备份失败：$error',
        startedAt: startedAt,
        finishedAt: DateTime.now(),
      );
      await logger?.call(report);
      return report;
    }
  }

  /// 从远端恢复（覆盖本地）。snapshot 为 null 时使用最新正式备份。
  Future<BackupReport> restore({
    SnapshotInfo? snapshot,
    required Future<void> Function() closeDb,
    required Future<void> Function() reopenDb,
  }) async {
    final startedAt = DateTime.now();
    try {
      final remote = await remoteStoreFactory();
      final remoteDbPath = snapshot == null
          ? dbPath
          : '${snapshot.remoteDir}/app.db';
      final remoteMd5Path = snapshot == null
          ? md5Path
          : '${snapshot.remoteDir}/app.db.md5';

      final dbBytes = await remote.download(remoteDbPath);
      if (dbBytes == null) {
        throw StateError('远端没有可恢复的备份文件（$remoteDbPath）');
      }

      final md5Bytes = await remote.download(remoteMd5Path);
      final expectedMd5 =
          md5Bytes == null ? null : utf8.decode(md5Bytes, allowMalformed: true).trim();
      final actualMd5 = HashUtils.md5OfBytes(dbBytes);
      if (expectedMd5 != null && expectedMd5.isNotEmpty && expectedMd5 != actualMd5) {
        throw StateError('md5 校验失败，已拒绝恢复（期望 $expectedMd5，实际 $actualMd5）');
      }

      final manifest = snapshot == null
          ? null
          : await _readSnapshotManifest(remote, snapshot.id);

      // 覆盖前先本地留底
      final localBackup = await _backupLocalDb('before_restore');
      await closeDb();
      try {
        await paths.dbFile.writeAsBytes(dbBytes, flush: true);
        for (final leftover in <String>[paths.dbWalPath, paths.dbShmPath]) {
          final file = File(leftover);
          if (await file.exists()) await file.delete();
        }
      } finally {
        await reopenDb();
      }

      final downloadedImages = await _downloadImages(
        remote,
        baseline: manifest?.images ?? const <String, SyncFileStamp>{},
        overwrite: snapshot != null,
      );

      final report = BackupReport(
        type: 'restore',
        success: true,
        message: '恢复完成（md5 校验通过），恢复图片 $downloadedImages 张'
            '${localBackup == null ? '' : '，覆盖前本地已留底'}',
        downloadedFiles: downloadedImages,
        totalBytes: dbBytes.length,
        snapshotId: snapshot?.id,
        startedAt: startedAt,
        finishedAt: DateTime.now(),
      );
      await logger?.call(report);
      return report;
    } catch (error) {
      final report = BackupReport(
        type: 'restore',
        success: false,
        message: '恢复失败：$error',
        startedAt: startedAt,
        finishedAt: DateTime.now(),
      );
      await logger?.call(report);
      return report;
    }
  }

  /// 双向同步：基于时间戳 + 上次同步 md5 判断，冲突不自动合并。
  Future<BackupReport> sync({
    required Future<void> Function() closeDb,
    required Future<void> Function() reopenDb,
  }) async {
    final startedAt = DateTime.now();
    final conflicts = <ConflictItem>[];
    var uploaded = 0;
    var downloaded = 0;
    var skipped = 0;
    var bytes = 0;
    try {
      final remote = await remoteStoreFactory();
      await _ensureStructure(remote);

      final state = await _readState(remote);
      // 本次同步后本地数据库的内容指纹（下载远端后需同步更新）
      var appliedMd5 = '';
      final db = dbProvider();
      await db.checkpoint();

      final dbBytes = await paths.dbFile.readAsBytes();
      final localMd5 = HashUtils.md5OfBytes(dbBytes);
      final localModified = (await paths.dbFile.stat()).modified.millisecondsSinceEpoch;
      final remoteDbEntry = await remote.stat(dbPath);
      final remoteMd5Bytes = await remote.download(md5Path);
      final remoteMd5 = remoteMd5Bytes == null
          ? null
          : utf8.decode(remoteMd5Bytes, allowMalformed: true).trim();

      final decision = SyncPolicy.decide(
        localExists: true,
        remoteExists: remoteDbEntry != null,
        localModifiedMs: localModified,
        remoteModifiedMs: remoteDbEntry?.modifiedMs ?? 0,
        localHash: localMd5,
        remoteHash: remoteMd5,
        lastSyncedHash: state?.dbMd5,
      );

      switch (decision.action) {
        case SyncAction.upload:
          final imageResult = await _uploadImages(remote, state: state);
          await _uploadDatabase(remote, dbBytes);
          await remote.upload(
            md5Path,
            utf8.encode(localMd5),
            contentType: 'text/plain; charset=utf-8',
          );
          uploaded += imageResult.uploaded + 1;
          skipped += imageResult.skipped;
          bytes += imageResult.bytes + dbBytes.length;
          appliedMd5 = localMd5;
          break;
        case SyncAction.download:
          final remoteBytes = await remote.download(dbPath);
          if (remoteBytes == null) {
            throw StateError('远端备份文件不存在，无法拉取');
          }
          final remoteActualMd5 = HashUtils.md5OfBytes(remoteBytes);
          if (remoteMd5 != null &&
              remoteMd5.isNotEmpty &&
              remoteMd5 != remoteActualMd5) {
            throw StateError('远端备份 md5 校验失败，已拒绝覆盖本地数据');
          }
          // 覆盖前本地留底，避免误覆盖无可挽回
          await _backupLocalDb('before_sync');
          await closeDb();
          try {
            await paths.dbFile.writeAsBytes(remoteBytes, flush: true);
            for (final leftover in <String>[paths.dbWalPath, paths.dbShmPath]) {
              final file = File(leftover);
              if (await file.exists()) await file.delete();
            }
          } finally {
            await reopenDb();
          }
          appliedMd5 = remoteActualMd5;
          downloaded++;
          bytes += remoteBytes.length;
          break;
        case SyncAction.conflict:
          final copy = await _writeLocalDbCopy('conflict');
          if (copy != null) {
            conflicts.add(
              ConflictItem(
                kind: 'db',
                label: '数据库（物品 + 碎念）',
                localPath: paths.dbFilePath,
                remotePath: dbPath,
                localCopyPath: copy,
                localModified: TimeUtils.toDateTime(localModified),
                remoteModified: remoteDbEntry?.lastModified,
              ),
            );
          }
          break;
        case SyncAction.none:
          skipped++;
          break;
      }

      final imageOutcome = await _syncImages(remote, state: state);
      uploaded += imageOutcome.uploaded;
      downloaded += imageOutcome.downloaded;
      skipped += imageOutcome.skipped;
      bytes += imageOutcome.bytes;
      conflicts.addAll(imageOutcome.conflicts);

      final newState = SyncState(
        lastSyncAt: TimeUtils.nowMs(),
        dbMd5: appliedMd5.isEmpty ? (state?.dbMd5 ?? localMd5) : appliedMd5,
        dbModifiedMs: TimeUtils.nowMs(),
        images: imageOutcome.stamps.isEmpty
            ? (state?.images ?? const <String, SyncFileStamp>{})
            : imageOutcome.stamps,
      );
      await _writeState(remote, newState);

      final report = BackupReport(
        type: 'sync',
        success: true,
        message: conflicts.isEmpty
            ? '同步完成（${decision.reason}）'
            : '同步完成，检测到 ${conflicts.length} 处冲突，未自动合并',
        uploadedFiles: uploaded,
        downloadedFiles: downloaded,
        skippedFiles: skipped,
        totalBytes: bytes,
        conflicts: conflicts,
        startedAt: startedAt,
        finishedAt: DateTime.now(),
      );
      await logger?.call(report);
      return report;
    } catch (error) {
      final report = BackupReport(
        type: 'sync',
        success: false,
        message: '同步失败：$error',
        conflicts: conflicts,
        startedAt: startedAt,
        finishedAt: DateTime.now(),
      );
      await logger?.call(report);
      return report;
    }
  }

  /// 读取同步状态（备份状态面板用）
  Future<SyncState?> readState() async {
    final remote = await remoteStoreFactory();
    return _readState(remote);
  }

  /// 快照列表（新 → 旧）
  Future<List<SnapshotInfo>> listSnapshots() async {
    final remote = await remoteStoreFactory();
    final entries = await remote.list(snapshotsDir);
    final ids = entries
        .where((e) => e.isDirectory)
        .map((e) => e.name)
        .where((name) => name.isNotEmpty && name != '.keep')
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final result = <SnapshotInfo>[];
    for (final id in ids) {
      final manifest = await _readSnapshotManifest(remote, id);
      result.add(
        SnapshotInfo(
          id: id,
          remoteDir: '$snapshotsDir/$id',
          dbSize: manifest?.dbSize ?? 0,
          createdAt: manifest == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(manifest.createdAt),
          imageCount: manifest?.imageCount ?? 0,
          md5: manifest?.dbMd5,
        ),
      );
    }
    return result;
  }

  /// 只保留最近 N 份快照
  Future<int> pruneSnapshots(int keep) async {
    if (keep <= 0) return 0;
    final remote = await remoteStoreFactory();
    final entries = await remote.list(snapshotsDir);
    final ids = entries
        .where((e) => e.isDirectory)
        .map((e) => e.name)
        .where((name) => name.isNotEmpty && name != '.keep')
        .toList()
      ..sort((a, b) => b.compareTo(a));
    var removed = 0;
    for (final id in ids.skip(keep)) {
      await remote.delete('$snapshotsDir/$id');
      removed++;
    }
    return removed;
  }

  // ------------------------------------------------------------ 内部实现

  Future<void> _uploadDatabase(RemoteStore remote, List<int> dbBytes) async {
    // 先传临时文件，成功后 MOVE 覆盖正式文件：中断不会产生坏备份
    await remote.upload(dbTmpPath, dbBytes);
    final tempStat = await remote.stat(dbTmpPath);
    if (tempStat == null || tempStat.size != dbBytes.length) {
      throw StateError('上传校验失败：远端临时文件大小不一致，已中止本次备份');
    }
    await remote.move(dbTmpPath, dbPath);
  }

  Future<_UploadOutcome> _uploadImages(
    RemoteStore remote, {
    SyncState? state,
  }) async {
    final localFiles = await _localImageFiles();
    final remoteEntries = <String, RemoteEntry>{};
    for (final entry in await remote.list(imagesDir)) {
      if (!entry.isDirectory) remoteEntries[entry.name] = entry;
    }

    var uploaded = 0;
    var skipped = 0;
    var bytes = 0;
    final stamps = <String, SyncFileStamp>{};

    for (final item in localFiles.entries) {
      final stat = await item.value.stat();
      stamps[item.key] = SyncFileStamp(
        size: stat.size,
        modified: stat.modified.millisecondsSinceEpoch,
      );
      final remoteEntry = remoteEntries[item.key];
      if (remoteEntry != null && remoteEntry.size == stat.size) {
        skipped++;
        continue;
      }
      final data = await item.value.readAsBytes();
      await remote.upload(
        '$imagesDir/${item.key}',
        data,
        contentType: _contentTypeOf(item.key),
      );
      uploaded++;
      bytes += data.length;
    }
    return _UploadOutcome(uploaded: uploaded, skipped: skipped, bytes: bytes, stamps: stamps);
  }

  Future<_SyncImagesOutcome> _syncImages(
    RemoteStore remote, {
    SyncState? state,
  }) async {
    final localFiles = await _localImageFiles();
    final remoteEntries = <String, RemoteEntry>{};
    for (final entry in await remote.list(imagesDir)) {
      if (!entry.isDirectory) remoteEntries[entry.name] = entry;
    }

    final names = <String>{...localFiles.keys, ...remoteEntries.keys};
    var uploaded = 0;
    var downloaded = 0;
    var skipped = 0;
    var bytes = 0;
    final conflicts = <ConflictItem>[];
    final stamps = <String, SyncFileStamp>{};

    for (final name in names) {
      final localFile = localFiles[name];
      final remoteEntry = remoteEntries[name];
      final localStat = localFile == null ? null : await localFile.stat();
      if (localStat != null && remoteEntry != null) {
        stamps[name] = SyncFileStamp(
          size: localStat.size,
          modified: localStat.modified.millisecondsSinceEpoch,
        );
      }
      final baseline = state?.images[name];
      final decision = SyncPolicy.decideByStamp(
        localExists: localFile != null,
        remoteExists: remoteEntry != null,
        localSize: localStat?.size ?? 0,
        remoteSize: remoteEntry?.size ?? 0,
        localModifiedMs: localStat?.modified.millisecondsSinceEpoch ?? 0,
        remoteModifiedMs: remoteEntry?.modifiedMs ?? 0,
        lastSyncedSize: baseline?.size,
        lastSyncedModifiedMs: baseline?.modified,
      );
      switch (decision.action) {
        case SyncAction.upload:
          final data = await localFile!.readAsBytes();
          await remote.upload(
            '$imagesDir/$name',
            data,
            contentType: _contentTypeOf(name),
          );
          uploaded++;
          bytes += data.length;
          break;
        case SyncAction.download:
          final data = await remote.download('$imagesDir/$name');
          if (data != null) {
            await paths.ensure();
            await File(p.join(paths.imagesDirPath, name))
                .writeAsBytes(data, flush: true);
            downloaded++;
            bytes += data.length;
          }
          break;
        case SyncAction.conflict:
          final data = await remote.download('$imagesDir/$name');
          String? copyPath;
          if (data != null) {
            await paths.ensure();
            final copyFile = File(p.join(
              paths.conflictDirPath,
              'remote_${TimeUtils.compactStamp(DateTime.now())}_$name',
            ));
            await copyFile.writeAsBytes(data, flush: true);
            copyPath = copyFile.path;
          }
          conflicts.add(
            ConflictItem(
              kind: 'image',
              label: name,
              localPath: localFile?.path ?? '',
              remotePath: '$imagesDir/$name',
              localCopyPath: copyPath,
              localModified: localStat?.modified,
              remoteModified: remoteEntry?.lastModified,
            ),
          );
          break;
        case SyncAction.none:
          skipped++;
          break;
      }
    }

    return _SyncImagesOutcome(
      uploaded: uploaded,
      downloaded: downloaded,
      skipped: skipped,
      bytes: bytes,
      conflicts: conflicts,
      stamps: stamps,
    );
  }

  Future<int> _downloadImages(
    RemoteStore remote, {
    required Map<String, SyncFileStamp> baseline,
    required bool overwrite,
  }) async {
    final localFiles = await _localImageFiles();
    var downloaded = 0;
    if (baseline.isNotEmpty) {
      for (final entry in baseline.entries) {
        final local = localFiles[entry.key];
        final localSize = local == null ? -1 : (await local.stat()).size;
        if (!overwrite && localSize == entry.value.size) continue;
        final data = await remote.download('$imagesDir/${entry.key}');
        if (data == null) continue;
        await paths.ensure();
        await File(p.join(paths.imagesDirPath, entry.key))
            .writeAsBytes(data, flush: true);
        downloaded++;
      }
      return downloaded;
    }

    for (final entry in await remote.list(imagesDir)) {
      if (entry.isDirectory) continue;
      final local = localFiles[entry.name];
      if (!overwrite && local != null && (await local.stat()).size == entry.size) {
        continue;
      }
      final data = await remote.download('$imagesDir/${entry.name}');
      if (data == null) continue;
      await paths.ensure();
      await File(p.join(paths.imagesDirPath, entry.name))
          .writeAsBytes(data, flush: true);
      downloaded++;
    }
    return downloaded;
  }

  Future<String?> _writeSnapshot(
    RemoteStore remote, {
    required List<int> dbBytes,
    required String dbMd5,
    required Map<String, SyncFileStamp> stamps,
  }) async {
    final id = await _uniqueSnapshotId(remote);
    final dir = '$snapshotsDir/$id';
    await remote.ensureDir(dir);
    await remote.upload('$dir/app.db', dbBytes);
    await remote.upload(
      '$dir/app.db.md5',
      utf8.encode(dbMd5),
      contentType: 'text/plain; charset=utf-8',
    );
    final db = dbProvider();
    final manifest = SnapshotManifest(
      createdAt: TimeUtils.nowMs(),
      dbMd5: dbMd5,
      dbSize: dbBytes.length,
      itemCount: (await db.select(db.items).get()).length,
      noteCount: (await db.select(db.bulletNotes).get()).length,
      images: stamps,
    );
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    await remote.upload(
      '$dir/manifest.json',
      manifestBytes,
      contentType: 'application/json; charset=utf-8',
    );
    return id;
  }

  /// 快照目录名唯一化：同一秒内多次备份也不会互相覆盖。
  Future<String> _uniqueSnapshotId(RemoteStore remote) async {
    final base = TimeUtils.compactStamp(DateTime.now());
    final existing = (await remote.list(snapshotsDir))
        .where((e) => e.isDirectory)
        .map((e) => e.name)
        .toSet();
    if (!existing.contains(base)) return base;
    var suffix = 1;
    var candidate = '${base}_$suffix';
    while (existing.contains(candidate)) {
      suffix++;
      candidate = '${base}_$suffix';
    }
    return candidate;
  }

  Future<SnapshotManifest?> _readSnapshotManifest(    RemoteStore remote,
    String id,
  ) async {
    try {
      final bytes = await remote.download('$snapshotsDir/$id/manifest.json');
      if (bytes == null) return null;
      return SnapshotManifest.fromJson(
        Map<String, Object?>.from(
          jsonDecode(utf8.decode(bytes, allowMalformed: true)) as Map<dynamic, dynamic>,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<SyncState?> _readState(RemoteStore remote) async {
    try {
      final bytes = await remote.download(statePath);
      if (bytes == null) return null;
      return SyncState.fromJson(
        Map<String, Object?>.from(
          jsonDecode(utf8.decode(bytes, allowMalformed: true)) as Map<dynamic, dynamic>,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeState(RemoteStore remote, SyncState state) async {
    await remote.upload(
      statePath,
      utf8.encode(jsonEncode(state.toJson())),
      contentType: 'application/json; charset=utf-8',
    );
  }

  Future<Map<String, File>> _localImageFiles() async {
    final dir = paths.imagesDir;
    if (!await dir.exists()) return <String, File>{};
    final entities = await dir.list(followLinks: false).toList();
    final files = <String, File>{};
    for (final entity in entities) {
      if (entity is File) files[p.basename(entity.path)] = entity;
    }
    return files;
  }

  /// 覆盖前把当前数据库留底（restore / sync 前调用）。
  Future<String?> _backupLocalDb(String tag) async {
    final dbFile = File(paths.dbFilePath);
    if (!await dbFile.exists()) return null;
    await paths.ensure();
    final target = File(p.join(
      paths.restoreBackupDirPath,
      'app_${tag}_${TimeUtils.compactStamp(DateTime.now())}.db',
    ));
    await dbFile.copy(target.path);
    return target.path;
  }

  /// 冲突副本：本地保留两份，标注冲突时间，等待用户选择。
  Future<String?> _writeLocalDbCopy(String tag) async {
    final dbFile = File(paths.dbFilePath);
    if (!await dbFile.exists()) return null;
    await paths.ensure();
    final target = File(p.join(
      paths.conflictDirPath,
      'local_${tag}_${TimeUtils.compactStamp(DateTime.now())}.db',
    ));
    await dbFile.copy(target.path);
    return target.path;
  }

  static String _contentTypeOf(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

class _UploadOutcome {
  const _UploadOutcome({
    required this.uploaded,
    required this.skipped,
    required this.bytes,
    required this.stamps,
  });

  final int uploaded;
  final int skipped;
  final int bytes;
  final Map<String, SyncFileStamp> stamps;
}

class _SyncImagesOutcome {
  const _SyncImagesOutcome({
    required this.uploaded,
    required this.downloaded,
    required this.skipped,
    required this.bytes,
    required this.conflicts,
    required this.stamps,
  });

  final int uploaded;
  final int downloaded;
  final int skipped;
  final int bytes;
  final List<ConflictItem> conflicts;
  final Map<String, SyncFileStamp> stamps;
}