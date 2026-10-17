import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/time_utils.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/item_sort.dart';
import '../../domain/models/item_status.dart';
import '../../domain/models/views.dart';
import '../db/database.dart';
import '../services/image_service.dart';

/// 新增 / 编辑物品的表单数据
class ItemDraft {
  const ItemDraft({
    this.id,
    required this.name,
    this.categoryId,
    this.location,
    this.price,
    this.unit = '元',
    this.buyChannel,
    this.buyDate,
    this.warrantyEndDate,
    this.status = ItemStatus.using,
    this.lendTarget,
    this.lendTime,
    this.expectReturnTime,
    this.description,
    this.imageRelativePaths = const <String>[],
    this.tagIds = const <int>[],
  });

  final int? id;
  final String name;
  final int? categoryId;
  final String? location;
  final double? price;
  final String unit;
  final String? buyChannel;
  final DateTime? buyDate;
  final DateTime? warrantyEndDate;
  final ItemStatus status;
  final String? lendTarget;
  final DateTime? lendTime;
  final DateTime? expectReturnTime;
  final String? description;
  final List<String> imageRelativePaths;
  final List<int> tagIds;

  bool get isEditing => id != null;
}

/// 物品仓库：列表筛选 / 检索 / 多图 / 标签 / 统计。
class ItemRepository {
  ItemRepository({required this.db, required this.imageService});

  final AppDatabase db;
  final ImageService imageService;

  Future<List<ItemWithImages>> list(ItemFilter filter) async {
    var rows = await db.itemsDao.findItems(
      keyword: filter.keyword,
      categoryId: filter.categoryId,
      location: filter.location,
      status: filter.status,
      tagIds: filter.tagIds,
    );
    // 质保筛选为动态计算（不入库），在内存中按天粒度过滤，
    // 口径与 ItemWithImages.daysToWarrantyEnd 一致。
    if (filter.warranty != null) {
      rows =
          rows.where((e) => _matchWarranty(e, filter.warranty!)).toList();
    }
    final sorted = sortItems(rows, filter.sort);
    return _decorate(sorted);
  }

  Future<ItemWithImages?> detail(int id) async {
    final item = await db.itemsDao.findById(id);
    if (item == null) return null;
    final decorated = await _decorate(<Item>[item]);
    return decorated.isEmpty ? null : decorated.first;
  }

  Future<List<ItemWithImages>> _decorate(List<Item> rows) async {
    if (rows.isEmpty) return <ItemWithImages>[];
    final ids = rows.map((e) => e.id).toList();
    final images = await db.itemsDao.imagesForItems(ids);
    final relTags = await db.itemsDao.tagIdsForItems(ids);
    final allTags = await db.tagsDao.allTags();
    final tagMap = <int, Tag>{for (final tag in allTags) tag.id: tag};
    return rows
        .map(
          (item) => ItemWithImages(
            item: item,
            images: images[item.id] ?? const <ItemImage>[],
            tags: (relTags[item.id] ?? const <int>[])
                .map((id) => tagMap[id])
                .whereType<Tag>()
                .toList(),
          ),
        )
        .toList();
  }

