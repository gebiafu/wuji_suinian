import '../../data/db/database.dart';
import 'item_status.dart';

/// 物品 + 图片 + 标签 聚合视图（列表 / 详情共用）。
class ItemWithImages {
  const ItemWithImages({
    required this.item,
    this.images = const <ItemImage>[],
    this.tags = const <Tag>[],
  });

  final Item item;
  final List<ItemImage> images;
  final List<Tag> tags;

  ItemStatus get status => ItemStatus.fromValue(item.status);

  String? get coverRelativePath =>
      images.isEmpty ? null : images.first.relativePath;

  /// 分类标签（category_id 指向 tags 表）
  Tag? get category {
    for (final tag in tags) {
      if (tag.id == item.categoryId) return tag;
    }
    return null;
  }

  List<Tag> get normalTags =>
      tags.where((t) => t.id != item.categoryId).toList(growable: false);

  int? get daysToWarrantyEnd {
    final end = item.warrantyEndDate;
    if (end == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime.fromMillisecondsSinceEpoch(end);
    return DateTime(target.year, target.month, target.day)
        .difference(today)
        .inDays;
  }

  bool get warrantyExpiringSoon {
    final days = daysToWarrantyEnd;
    return days != null && days >= 0 && days <= 30;
  }

  bool get warrantyExpired {
    final days = daysToWarrantyEnd;
    return days != null && days < 0;
  }
}

/// 碎念 + 标签 聚合视图。
class NoteWithTags {
  const NoteWithTags({required this.note, this.tags = const <Tag>[]});

  final BulletNote note;
  final List<Tag> tags;
}

/// 跨模块全文检索结果。
class SearchResults {
  const SearchResults({
    required this.keyword,
    this.items = const <ItemWithImages>[],
    this.notes = const <NoteWithTags>[],
  });

  final String keyword;
  final List<ItemWithImages> items;
  final List<NoteWithTags> notes;

  int get total => items.length + notes.length;

  bool get isEmpty => total == 0;
}

/// 标签使用情况（标签管理页）
class TagUsage {
  const TagUsage({required this.tag, required this.count});

  final Tag tag;
  final int count;
}

/// 物品轻量统计
class ItemStats {
  const ItemStats({
    required this.totalCount,
    required this.totalValue,
    this.statusCounts = const <ItemStatus, int>{},
    this.categoryCounts = const <String, int>{},
  });

  final int totalCount;
  final double totalValue;
  final Map<ItemStatus, int> statusCounts;
  final Map<String, int> categoryCounts;
}

/// 存储占用统计
class StorageStats {
  const StorageStats({
    required this.dbBytes,
    required this.imageBytes,
    required this.imageCount,
    required this.orphanCount,
    required this.orphanBytes,
    required this.itemCount,
    required this.noteCount,
    required this.tagCount,
  });

  final int dbBytes;
  final int imageBytes;
  final int imageCount;
  final int orphanCount;
  final int orphanBytes;
  final int itemCount;
  final int noteCount;
  final int tagCount;

  int get totalBytes => dbBytes + imageBytes;
}