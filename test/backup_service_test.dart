import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuji_suinian/core/utils/hash_utils.dart';
import 'package:wuji_suinian/data/db/database.dart';
import 'package:wuji_suinian/data/services/backup_service.dart';
import 'package:wuji_suinian/domain/models/backup_models.dart';
import 'package:wuji_suinian/data/services/webdav/memory_remote_store.dart';
import 'package:wuji_suinian/domain/models/settings.dart';

import 'support/test_env.dart';

void main() {
  late TestEnv env;
  late MemoryRemoteStore remote;
  late BackupService service;
  late AppDatabase current;

  setUp(() async {
    // 备份 / 恢复针对真实数据库文件，因此使用文件型数据库
    env = await TestEnv.create(memory: false);
    remote = MemoryRemoteStore();
    current = env.db;
    service = BackupService(
      paths: env.paths,
      dbProvider: () => current,
      remoteStoreFactory: () async => remote,
      settingsReader: () => const AppSettings(snapshotKeep: 3),
    );
  });

  tearDown(() => env.dispose());

  Future<void> closeDb() => current.close();

  Future<void> reopenDb() async {
    current = AppDatabase.openAt(env.paths);
    env.db = current;
  }

  test('备份：上传 db + 图片 + md5，生成快照与同步状态', () async {
    await seedItem(
      env,
      name: '电钻',
      images: <String>['asset/images/a.jpg'],
    );
    await writeImageFile(env.paths, 'a.jpg', <int>[1, 2, 3, 4]);

    final report = await service.backup();
    expect(report.success, isTrue, reason: report.message);
    expect(report.snapshotId, isNotNull);

    final dbBytes = remote.raw('db/app.db');
    expect(dbBytes, isNotNull);
    expect(remote.raw('db/app.db.tmp'), isNull, reason: '临时文件应已 MOVE 为正式文件');
    expect(remote.raw('images/a.jpg'), <int>[1, 2, 3, 4]);

    final md5Text = utf8.decode(remote.raw('md5/app.db.md5')!).trim();
    expect(md5Text, HashUtils.md5OfBytes(dbBytes!));

    final snapshots = await service.listSnapshots();
    expect(snapshots.length, 1);
    expect(snapshots.first.imageCount, 1);
    expect(snapshots.first.md5, md5Text);

    final state = await service.readState();
    expect(state, isNotNull);
    expect(state!.dbMd5, md5Text);
    expect(state.images.containsKey('a.jpg'), isTrue);
  });

  test('备份：图片未变化时跳过重复上传，快照按份数自动清理', () async {
    await writeImageFile(env.paths, 'a.jpg', <int>[1, 2, 3, 4]);
    await service.backup();

    final second = await service.backup();
    expect(second.success, isTrue);
    expect(second.skippedFiles, greaterThanOrEqualTo(1));

    await service.backup();
    await service.backup();
    final snapshots = await service.listSnapshots();
    expect(snapshots.length, 3, reason: 'snapshotKeep=3，最多保留 3 份快照');
  });

  test('恢复：md5 校验通过后覆盖本地，并保留本地留底', () async {
    await seedItem(env, name: '被恢复的物品');
    await service.backup();

    // 模拟本地数据被清空
    await env.db.wipeAll();
    expect(await env.db.itemsDao.all(), isEmpty);

    final report = await service.restore(
      snapshot: null,
      closeDb: closeDb,
      reopenDb: reopenDb,
    );
    expect(report.success, isTrue, reason: report.message);
    expect((await current.select(current.items).get()).length, 1);
    expect(await env.paths.dbFile.exists(), isTrue);
  });

  test('恢复：md5 校验失败时拒绝覆盖本地数据', () async {
    await seedItem(env, name: '本地唯一数据');
    remote.seed('db/app.db', utf8.encode('这是一个损坏的数据库文件'));
    remote.seed('md5/app.db.md5', utf8.encode('0000000000000000000000000000dead'));

    final report = await service.restore(
      snapshot: null,
      closeDb: closeDb,
      reopenDb: reopenDb,
    );
    expect(report.success, isFalse);
    expect(report.message, contains('md5'));
    expect((await current.select(current.items).get()).length, 1);
  });

  test('同步：本地有修改 → 上传', () async {
    await seedItem(env, name: '旧数据');
    await service.backup();

    await seedItem(env, name: '新数据');
    final report = await service.sync(closeDb: closeDb, reopenDb: reopenDb);
    expect(report.success, isTrue, reason: report.message);
    expect(report.uploadedFiles, greaterThanOrEqualTo(1));

    final state = await service.readState();
    final localMd5 = await HashUtils.md5OfFile(env.paths.dbFile);
    expect(state!.dbMd5, localMd5);
  });

  test('同步：远端较新 → 下载并覆盖本地', () async {
    // 用另一个"设备"生成更新的数据库文件
    final other = await TestEnv.create(memory: false);
    addTearDown(other.dispose);
    await seedItem(other, name: '来自另一台设备的物品');
    await other.db.checkpoint();
    final remoteDbBytes = await other.paths.dbFile.readAsBytes();
    await other.dispose();

    await seedItem(env, name: '本机旧数据');
    await service.backup();

    // 远端被另一台设备更新
    remote.seed('db/app.db', remoteDbBytes);
    remote.seed(
      'md5/app.db.md5',
      utf8.encode(HashUtils.md5OfBytes(remoteDbBytes)),
    );

    final report = await service.sync(closeDb: closeDb, reopenDb: reopenDb);
    expect(report.success, isTrue, reason: report.message);
    expect(report.conflicts, isEmpty);

    final names = (await current.select(current.items).get())
        .map((e) => e.name)
        .toList();
    expect(names, contains('来自另一台设备的物品'));
  });

  test('同步：两端都修改 → 冲突，生成冲突副本且不自动合并', () async {
    await seedItem(env, name: '基准数据');
    await service.backup();

    // 本地继续修改
    await seedItem(env, name: '本地新增');
    await env.db.checkpoint();
    final localNamesBefore = (await env.db.itemsDao.all())
        .map((e) => e.name)
        .toList();

    // 远端也被修改（内容与本地不同）
    final remoteDbBytes = utf8.encode('remote-changed-database-bytes');
    remote.seed('db/app.db', remoteDbBytes);
    remote.seed(
      'md5/app.db.md5',
      utf8.encode(HashUtils.md5OfBytes(remoteDbBytes)),
    );

    final report = await service.sync(closeDb: closeDb, reopenDb: reopenDb);
    expect(report.success, isTrue);
    expect(report.conflicts, isNotEmpty);
    expect(report.message, contains('冲突'));

    final conflictFiles = await env.paths.conflictDir
        .list()
        .where((e) => e.path.endsWith('.db'))
        .toList();
    expect(conflictFiles, isNotEmpty, reason: '冲突时应在本地保留副本');

    final localNamesAfter = (await current.select(current.items).get())
        .map((e) => e.name)
        .toList();
    expect(localNamesAfter, localNamesBefore, reason: '冲突时不得自动覆盖本地数据');
  });

  test('备份失败时返回失败报告并写入日志回调', () async {
    final reports = <BackupReport>[];
    final failing = BackupService(
      paths: env.paths,
      dbProvider: () => current,
      remoteStoreFactory: () async => _FailingRemoteStore(),
      settingsReader: () => const AppSettings(),
      logger: (report) async => reports.add(report),
    );
    final report = await failing.backup();
    expect(report.success, isFalse);
    expect(reports.single.success, isFalse);
  });
}

/// 模拟网络故障：所有写操作失败
class _FailingRemoteStore extends MemoryRemoteStore {
  @override
  Future<void> upload(String path, List<int> bytes, {String? contentType}) {
    throw StateError('网络中断');
  }
}