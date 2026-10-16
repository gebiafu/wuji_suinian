import '../../../domain/models/backup_models.dart';

/// 双向同步策略（纯函数，方便单元测试）。
///
/// 方案：基于「上次同步记录的内容 md5 + 文件时间戳」判断。
/// - 远端新于本地 → 拉取
/// - 本地新于远端 → 上传
/// - 一致 → 跳过
/// - 两端都修改 → 冲突（不自动合并，生成冲突副本让用户选择）
class SyncPolicy {
  SyncPolicy._();

  /// 文件系统时间戳精度差异容忍（秒级 → 毫秒）
  static const int toleranceMs = 2000;

  static SyncDecision decide({
    required bool localExists,
    required bool remoteExists,
    int localModifiedMs = 0,
    int remoteModifiedMs = 0,
    String? localHash,
    String? remoteHash,
    String? lastSyncedHash,
  }) {
    if (!localExists && !remoteExists) {
      return const SyncDecision(action: SyncAction.none, reason: '两端都不存在');
    }
    if (!localExists) {
      return const SyncDecision(action: SyncAction.download, reason: '本地缺失，从远端拉取');
    }
    if (!remoteExists) {
      return const SyncDecision(action: SyncAction.upload, reason: '远端缺失，上传本地文件');
    }

    final hashesKnown = localHash != null && remoteHash != null;
    if (hashesKnown && localHash == remoteHash) {
      return SyncDecision(
        action: SyncAction.none,
        reason: '内容一致，跳过',
        localHash: localHash,
        remoteHash: remoteHash,
      );
    }

    if (hashesKnown && lastSyncedHash != null) {
      final localChanged = localHash != lastSyncedHash;
      final remoteChanged = remoteHash != lastSyncedHash;
      if (!localChanged && !remoteChanged) {
        return const SyncDecision(action: SyncAction.none, reason: '与上次同步一致');
      }
      if (localChanged && remoteChanged) {
        return SyncDecision(
          action: SyncAction.conflict,
          reason: '两端自上次同步后都被修改',
          localHash: localHash,
          remoteHash: remoteHash,
        );
      }
      if (localChanged) {
        return SyncDecision(
          action: SyncAction.upload,
          reason: '本地有新的修改',
          localHash: localHash,
          remoteHash: remoteHash,
        );
      }
      return SyncDecision(
        action: SyncAction.download,
        reason: '远端有新的修改',
        localHash: localHash,
        remoteHash: remoteHash,
      );
    }

    final localNewer = localModifiedMs > remoteModifiedMs + toleranceMs;
    final remoteNewer = remoteModifiedMs > localModifiedMs + toleranceMs;

    if (localNewer && remoteNewer) {
      return const SyncDecision(action: SyncAction.none, reason: '时间戳异常，跳过待人工确认');
    }
    if (localNewer) {
      return const SyncDecision(action: SyncAction.upload, reason: '本地时间戳较新');
    }
    if (remoteNewer) {
      return const SyncDecision(action: SyncAction.download, reason: '远端时间戳较新');
    }

    // 时间戳相同但内容不同（无基准）→ 视为冲突，交由用户决定
    if (hashesKnown && localHash != remoteHash) {
      return const SyncDecision(action: SyncAction.conflict, reason: '时间戳接近但内容不同');
    }
    return const SyncDecision(action: SyncAction.none, reason: '时间戳一致，跳过');
  }

  /// 图片等无 md5 场景的轻量判断：size + mtime。
  static SyncDecision decideByStamp({
    required bool localExists,
    required bool remoteExists,
    int localSize = 0,
    int remoteSize = 0,
    int localModifiedMs = 0,
    int remoteModifiedMs = 0,
    int? lastSyncedSize,
    int? lastSyncedModifiedMs,
  }) {
    if (!localExists && !remoteExists) {
      return const SyncDecision(action: SyncAction.none, reason: '两端都不存在');
    }
    if (!localExists) {
      return const SyncDecision(action: SyncAction.download, reason: '本地缺失');
    }
    if (!remoteExists) {
      return const SyncDecision(action: SyncAction.upload, reason: '远端缺失');
    }
    if (localSize == remoteSize) {
      return const SyncDecision(action: SyncAction.none, reason: '大小一致，跳过');
    }
    if (lastSyncedSize != null) {
      final localChanged = localSize != lastSyncedSize;
      final remoteChanged = remoteSize != lastSyncedSize;
      if (localChanged && remoteChanged) {
        return const SyncDecision(action: SyncAction.conflict, reason: '两端都修改');
      }
      if (localChanged) {
        return const SyncDecision(action: SyncAction.upload, reason: '本地已修改');
      }
      if (remoteChanged) {
        return const SyncDecision(action: SyncAction.download, reason: '远端已修改');
      }
    }
    if (remoteModifiedMs > localModifiedMs + toleranceMs) {
      return const SyncDecision(action: SyncAction.download, reason: '远端较新');
    }
    return const SyncDecision(action: SyncAction.upload, reason: '本地较新');
  }
}