import 'package:flutter/foundation.dart';

/// 一套 WebDAV 配置（支持多套切换：坚果云 / 阿里云盘 WebDAV 等）。
///
/// 注意：密码不落在 sqlite / shared_preferences，而是写入 secure_storage。
@immutable
class WebdavConfig {
  const WebdavConfig({
    required this.id,
    required this.name,
    required this.serverUrl,
    required this.username,
    this.remoteDir = 'backup',
    this.password = '',
  });

  final String id;
  final String name;
  final String serverUrl;
  final String username;

  /// 远端备份根目录（相对服务器根）
  final String remoteDir;

  /// 仅运行时持有，持久化时拆分到 secure_storage
  final String password;

  WebdavConfig copyWith({
    String? id,
    String? name,
    String? serverUrl,
    String? username,
    String? remoteDir,
    String? password,
  }) {
    return WebdavConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      remoteDir: remoteDir ?? this.remoteDir,
      password: password ?? this.password,
    );
  }

  /// 持久化到本地（不含密码）
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'serverUrl': serverUrl,
        'username': username,
        'remoteDir': remoteDir,
      };

  static WebdavConfig fromJson(Map<String, Object?> json) => WebdavConfig(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'WebDAV',
        serverUrl: json['serverUrl'] as String? ?? '',
        username: json['username'] as String? ?? '',
        remoteDir: json['remoteDir'] as String? ?? 'backup',
      );
}

/// 远端条目（PROPFIND 结果）
@immutable
class RemoteEntry {
  const RemoteEntry({
    required this.path,
    required this.isDirectory,
    this.size = 0,
    this.lastModified,
    this.etag,
    this.contentMd5,
  });

  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? lastModified;
  final String? etag;
  final String? contentMd5;

  String get name => path.split('/').where((e) => e.isNotEmpty).last;

  int get modifiedMs => lastModified?.millisecondsSinceEpoch ?? 0;

  @override
  String toString() =>
      'RemoteEntry($path, dir=$isDirectory, size=$size, mtime=$modifiedMs)';
}

/// 远端快照信息
@immutable
class SnapshotInfo {
  const SnapshotInfo({
    required this.id,
    required this.remoteDir,
    this.dbSize = 0,
    this.createdAt,
    this.imageCount = 0,
    this.md5,
  });

  final String id;
  final String remoteDir;
  final int dbSize;
  final DateTime? createdAt;
  final int imageCount;
  final String? md5;
}

/// 同步动作
enum SyncAction {
  none('无需处理'),
  upload('上传'),
  download('下载'),
  conflict('冲突');

  const SyncAction(this.label);
  final String label;
}

/// 单文件同步决策
@immutable
class SyncDecision {
  const SyncDecision({
    required this.action,
    this.reason = '',
    this.localHash,
    this.remoteHash,
  });

  final SyncAction action;
  final String reason;
  final String? localHash;
  final String? remoteHash;

  bool get changed => action != SyncAction.none;

  @override
  String toString() => 'SyncDecision(${action.name}: $reason)';
}

/// 冲突项（本地保留两份，由用户手动选择以哪边为准）
@immutable
class ConflictItem {
  const ConflictItem({
    required this.kind,
    required this.label,
    required this.localPath,
    required this.remotePath,
    this.localCopyPath,
    this.localModified,
    this.remoteModified,
  });

  /// db / image
  final String kind;
  final String label;
  final String localPath;
  final String remotePath;
  final String? localCopyPath;
  final DateTime? localModified;
  final DateTime? remoteModified;
}

/// 一次备份 / 同步的结果报告
class BackupReport {
  BackupReport({
    required this.type,
    required this.success,
    this.message = '',
    this.uploadedFiles = 0,
    this.downloadedFiles = 0,
    this.skippedFiles = 0,
    this.totalBytes = 0,
    this.snapshotId,
    this.conflicts = const <ConflictItem>[],
    this.startedAt,
    this.finishedAt,
  });

  final String type;
  final bool success;
  final String message;
  final int uploadedFiles;
  final int downloadedFiles;
  final int skippedFiles;
  final int totalBytes;
  final String? snapshotId;
  final List<ConflictItem> conflicts;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  Duration? get duration => (startedAt == null || finishedAt == null)
      ? null
      : finishedAt!.difference(startedAt!);

  BackupReport copyWith({
    String? type,
    bool? success,
    String? message,
    int? uploadedFiles,
    int? downloadedFiles,
    int? skippedFiles,
    int? totalBytes,
    String? snapshotId,
    List<ConflictItem>? conflicts,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return BackupReport(
      type: type ?? this.type,
      success: success ?? this.success,
      message: message ?? this.message,
      uploadedFiles: uploadedFiles ?? this.uploadedFiles,
      downloadedFiles: downloadedFiles ?? this.downloadedFiles,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      totalBytes: totalBytes ?? this.totalBytes,
      snapshotId: snapshotId ?? this.snapshotId,
      conflicts: conflicts ?? this.conflicts,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}