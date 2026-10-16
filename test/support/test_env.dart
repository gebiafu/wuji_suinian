import 'dart:io';

import 'package:wuji_suinian/core/paths/app_paths.dart';
import 'package:wuji_suinian/data/db/database.dart';
import 'package:wuji_suinian/data/repositories/item_repository.dart';
import 'package:wuji_suinian/data/repositories/note_repository.dart';
import 'package:wuji_suinian/data/repositories/search_repository.dart';
import 'package:wuji_suinian/data/repositories/tag_repository.dart';
import 'package:wuji_suinian/data/services/image_service.dart';
import 'package:wuji_suinian/domain/models/settings.dart';

/// 测试环境：临时目录 + 真实 SQLite（内存或文件）
class TestEnv {
  TestEnv._(this.paths, this.db, this.root);

  final AppPaths paths;
  final Directory root;
  AppDatabase db;

  ImageService get imageService => ImageService(
        paths: paths,
        settingsReader: () => const AppSettings(compressImage: false),
      );

  ItemRepository get items =>
      ItemRepository(db: db, imageService: imageService);

  NoteRepository get notes =>
      NoteRepository(db: db, imageService: imageService);

  TagRepository get tags => TagRepository(db);

  SearchRepository get search =>
      SearchRepository(items: items, notes: notes);

  static Future<TestEnv> create({bool memory = true}) async {
    final root = await Directory.systemTemp.createTemp('wuji_test_');
    final paths = AppPaths(rootDir: root);
    await paths.ensure();
    final db = memory ? AppDatabase.memory() : AppDatabase.openAt(paths);
    return TestEnv._(paths, db, root);
  }

  /// 供 restore / sync 测试使用：模拟数据库连接重建
  Future<void> reopen() async {
    await db.close();
    db = AppDatabase.openAt(paths);
  }

  Future<void> dispose() async {
    try {
      await db.close();
    } catch (_) {
      // ignore
    }
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

Future<int> seedItem(
  TestEnv env, {
  required String name,
  int? categoryId,
  String? location,
  double? price,
  DateTime? buyDate,
  DateTime? warrantyEnd,
  List<String> images = const <String>[],
  List<int> tagIds = const <int>[],
}) {
  return env.items.create(
    ItemDraft(
      name: name,
      categoryId: categoryId,
      location: location,
      price: price,
      buyDate: buyDate,
      warrantyEndDate: warrantyEnd,
      imageRelativePaths: images,
      tagIds: tagIds,
    ),
  );
}

Future<int> seedNote(
  TestEnv env, {
  required String content,
  bool isTodo = false,
  String? imagePath,
  List<int> tagIds = const <int>[],
}) {
  return env.notes.create(
    content: content,
    isTodo: isTodo,
    imageRelativePath: imagePath,
    tagIds: tagIds,
  );
}

Future<void> writeImageFile(AppPaths paths, String name, List<int> bytes) async {
  await paths.ensure();
  await File('${paths.imagesDirPath}/$name').writeAsBytes(bytes, flush: true);
}