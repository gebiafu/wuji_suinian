import 'package:drift/drift.dart';

/// 标签表（物品 / 碎念共用标签池）
class Tags extends Table {
  @override
  String get tableName => 'tags';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get createAt => integer().named('create_at')();
}

/// 物品表
class Items extends Table {
  @override
  String get tableName => 'items';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// 分类（标签 id，指向 tags 表）
  IntColumn get categoryId => integer().nullable().named('category_id')();
  TextColumn get location => text().nullable()();
  RealColumn get price => real().nullable()();
  TextColumn get unit => text().withDefault(const Constant('元'))();
  TextColumn get buyChannel => text().nullable().named('buy_channel')();
  IntColumn get buyDate => integer().nullable().named('buy_date')();
  IntColumn get warrantyEndDate =>
      integer().nullable().named('warranty_end_date')();

  /// using / idle / discarded / lend
  TextColumn get status => text().withDefault(const Constant('using'))();

  TextColumn get lendTarget => text().nullable().named('lend_target')();
  IntColumn get lendTime => integer().nullable().named('lend_time')();
  IntColumn get expectReturnTime =>
      integer().nullable().named('expect_return_time')();
  TextColumn get description => text().nullable()();
  IntColumn get createAt => integer().named('create_at')();
  IntColumn get updateAt => integer().named('update_at')();
}

/// 物品图片表（一条物品多张图，只存相对路径，不存 blob）
class ItemImages extends Table {
  @override
  String get tableName => 'item_images';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer()
      .named('item_id')
      .references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get relativePath => text().named('relative_path')();
  IntColumn get sort => integer().nullable()();
}

/// 子弹笔记 / 碎碎念
class BulletNotes extends Table {
  @override
  String get tableName => 'bullet_notes';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get imagePath => text().nullable().named('image_path')();
  BoolColumn get isTodo =>
      boolean().withDefault(const Constant(false)).named('is_todo')();
  BoolColumn get todoFinished =>
      boolean().withDefault(const Constant(false)).named('todo_finished')();
  BoolColumn get isTop =>
      boolean().withDefault(const Constant(false)).named('is_top')();
  IntColumn get createAt => integer().named('create_at')();
  IntColumn get updateAt => integer().named('update_at')();
}

/// 碎念-标签关联（多对多）
class BulletNoteTagRel extends Table {
  @override
  String get tableName => 'bullet_note_tag_rel';

  IntColumn get noteId => integer().named('note_id')();
  IntColumn get tagId => integer().named('tag_id')();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}

/// 物品-标签关联（多对多）
class ItemTagRel extends Table {
  @override
  String get tableName => 'item_tag_rel';

  IntColumn get itemId => integer().named('item_id')();
  IntColumn get tagId => integer().named('tag_id')();

  @override
  Set<Column> get primaryKey => {itemId, tagId};
}

/// 备份 / 同步日志（对应需求「备份状态面板、同步日志」）
class BackupRecords extends Table {
  @override
  String get tableName => 'backup_records';

  IntColumn get id => integer().autoIncrement()();

  /// backup / restore / sync / export / import
  TextColumn get type => text()();

  /// success / failed / conflict
  TextColumn get status => text()();
  TextColumn get message => text().nullable()();
  IntColumn get size => integer().nullable()();
  TextColumn get remotePath => text().nullable().named('remote_path')();
  IntColumn get createAt => integer().named('create_at')();
}