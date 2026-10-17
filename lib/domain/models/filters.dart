import 'item_sort.dart';

/// 质保筛选（物品列表「状态」筛选的扩展选项，动态计算，非入库字段）。
enum WarrantyFilter {
  /// 质保临期：未过期且剩余天数在提醒窗口内（默认 30 天）
  expiring('质保临期'),

  /// 质保已到期
  expired('质保已到期');

  const WarrantyFilter(this.label);
  final String label;
}

/// 物品列表筛选条件。
class ItemFilter {
  const ItemFilter({
    this.keyword = '',
    this.categoryId,
    this.location,
    this.status,
    this.warranty,
    this.tagIds = const <int>[],
    this.sort = ItemSort.createdDesc,
  });

  final String keyword;
  final int? categoryId;
  final String? location;
  final String? status;

  /// 质保状态筛选（与生命周期状态筛选可叠加）
  final WarrantyFilter? warranty;
  final List<int> tagIds;
  final ItemSort sort;

  bool get hasFilter =>
      keyword.trim().isNotEmpty ||
      categoryId != null ||
      (location != null && location!.isNotEmpty) ||
      status != null ||
      warranty != null ||
      tagIds.isNotEmpty;

  ItemFilter copyWith({
    String? keyword,
    int? categoryId,
    String? location,
    String? status,
    WarrantyFilter? warranty,
    List<int>? tagIds,
    ItemSort? sort,
    bool clearCategory = false,
    bool clearLocation = false,
    bool clearStatus = false,
    bool clearWarranty = false,
  }) {
    return ItemFilter(
      keyword: keyword ?? this.keyword,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      location: clearLocation ? null : (location ?? this.location),
      status: clearStatus ? null : (status ?? this.status),
      warranty: clearWarranty ? null : (warranty ?? this.warranty),
      tagIds: tagIds ?? this.tagIds,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ItemFilter &&
      other.keyword == keyword &&
      other.categoryId == categoryId &&
      other.location == location &&
      other.status == status &&
      other.warranty == warranty &&
      _listEquals(other.tagIds, tagIds) &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(
        keyword,
        categoryId,
        location,
        status,
        warranty,
        Object.hashAll(tagIds),
        sort,
      );
}

/// 碎碎念筛选条件。
class NoteFilter {
  const NoteFilter({
    this.keyword = '',
    this.onlyTodo = false,
    this.onlyUnfinishedTodo = false,
    this.onlyTop = false,
    this.tagIds = const <int>[],
  });

  final String keyword;

  /// 只看待办
  final bool onlyTodo;

  /// 只看未完成待办
  final bool onlyUnfinishedTodo;

  /// 只看置顶
  final bool onlyTop;
  final List<int> tagIds;

  bool get hasFilter =>
      keyword.trim().isNotEmpty || onlyTodo || onlyUnfinishedTodo || onlyTop || tagIds.isNotEmpty;

  NoteFilter copyWith({
    String? keyword,
    bool? onlyTodo,
    bool? onlyUnfinishedTodo,
    bool? onlyTop,
    List<int>? tagIds,
  }) {
    return NoteFilter(
      keyword: keyword ?? this.keyword,
      onlyTodo: onlyTodo ?? this.onlyTodo,
      onlyUnfinishedTodo: onlyUnfinishedTodo ?? this.onlyUnfinishedTodo,
      onlyTop: onlyTop ?? this.onlyTop,
      tagIds: tagIds ?? this.tagIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NoteFilter &&
      other.keyword == keyword &&
      other.onlyTodo == onlyTodo &&
      other.onlyUnfinishedTodo == onlyUnfinishedTodo &&
      other.onlyTop == onlyTop &&
      _listEquals(other.tagIds, tagIds);

  @override
  int get hashCode => Object.hash(
        keyword,
        onlyTodo,
        onlyUnfinishedTodo,
        onlyTop,
        Object.hashAll(tagIds),
      );
}

bool _listEquals(List<int> a, List<int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}