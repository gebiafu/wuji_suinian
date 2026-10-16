import 'package:flutter_test/flutter_test.dart';
import 'package:wuji_suinian/data/services/webdav/sync_policy.dart';
import 'package:wuji_suinian/domain/models/backup_models.dart';

void main() {
  group('SyncPolicy.decide（数据库文件）', () {
    test('本地缺失 → 下载', () {
      final decision = SyncPolicy.decide(
        localExists: false,
        remoteExists: true,
      );
      expect(decision.action, SyncAction.download);
    });

    test('远端缺失 → 上传', () {
      final decision = SyncPolicy.decide(
        localExists: true,
        remoteExists: false,
      );
      expect(decision.action, SyncAction.upload);
    });

    test('内容一致 → 跳过', () {
      final decision = SyncPolicy.decide(
        localExists: true,
        remoteExists: true,
        localHash: 'abc',
        remoteHash: 'abc',
      );
      expect(decision.action, SyncAction.none);
    });

    test('仅本地有修改 → 上传', () {
      final decision = SyncPolicy.decide(
        localExists: true,
        remoteExists: true,
        localHash: 'new',
        remoteHash: 'old',
        lastSyncedHash: 'old',
      );
      expect(decision.action, SyncAction.upload);
    });

    test('仅远端有修改 → 下载', () {
      final decision = SyncPolicy.decide(
        localExists: true,
        remoteExists: true,
        localHash: 'old',
        remoteHash: 'new',
        lastSyncedHash: 'old',
      );
      expect(decision.action, SyncAction.download);
    });

    test('两端都修改 → 冲突（不自动合并）', () {
      final decision = SyncPolicy.decide(
        localExists: true,
        remoteExists: true,
        localHash: 'local-new',
        remoteHash: 'remote-new',
        lastSyncedHash: 'base',
      );
      expect(decision.action, SyncAction.conflict);
      expect(decision.reason, contains('两端'));
    });

    test('无基准时按时间戳判断', () {
      final remoteNewer = SyncPolicy.decide(
        localExists: true,
        remoteExists: true,
        localModifiedMs: 1000,
        remoteModifiedMs: 5000,
      );
      expect(remoteNewer.action, SyncAction.download);

      final localNewer = SyncPolicy.decide(
        localExists: true,
        remoteExists: true,
        localModifiedMs: 9000,
        remoteModifiedMs: 5000,
      );
      expect(localNewer.action, SyncAction.upload);
    });

    test('时间戳在容忍范围内视为一致', () {
      final decision = SyncPolicy.decide(
        localExists: true,
        remoteExists: true,
        localModifiedMs: 1000,
        remoteModifiedMs: 1500,
      );
      expect(decision.action, SyncAction.none);
    });
  });

  group('SyncPolicy.decideByStamp（图片）', () {
    test('大小一致 → 跳过', () {
      final decision = SyncPolicy.decideByStamp(
        localExists: true,
        remoteExists: true,
        localSize: 100,
        remoteSize: 100,
      );
      expect(decision.action, SyncAction.none);
    });

    test('本地独有 → 上传', () {
      final decision = SyncPolicy.decideByStamp(
        localExists: true,
        remoteExists: false,
      );
      expect(decision.action, SyncAction.upload);
    });

    test('无基准时远端较新 → 下载', () {
      final decision = SyncPolicy.decideByStamp(
        localExists: true,
        remoteExists: true,
        localSize: 100,
        remoteSize: 120,
        localModifiedMs: 1000,
        remoteModifiedMs: 9000,
      );
      expect(decision.action, SyncAction.download);
    });

    test('有基准且两端都变化 → 冲突', () {
      final decision = SyncPolicy.decideByStamp(
        localExists: true,
        remoteExists: true,
        localSize: 130,
        remoteSize: 120,
        lastSyncedSize: 100,
      );
      expect(decision.action, SyncAction.conflict);
    });
  });
}