part of '../database.dart';

/// 标签池：物品与碎念共用。
@DriftAccessor(tables: [Tags, ItemTagRel, BulletNoteTagRel, Items])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  Future<List<Tag>> allTags() async {
    final rows = await select(tags).get();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  Future<Tag?> findByName(String name) =>
      (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<Tag?> findById(int id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 不存在则创建，返回标签 id。
  Future<int> ensureTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('标签名不能为空');
    }
    final existing = await findByName(trimmed);
    if (existing != null) return existing.id;
    return into(tags).insert(
      TagsCompanion.insert(
        name: trimmed,
        createAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> renameTag(int id, String name) async {
    await (update(tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(name: Value(name.trim())),
    );
  }

  /// 删除标签并清理多对多关联。
  Future<void> deleteTag(int id) async {
    await transaction(() async {
      await (delete(itemTagRel)..where((t) => t.tagId.equals(id))).go();
      await (delete(bulletNoteTagRel)..where((t) => t.tagId.equals(id))).go();
      await (update(items)..where((t) => t.categoryId.equals(id)))
          .write(const ItemsCompanion(categoryId: Value(null)));
      await (delete(tags)..where((t) => t.id.equals(id))).go();
    });
  }

  /// 标签使用次数（物品 + 碎念）。
  Future<Map<int, int>> usageCounts() async {
    final rows = await customSelect(
      'SELECT tag_id, COUNT(*) AS c FROM ('
      '  SELECT tag_id FROM item_tag_rel'
      '  UNION ALL'
      '  SELECT tag_id FROM bullet_note_tag_rel'
      ') GROUP BY tag_id',
      readsFrom: {itemTagRel, bulletNoteTagRel},
    ).get();
    return {
      for (final row in rows) row.read<int>('tag_id'): row.read<int>('c'),
    };
  }
}