import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../domain/models/filters.dart';
import '../common/widgets/empty_state.dart';
import '../search/global_search_page.dart';
import 'notes_controller.dart';
import 'widgets/note_bubble.dart';
import 'widgets/note_input_bar.dart';

/// Tab1：碎碎念（子弹笔记，默认首页）——短信式信息流
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesValue = ref.watch(notesControllerProvider);
    final filter = ref.watch(noteFilterProvider);
    final tagsValue = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('碎碎念'),
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
        ],
      ),
      body: Column(
        children: <Widget>[
          _FilterBar(filter: filter, tagsValue: tagsValue),
          const Divider(height: 1),
          Expanded(
            child: notesValue.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: filter.hasFilter ? '没有符合条件的碎念' : '还没有碎念',
                    subtitle: filter.hasFilter
                        ? '试试更换筛选条件'
                        : '在下方输入框随手记一条，支持图片与待办',
                    actionLabel: filter.hasFilter ? '清空筛选' : null,
                    onAction: filter.hasFilter
                        ? () => ref.read(noteFilterProvider.notifier).reset()
                        : null,
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notes.length,
                  itemBuilder: (context, index) => NoteBubble(
                    entry: notes[index],
                    keyword: filter.keyword,
                  ),
                );
              },
              loading: () => const LoadingState(label: '正在加载碎念…'),
              error: (error, stack) => ErrorState(
                message: '$error',
                onRetry: () =>
                    ref.read(notesControllerProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const NoteInputBar(),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter, required this.tagsValue});

  final NoteFilter filter;
  final AsyncValue<List<Tag>> tagsValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(noteFilterProvider.notifier);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          Center(
            child: FilterChip(
              label: const Text('待办'),
              selected: filter.onlyTodo,
              onSelected: (_) => controller.toggleOnlyTodo(),
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: FilterChip(
              label: const Text('未完成'),
              selected: filter.onlyUnfinishedTodo,
              onSelected: (_) => controller.toggleOnlyUnfinished(),
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: FilterChip(
              label: const Text('置顶'),
              selected: filter.onlyTop,
              onSelected: (_) => controller.toggleOnlyTop(),
            ),
          ),
          const SizedBox(width: 8),
          for (final tag in tagsValue.value ?? const <Tag>[])
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

