import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/item_sort.dart';
import '../../domain/models/views.dart';
import '../../data/repositories/item_repository.dart';

final itemFilterProvider = NotifierProvider<ItemFilterNotifier, ItemFilter>(
  ItemFilterNotifier.new,
);

class ItemFilterNotifier extends Notifier<ItemFilter> {
  @override
  ItemFilter build() => const ItemFilter();

  void setKeyword(String keyword) => state = state.copyWith(keyword: keyword);

  void setCategory(int? categoryId) => state = categoryId == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(categoryId: categoryId);

  void setLocation(String? location) => state = location == null
      ? state.copyWith(clearLocation: true)
      : state.copyWith(location: location);

  void setStatus(String? status) => state = status == null
      ? state.copyWith(clearStatus: true)
      : state.copyWith(status: status);

  void setWarranty(WarrantyFilter? warranty) => state = warranty == null
      ? state.copyWith(clearWarranty: true)
      : state.copyWith(warranty: warranty);

  void setSort(ItemSort sort) => state = state.copyWith(sort: sort);

  void toggleTag(int tagId) {
    final ids = List<int>.of(state.tagIds);
    if (ids.contains(tagId)) {
      ids.remove(tagId);
    } else {
      ids.add(tagId);
    }
    state = state.copyWith(tagIds: ids);
  }

  void reset() => state = const ItemFilter();
}

final itemsControllerProvider =
    AsyncNotifierProvider<ItemsController, List<ItemWithImages>>(
  ItemsController.new,
);

class ItemsController extends AsyncNotifier<List<ItemWithImages>> {
  @override
  Future<List<ItemWithImages>> build() {
    ref.watch(databaseProvider);
    final filter = ref.watch(itemFilterProvider);
    return ref.read(itemRepositoryProvider).list(filter);
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    // 同步失效其它依赖物品数据的 provider：
    // 修复「编辑（含新增图片）后详情页仍显示旧数据，需退出重进才刷新」的问题。
    ref.invalidate(itemDetailProvider);
    ref.invalidate(locationsProvider);
    await future;
  }

  Future<int> create(ItemDraft draft) async {
    final id = await ref.read(itemRepositoryProvider).create(draft);
    await _reload();
    await _rescheduleWarranty();
    return id;
  }

  Future<void> updateItem(ItemDraft draft) async {
    await ref.read(itemRepositoryProvider).update(draft);
    await _reload();
    await _rescheduleWarranty();
  }

  Future<void> remove(int id, {bool deleteImages = true}) async {
    await ref
        .read(itemRepositoryProvider)
        .delete(id, deleteImages: deleteImages);
    await _reload();
    await _rescheduleWarranty();
  }

  Future<void> refresh() => _reload();

  /// 物品变化后刷新质保提醒
  Future<void> _rescheduleWarranty() async {
    try {
      final service = ref.read(warrantyReminderServiceProvider);
      await service.reschedule();
    } catch (_) {
      // 通知不可用时静默忽略
    }
  }
}

/// 当前筛选条件下的轻量统计
final itemStatsProvider = FutureProvider<ItemStats>((ref) {
  ref.watch(databaseProvider);
  final filter = ref.watch(itemFilterProvider);
  return ref.read(itemRepositoryProvider).stats(filter: filter);
});

final itemDetailProvider =
    FutureProvider.family<ItemWithImages?, int>((ref, id) async {
  ref.watch(databaseProvider);
  return ref.read(itemRepositoryProvider).detail(id);
});