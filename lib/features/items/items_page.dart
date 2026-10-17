import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/item_sort.dart';
import '../../domain/models/item_status.dart';import '../common/widgets/empty_state.dart';
import '../search/global_search_page.dart';
import 'item_detail_page.dart';
import 'item_form_page.dart';
import 'item_stats_page.dart';
import 'items_controller.dart';
import 'widgets/item_card.dart';

/// Tab2：物品台账
class ItemsPage extends ConsumerWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsValue = ref.watch(itemsControllerProvider);
    final filter = ref.watch(itemFilterProvider);
    final tagsValue = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('物品台账'),
        actions: <Widget>[
          IconButton(
            tooltip: '全局检索',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const GlobalSearchPage(),
              ),
            ),
          ),
          IconButton(
            tooltip: '统计',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ItemStatsPage(),
              ),
            ),
          ),
          PopupMenuButton<ItemSort>(
            tooltip: '排序',
            icon: const Icon(Icons.sort),
            onSelected: (sort) =>
                ref.read(itemFilterProvider.notifier).setSort(sort),
            itemBuilder: (context) => <PopupMenuEntry<ItemSort>>[
              for (final sort in ItemSort.values)
                CheckedPopupMenuItem<ItemSort>(
                  value: sort,
                  checked: filter.sort == sort,
                  child: Text(sort.label),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _ItemFilterBar(filter: filter, tagsValue: tagsValue),
          const Divider(height: 1),
          Expanded(
            child: itemsValue.when(
              data: (items) {
                // 下拉刷新：列表与空状态均可触发（需求 1）
                Future<void> onRefresh() =>
                    ref.read(itemsControllerProvider.notifier).refresh();
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: filter.hasFilter ? '没有符合条件的物品' : '还没有物品',
                            subtitle: filter.hasFilter
                                ? '试试清空筛选条件'
                                : '点击右下角按钮，拍照并录入你的第一件物品',
                            actionLabel: '新增物品',
                            onAction: () => _openForm(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = items[index];
                      return ItemCard(
                        entry: entry,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                ItemDetailPage(itemId: entry.item.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingState(label: '正在加载物品…'),
              error: (error, stack) => ErrorState(
                message: '$error',
                onRetry: () =>
                    ref.read(itemsControllerProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('新增物品'),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const ItemFormPage()),
    );
  }
}

class _ItemFilterBar extends ConsumerWidget {
  const _ItemFilterBar({required this.filter, required this.tagsValue});

  final ItemFilter filter;
  final AsyncValue<List<Tag>> tagsValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(itemFilterProvider.notifier);
    final tags = tagsValue.value ?? const <Tag>[];
    String? categoryName;
    for (final tag in tags) {
      if (tag.id == filter.categoryId) categoryName = tag.name;
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          Center(
            child: ActionChip(
              avatar: const Icon(Icons.category_outlined, size: 16),
              label: Text(categoryName == null ? '分类' : '分类：$categoryName'),
              onPressed: () async {
                final selected = await showModalBottomSheet<_Option<int?>>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => _OptionSheet<int?>(
                    title: '按分类筛选',
                    options: <_Option<int?>>[
                      const _Option<int?>(value: null, label: '全部分类'),
                      for (final tag in tags)
                        _Option<int?>(value: tag.id, label: tag.name),
                    ],
                  ),
                );
                if (selected == null) return;
                controller.setCategory(selected.value);
              },
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: ActionChip(
              avatar: const Icon(Icons.place_outlined, size: 16),
              label: Text(
                filter.location == null ? '存放位置' : '位置：${filter.location}',
              ),
              onPressed: () async {
                final locations = await ref.read(locationsProvider.future);
                if (!context.mounted) return;
                final selected = await showModalBottomSheet<_Option<String?>>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => _OptionSheet<String?>(
                    title: '按存放位置筛选',
                    options: <_Option<String?>>[
                      const _Option<String?>(value: null, label: '全部位置'),
                      for (final location in locations)
                        _Option<String?>(value: location, label: location),
                    ],
                  ),
                );
                if (selected == null) return;
                controller.setLocation(selected.value);
              },
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: ActionChip(
              avatar: const Icon(Icons.tune, size: 16),
              label: Text(_statusLabel(filter)),
              onPressed: () async {
                final selected =
                    await showModalBottomSheet<_Option<_StatusSelection>>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => _OptionSheet<_StatusSelection>(
                    title: '按状态筛选',
                    options: <_Option<_StatusSelection>>[
                      const _Option<_StatusSelection>(
                        value: _StatusSelection(null, null),
                        label: '全部状态',
                      ),
                      for (final status in ItemStatus.values)
                        _Option<_StatusSelection>(
                          value: _StatusSelection(status.value, null),
                          label: status.label,
                        ),
                      const _Option<_StatusSelection>(
                        value: _StatusSelection(null, WarrantyFilter.expiring),
                        label: '质保临期（30 天内）',
                      ),
                      const _Option<_StatusSelection>(
                        value: _StatusSelection(null, WarrantyFilter.expired),
                        label: '质保已到期',
                      ),
                    ],
                  ),
                );
                if (selected == null) return;
                controller.setStatus(selected.value.status);
                controller.setWarranty(selected.value.warranty);
              },
            ),
          ),
          if (filter.hasFilter)
            Center(
              child: TextButton.icon(
                onPressed: controller.reset,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('清空'),
              ),
            ),
        ],
      ),
    );
  }

  static String _statusLabel(ItemFilter filter) {
    if (filter.warranty != null) return '状态：${filter.warranty!.label}';
    if (filter.status != null) {
      return '状态：${ItemStatus.fromValue(filter.status).label}';
    }
    return '状态';
  }
}

/// 状态筛选的组合值：生命周期状态与质保状态可叠加。
class _StatusSelection {
  const _StatusSelection(this.status, this.warranty);

  final String? status;
  final WarrantyFilter? warranty;
}

class _Option<T> {
  const _Option({required this.value, required this.label});

  final T value;
  final String label;
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({required this.title, required this.options});

  final String title;
  final List<_Option<T>> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (final option in options)
                  ListTile(
                    title: Text(option.label),
                    onTap: () => Navigator.pop(context, option),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}