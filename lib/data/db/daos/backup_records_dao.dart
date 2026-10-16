part of '../database.dart';

/// 备份 / 同步日志。
@DriftAccessor(tables: [BackupRecords])
class BackupRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$BackupRecordsDaoMixin {
  BackupRecordsDao(super.db);

  Future<int> add({
    required String type,
    required String status,
    String? message,
    int? size,
    String? remotePath,
  }) {
    return into(backupRecords).insert(
      BackupRecordsCompanion.insert(
        type: type,
        status: status,
        message: Value(message),
        size: Value(size),
        remotePath: Value(remotePath),
        createAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<List<BackupRecord>> recent({int limit = 50}) async {
    final rows = await select(backupRecords).get();
    rows.sort((a, b) => b.createAt.compareTo(a.createAt));
    return rows.take(limit).toList();
  }

  Future<BackupRecord?> latest(String type) async {
    final all = await recent(limit: 200);
    for (final row in all) {
      if (row.type == type && row.status == 'success') return row;
    }
    return null;
  }

  Future<void> clear() => delete(backupRecords).go();
}