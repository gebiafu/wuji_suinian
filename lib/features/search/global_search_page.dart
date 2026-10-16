import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_utils.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/highlight_text.dart';
import '../items/item_detail_page.dart';
import '../items/widgets/item_card.dart';
import 'search_controller.dart';

/// 全局跨模块检索：物品 + 碎念 分组展示，关键词高亮
class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsValue = ref.watch(searchResultsProvider);
    final keyword = ref.watch(searchKeywordProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '搜索物品与碎念…',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (value) =>
              ref.read(searchKeywordProvider.notifier).setKeyword(value),
        ),
        actions: <Widget>[
          if (keyword.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(searchKeywordProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: keyword.trim().isEmpty
          ? const EmptyState(
              icon: Icons.search,
              title: '全局检索',
              subtitle: '一次输入，同时搜索「物品台账」与「碎碎念」，结果分组展示',
            )
          : resultsValue.when(
              data: (results) {
                if (results.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: '没有找到「${results.keyword}」',
                    subtitle: '换个关键词试试，支持名称、备注、位置、价格、标签',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: <Widget>[
                    _SectionTitle(
                      title: '物品',
                      count: results.items.length,
                    ),
                    if (results.items.isEmpty)
                      const _EmptySection(text: '没有匹配的物品')
                    else
                      for (final entry in results.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ItemCard(
                            entry: entry,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    ItemDetailPage(itemId: entry.item.id),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 12),
                    _SectionTitle(
                      title: '碎念',
                      count: results.notes.length,
                    ),
                    if (results.notes.isEmpty)
                      const _EmptySection(text: '没有匹配的碎念')
                    else
                      for (final entry in results.notes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  HighlightText(
                                    text: entry.note.content,
                                    keyword: results.keyword,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    TimeUtils.formatChatTime(
                                      TimeUtils.toDateTime(entry.note.createAt),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                );
              },
              loading: () => const LoadingState(label: '正在搜索…'),
              error: (error, stack) => ErrorState(message: '$error'),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}