import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuji_suinian/core/utils/hash_utils.dart';
import 'package:wuji_suinian/data/services/archive_service.dart';
import 'package:wuji_suinian/data/db/database.dart';

import 'support/test_env.dart';

void main() {
  late TestEnv source;
  late TestEnv target;

  setUp(() async {
    source = await TestEnv.create(memory: false);
    target = await TestEnv.create(memory: false);
  });

  tearDown(() async {
    await source.dispose();
    await target.dispose();
  });

  test('导出 ZIP：包含数据库、图片与 manifest，md5 正确', () async {
    await seedItem(
      source,
      name: '相机',
      images: <String>['asset/images/cam.jpg'],
    );
    await seedNote(source, content: '随手一拍');
    await writeImageFile(source.paths, 'cam.jpg', <int>[9, 9, 9]);

    final service = ArchiveService(paths: source.paths);
    final file = await service.exportArchive(db: source.db);
    expect(await file.exists(), isTrue);

    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final names = archive.files.map((e) => e.name).toList();
    expect(names, contains('manifest.json'));
    expect(names, contains('db/app.db'));
    expect(names, contains('asset/images/cam.jpg'));

    final inspection = await service.inspect(file);
    expect(inspection.success, isTrue);
    expect(inspection.manifest!.itemCount, 1);
    expect(inspection.manifest!.noteCount, 1);
    expect(inspection.manifest!.imageCount, 1);
  });

  test('导入 ZIP：恢复数据库与图片', () async {
    await seedItem(
      source,
      name: '待迁移物品',
      images: <String>['asset/images/kb.jpg'],
    );
    await seedNote(source, content: '待迁移碎念');
    await writeImageFile(source.paths, 'kb.jpg', <int>[7, 7, 7, 7]);

    final service = ArchiveService(paths: source.paths);
    final file = await service.exportArchive(db: source.db);

    await target.db.close();
    final importService = ArchiveService(paths: target.paths);
    final outcome = await importService.importArchive(file);
    target.db = AppDatabase.openAt(target.paths);

    expect(outcome.success, isTrue, reason: outcome.message);
    expect(outcome.restoredImages, 1);

    final items = await target.db.select(target.db.items).get();
    expect(items.length, 1);
    expect(items.first.name, '待迁移物品');

    final notes = await target.db.select(target.db.bulletNotes).get();
    expect(notes.single.content, '待迁移碎念');

    expect(
      await File('${target.paths.imagesDirPath}/kb.jpg').exists(),
      isTrue,
    );
  });

  test('导入：md5 不匹配时拒绝导入', () async {
    final archive = Archive();
    final dbBytes = utf8.encode('被篡改的数据库内容');
    archive.addFile(ArchiveFile('db/app.db', dbBytes.length, dbBytes));
    final manifest = ArchiveManifest(
      exportedAt: DateTime.now().millisecondsSinceEpoch,
      dbMd5: HashUtils.md5OfString('原始内容'),
    );
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );
    final zipBytes = ZipEncoder().encode(archive);
    final zipFile = File('${source.paths.tempDirPath}/tampered.zip');
    await zipFile.writeAsBytes(zipBytes, flush: true);

    await source.db.close();
    final service = ArchiveService(paths: source.paths);
    final outcome = await service.importArchive(zipFile);
    source.db = AppDatabase.openAt(source.paths);

    expect(outcome.success, isFalse);
    expect(outcome.message, contains('md5'));
  });

  test('导入：缺少 manifest 的压缩包被拒绝', () async {
    final archive = Archive();
    final bytes = utf8.encode('whatever');
    archive.addFile(ArchiveFile('db/app.db', bytes.length, bytes));
    final zipFile = File('${source.paths.tempDirPath}/no_manifest.zip');
    await zipFile.writeAsBytes(ZipEncoder().encode(archive), flush: true);

    final service = ArchiveService(paths: source.paths);
    final outcome = await service.inspect(zipFile);
    expect(outcome.success, isFalse);
    expect(outcome.message, contains('manifest'));
  });
}