  /// 质保筛选匹配：临期 = 未过期且剩余天数 <= 提醒窗口；到期 = 剩余天数 < 0。
  static bool _matchWarranty(Item item, WarrantyFilter warranty) {
    final endMs = item.warrantyEndDate;
    if (endMs == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime.fromMillisecondsSinceEpoch(endMs);
    final days = DateTime(target.year, target.month, target.day)
        .difference(today)
        .inDays;
    return switch (warranty) {
      WarrantyFilter.expired => days < 0,
      WarrantyFilter.expiring =>
        days >= 0 && days <= AppConstants.warrantyReminderDays,
    };
  }

  static List<Item> sortItems(List<Item> rows, ItemSort sort) {
    final list = List<Item>.of(rows);
    int compareNullable(int? a, int? b, {required bool descending}) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return descending ? b.compareTo(a) : a.compareTo(b);
    }

    switch (sort) {
      case ItemSort.createdDesc:
        list.sort((a, b) => b.createAt.compareTo(a.createAt));
        break;
      case ItemSort.createdAsc:
        list.sort((a, b) => a.createAt.compareTo(b.createAt));
        break;
      case ItemSort.buyDateDesc:
        list.sort((a, b) => compareNullable(a.buyDate, b.buyDate, descending: true));
        break;
      case ItemSort.priceDesc:
        list.sort((a, b) {
          final va = a.price ?? -1;
          final vb = b.price ?? -1;
          return vb.compareTo(va);
        });
        break;
      case ItemSort.priceAsc:
        list.sort((a, b) {
          final va = a.price ?? double.maxFinite;
          final vb = b.price ?? double.maxFinite;
          return va.compareTo(vb);
        });
        break;
      case ItemSort.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return list;
  }

  /// 新增物品，返回新 id。
  Future<int> create(ItemDraft draft) async {
    final now = TimeUtils.nowMs();
    final id = await db.itemsDao.insertItem(
      ItemsCompanion.insert(
        name: draft.name.trim(),
        categoryId: Value(draft.categoryId),
        location: Value(_emptyToNull(draft.location)),
        price: Value(draft.price),
        unit: Value(draft.unit),
        buyChannel: Value(_emptyToNull(draft.buyChannel)),
        buyDate: Value(TimeUtils.toMs(draft.buyDate)),
        warrantyEndDate: Value(TimeUtils.toMs(draft.warrantyEndDate)),
        status: Value(draft.status.value),
        lendTarget: Value(_emptyToNull(draft.lendTarget)),
        lendTime: Value(TimeUtils.toMs(draft.lendTime)),
        expectReturnTime: Value(TimeUtils.toMs(draft.expectReturnTime)),
        description: Value(_emptyToNull(draft.description)),
        createAt: now,
        updateAt: now,
      ),
    );
    await _saveRelations(id, draft);
    return id;
  }

  Future<void> update(ItemDraft draft) async {
    final id = draft.id;
    if (id == null) {
      throw ArgumentError('update 需要提供物品 id');
    }
    final existing = await db.itemsDao.findById(id);
    if (existing == null) {
      throw StateError('物品不存在（id=$id），可能已被删除');
    }
    await db.itemsDao.updateItem(
      Item(
        id: id,
        name: draft.name.trim(),
        categoryId: draft.categoryId,
        location: _emptyToNull(draft.location),
        price: draft.price,
        unit: draft.unit,
        buyChannel: _emptyToNull(draft.buyChannel),
        buyDate: TimeUtils.toMs(draft.buyDate),
        warrantyEndDate: TimeUtils.toMs(draft.warrantyEndDate),
        status: draft.status.value,
        lendTarget: _emptyToNull(draft.lendTarget),
        lendTime: TimeUtils.toMs(draft.lendTime),
        expectReturnTime: TimeUtils.toMs(draft.expectReturnTime),
        description: _emptyToNull(draft.description),
        createAt: existing.createAt,
        updateAt: TimeUtils.nowMs(),
      ),
    );
    await _saveRelations(id, draft);
  }

  Future<void> _saveRelations(int itemId, ItemDraft draft) async {
    // 已删除图片的本地文件处理由调用方（UI）决定，这里只同步数据库记录
    await db.itemsDao.replaceImages(itemId, draft.imageRelativePaths);
    final tagIds = <int>{
      ...draft.tagIds,
      if (draft.categoryId != null) draft.categoryId!,
    }.toList();
    await db.itemsDao.setItemTags(itemId, tagIds);
  }

  /// 删除物品；[deleteImages] 为 true 时同时删除本地原图。
  Future<void> delete(int id, {required bool deleteImages}) async {
    final images = await db.itemsDao.imagesForItem(id);
    await db.itemsDao.deleteItem(id);
    if (deleteImages) {
      await imageService.deleteMany(images.map((e) => e.relativePath).toList());
    }
  }

  Future<List<String>> distinctLocations() => db.itemsDao.distinctLocations();

  Future<ItemStats> stats({ItemFilter? filter}) async {
    final rows = await db.itemsDao.findItems(
      keyword: filter?.keyword,
      categoryId: filter?.categoryId,
      location: filter?.location,
      status: filter?.status,
      tagIds: filter?.tagIds,
    );
    var totalValue = 0.0;
    final statusCounts = <ItemStatus, int>{};
    for (final item in rows) {
      totalValue += item.price ?? 0;
      final status = ItemStatus.fromValue(item.status);
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    final tagCounts = await db.itemsDao.categoryCounts();
    final tags = await db.tagsDao.allTags();
    final tagNameMap = <int, String>{for (final tag in tags) tag.id: tag.name};
    final categoryCounts = <String, int>{};
    tagCounts.forEach((tagId, count) {
      final name = tagNameMap[tagId] ?? '未分类';
      categoryCounts[name] = count;
    });
    if (rows.any((e) => e.categoryId == null)) {
      categoryCounts['未分类'] =
          rows.where((e) => e.categoryId == null).length;
    }
    return ItemStats(
      totalCount: rows.length,
      totalValue: totalValue,
      statusCounts: statusCounts,
      categoryCounts: categoryCounts,
    );
  }

  /// 质保即将到期 / 已过期的物品（用于通知与首页提示）
  Future<List<ItemWithImages>> warrantyWatchList({int days = 30}) async {
    final rows = await db.itemsDao.itemsWithWarranty();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final list = rows.where((item) {
      final end = TimeUtils.toDateTime(item.warrantyEndDate);
      if (end == null) return false;
      final target = DateTime(end.year, end.month, end.day);
      final diff = target.difference(today).inDays;
      return diff <= days;
    }).toList();
    list.sort((a, b) => (a.warrantyEndDate ?? 0).compareTo(b.warrantyEndDate ?? 0));
    return _decorate(list);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}