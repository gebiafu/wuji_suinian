part of '../database.dart';

/// 物品数据访问：列表筛选、检索、多图、标签关联、统计。
@DriftAccessor(tables: [Items, ItemImages, ItemTagRel])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  Future<List<Item>> findItems({
    String? keyword,
    int? categoryId,
    String? location,
    String? status,
    List<int>? tagIds,
  }) async {
    final query = select(items);
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    if (location != null && location.isNotEmpty) {
      query.where((t) => t.location.equals(location));
    }
    if (status != null && status.isNotEmpty) {
      query.where((t) => t.status.equals(status));
    }

    final kw = keyword?.trim() ?? '';
    if (kw.isNotEmpty) {
      final pattern = '%${kw.toLowerCase()}%';
      final number = double.tryParse(kw);
      query.where((t) {
        final parts = <Expression<bool>>[
          t.name.lower().like(pattern),
          t.description.like(pattern),
          t.location.like(pattern),
          t.buyChannel.like(pattern),
          t.lendTarget.like(pattern),
        ];
        if (number != null) {
          parts.add(t.price.equals(number));
        }
        return parts.reduce((a, b) => a | b);
      });
    }

    if (tagIds != null && tagIds.isNotEmpty) {
      final ids = await itemIdsForTags(tagIds);
      if (ids.isEmpty) return <Item>[];
      query.where((t) => t.id.isIn(ids));
    }

    return query.get();
  }

  Future<Item?> findById(int id) =>
      (select(items)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Item>> all() => select(items).get();

  Future<int> insertItem(ItemsCompanion companion) =>
      into(items).insert(companion);

  Future<bool> updateItem(Item row) => update(items).replace(row);

  Future<int> deleteItem(int id) =>
      (delete(items)..where((t) => t.id.equals(id))).go();

  Future<List<Item>> itemsWithWarranty() async {
    final rows = await (select(items)..where((t) => t.warrantyEndDate.isNotNull()))
        .get();
    return rows;
  }

  Future<List<String>> distinctLocations() async {
    final rows = await customSelect(
      "SELECT DISTINCT location FROM items "
      "WHERE location IS NOT NULL AND TRIM(location) != '' ORDER BY location",
      readsFrom: {items},
    ).get();
    return rows.map((r) => r.read<String>('location')).toList();
  }

  Future<Map<int, int>> categoryCounts() async {
    final rows = await customSelect(
      'SELECT category_id, COUNT(*) AS c FROM items '
      'WHERE category_id IS NOT NULL GROUP BY category_id',
      readsFrom: {items},
    ).get();
    return {
      for (final r in rows)
        r.read<int>('category_id'): r.read<int>('c'),
    };
  }

  // ---------------------------------------------------------------- 图片

  Future<List<ItemImage>> imagesForItem(int itemId) async {
    final rows = await (select(itemImages)
          ..where((t) => t.itemId.equals(itemId)))
        .get();
    rows.sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
    return rows;
  }

  Future<Map<int, List<ItemImage>>> imagesForItems(List<int> itemIds) async {
    if (itemIds.isEmpty) return <int, List<ItemImage>>{};
    final rows = await (select(itemImages)
          ..where((t) => t.itemId.isIn(itemIds)))
        .get();
    final map = <int, List<ItemImage>>{};
    for (final row in rows) {
      map.putIfAbsent(row.itemId, () => <ItemImage>[]).add(row);
    }
    for (final list in map.values) {
      list.sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
    }
    return map;
  }

  Future<int> insertImage(ItemImagesCompanion companion) =>
      into(itemImages).insert(companion);

  Future<int> deleteImage(int id) =>
      (delete(itemImages)..where((t) => t.id.equals(id))).go();

  Future<int> deleteImagesOfItem(int itemId) =>
      (delete(itemImages)..where((t) => t.itemId.equals(itemId))).go();

  Future<List<ItemImage>> allImages() => select(itemImages).get();

  Future<void> replaceImages(int itemId, List<String> relativePaths) async {
    await transaction(() async {
      await deleteImagesOfItem(itemId);
      for (var i = 0; i < relativePaths.length; i++) {
        await into(itemImages).insert(
          ItemImagesCompanion.insert(
            itemId: itemId,
            relativePath: relativePaths[i],
            sort: Value(i),
          ),
        );
      }
    });
  }

  // ------------------------------------------------------------ 标签关联

  Future<List<int>> tagIdsForItem(int itemId) async {
    final rows = await (select(itemTagRel)
          ..where((t) => t.itemId.equals(itemId)))
        .get();
    return rows.map((r) => r.tagId).toList();
  }

  Future<Map<int, List<int>>> tagIdsForItems(List<int> itemIds) async {
    if (itemIds.isEmpty) return <int, List<int>>{};
    final rows = await (select(itemTagRel)
          ..where((t) => t.itemId.isIn(itemIds)))
        .get();
    final map = <int, List<int>>{};
    for (final row in rows) {
      map.putIfAbsent(row.itemId, () => <int>[]).add(row.tagId);
    }
    return map;
  }

  Future<void> setItemTags(int itemId, List<int> tagIds) async {
    await transaction(() async {
      await (delete(itemTagRel)..where((t) => t.itemId.equals(itemId))).go();
      for (final tagId in tagIds.toSet()) {
        await into(itemTagRel).insert(
          ItemTagRelData(itemId: itemId, tagId: tagId),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<List<int>> itemIdsForTags(List<int> tagIds) async {
    if (tagIds.isEmpty) return <int>[];
    final rows = await (select(itemTagRel)
          ..where((t) => t.tagId.isIn(tagIds)))
        .get();
    return rows.map((r) => r.itemId).toSet().toList();
  }
}