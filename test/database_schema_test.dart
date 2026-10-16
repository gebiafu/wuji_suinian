import 'package:flutter_test/flutter_test.dart';

import 'support/test_env.dart';

/// 校验数据库表结构符合需求文档第四节的设计
void main() {
  late TestEnv env;

  setUp(() async {
    env = await TestEnv.create();
  });

  tearDown(() => env.dispose());

  Future<Set<String>> columnsOf(String table) async {
    final rows = await env.db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  test('表结构与需求文档一致', () async {
    final tables = await env.db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    final names = tables.map((row) => row.read<String>('name')).toSet();
    expect(
      names,
      containsAll(<String>[
        'tags',
        'items',
        'item_images',
        'bullet_notes',
        'bullet_note_tag_rel',
        'item_tag_rel',
        'backup_records', // 需求「同步日志 / 状态面板」的补充表
      ]),
    );

    expect(
      await columnsOf('items'),
      containsAll(<String>[
        'id',
        'name',
        'category_id',
        'location',
        'price',
        'unit',
        'buy_channel',
        'buy_date',
        'warranty_end_date',
        'status',
        'lend_target',
        'lend_time',
        'expect_return_time',
        'description',
        'create_at',
        'update_at',
      ]),
    );

    expect(
      await columnsOf('item_images'),
      containsAll(<String>['id', 'item_id', 'relative_path', 'sort']),
    );

    expect(
      await columnsOf('bullet_notes'),
      containsAll(<String>[
        'id',
        'content',
        'image_path',
        'is_todo',
        'todo_finished',
        'is_top',
        'create_at',
        'update_at',
      ]),
    );

    expect(
      await columnsOf('bullet_note_tag_rel'),
      containsAll(<String>['note_id', 'tag_id']),
    );
    expect(
      await columnsOf('item_tag_rel'),
      containsAll(<String>['item_id', 'tag_id']),
    );
    expect(
      await columnsOf('tags'),
      containsAll(<String>['id', 'name', 'create_at']),
    );
  });

  test('删除物品时图片记录级联清理', () async {
    final id = await seedItem(
      env,
      name: '电钻',
      images: <String>['asset/images/a.jpg', 'asset/images/b.jpg'],
    );
    expect((await env.db.itemsDao.imagesForItem(id)).length, 2);

    await env.db.itemsDao.deleteItem(id);
    expect(await env.db.itemsDao.imagesForItem(id), isEmpty);
  });

  test('清空全部数据', () async {
    await seedItem(env, name: 'A');
    await seedNote(env, content: '碎念');
    await env.db.wipeAll();
    expect(await env.db.itemsDao.all(), isEmpty);
    expect(await env.db.notesDao.count(), 0);
    expect(await env.db.tagsDao.allTags(), isEmpty);
  });
}