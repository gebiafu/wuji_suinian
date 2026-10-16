import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/item_sort.dart';
import '../../domain/models/item_status.dart';
import '../common/widgets/empty_state.dart';
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
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: filter.hasFilter ? '没有符合条件的物品' : '还没有物品',
                    subtitle: filter.hasFilter
                        ? '试试清空筛选条件'
                        : '点击右下角按钮，拍照并录入你的第一件物品',
                    actionLabel: '新增物品',
                    onAction: () => _openForm(context),
                  );
                }
                return ListView.separated(
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
              label: Text(
                filter.status == null
                    ? '状态'
                    : '状态：${ItemStatus.fromValue(filter.status).label}',
              ),
              onPressed: () async {
                final selected = await showModalBottomSheet<_Option<String?>>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => _OptionSheet<String?>(
                    title: '按状态筛选',
                    options: <_Option<String?>>[
                      const _Option<String?>(value: null, label: '全部状态'),
                      for (final status in ItemStatus.values)
                        _Option<String?>(value: status.value, label: status.label),
                    ],
                  ),
                );
                if (selected == null) return;
                controller.setStatus(selected.value);
              },
            ),
          ),
          const SizedBox(width: 8),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: FilterChip(
                  label: Text('#${tag.name}'),
                  selected: filter.tagIds.contains(tag.id),
                  onSelected: (_) => controller.toggleTag(tag.id),
                ),
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