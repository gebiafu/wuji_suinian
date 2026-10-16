import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../data/services/backup_service.dart';
import '../../domain/models/backup_models.dart';

/// 备份中心状态
class BackupCenterState {
  const BackupCenterState({
    this.busy = false,
    this.busyLabel = '',
    this.lastReport,
    this.snapshots = const <SnapshotInfo>[],
    this.logs = const <BackupRecord>[],
    this.syncState,
    this.remoteError,
  });

  final bool busy;
  final String busyLabel;
  final BackupReport? lastReport;
  final List<SnapshotInfo> snapshots;
  final List<BackupRecord> logs;
  final SyncState? syncState;
  final String? remoteError;

  BackupCenterState copyWith({
    bool? busy,
    String? busyLabel,
    BackupReport? lastReport,
    List<SnapshotInfo>? snapshots,
    List<BackupRecord>? logs,
    SyncState? syncState,
    String? remoteError,
    bool clearError = false,
    bool clearReport = false,
  }) {
    return BackupCenterState(
      busy: busy ?? this.busy,
      busyLabel: busyLabel ?? this.busyLabel,
      lastReport: clearReport ? null : (lastReport ?? this.lastReport),
      snapshots: snapshots ?? this.snapshots,
      logs: logs ?? this.logs,
      syncState: syncState ?? this.syncState,
      remoteError: clearError ? null : (remoteError ?? this.remoteError),
    );
  }
}

final backupCenterProvider =
    NotifierProvider<BackupCenterController, BackupCenterState>(
  BackupCenterController.new,
);

class BackupCenterController extends Notifier<BackupCenterState> {
  @override
  BackupCenterState build() => const BackupCenterState();

  BackupService get _service => ref.read(backupServiceProvider);

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> load({bool withRemote = false}) async {
    final logs = await _db.backupRecordsDao.recent(limit: 50);
    var snapshots = state.snapshots;
    SyncState? syncState = state.syncState;
    String? remoteError;
    if (withRemote) {
      try {
        snapshots = await _service.listSnapshots();
        syncState = await _service.readState();
      } catch (error) {
        remoteError = '$error';
      }
    }
    state = state.copyWith(
      logs: logs,
      snapshots: snapshots,
      syncState: syncState,
      remoteError: remoteError,
      clearError: remoteError == null,
    );
  }

  Future<BackupReport> runBackup({bool createSnapshot = true}) async {
    state = state.copyWith(busy: true, busyLabel: '正在备份到 WebDAV…');
    try {
      final report = await _service.backup(createSnapshot: createSnapshot);
      state = state.copyWith(lastReport: report);
      await load(withRemote: true);
      return report;
    } finally {
      state = state.copyWith(busy: false, busyLabel: '');
    }
  }

  Future<BackupReport> runSync() async {
    state = state.copyWith(busy: true, busyLabel: '正在双向同步…');
    try {
      final report = await _service.sync(
        closeDb: () async => _db.close(),
        reopenDb: () async => ref.read(databaseProvider.notifier).reload(),
      );
      state = state.copyWith(lastReport: report);
      await load(withRemote: true);
      return report;
    } finally {
      state = state.copyWith(busy: false, busyLabel: '');
    }
  }

  Future<BackupReport> runRestore(SnapshotInfo? snapshot) async {
    state = state.copyWith(
      busy: true,
      busyLabel: snapshot == null ? '正在恢复最新备份…' : '正在恢复快照 ${snapshot.id}…',
    );
    try {
      final report = await _service.restore(
        snapshot: snapshot,
        closeDb: () async => _db.close(),
        reopenDb: () async => ref.read(databaseProvider.notifier).reload(),
      );
      state = state.copyWith(lastReport: report);
      await load(withRemote: true);
      return report;
    } finally {
      state = state.copyWith(busy: false, busyLabel: '');
    }
  }

  /// 冲突处理：以远端为准（覆盖本地）
  Future<BackupReport> resolveWithRemote() => runRestore(null);

  /// 冲突处理：以本地为准（覆盖远端）
  Future<BackupReport> resolveWithLocal() => runBackup(createSnapshot: false);

  Future<int> pruneSnapshots(int keep) async {
    state = state.copyWith(busy: true, busyLabel: '正在清理历史快照…');
    try {
      final removed = await _service.pruneSnapshots(keep);
      await load(withRemote: true);
      return removed;
    } finally {
      state = state.copyWith(busy: false, busyLabel: '');
    }
  }

  Future<void> clearLogs() async {
    await _db.backupRecordsDao.clear();
    await load();
  }

  void resetReport() => state = state.copyWith(clearReport: true);
}