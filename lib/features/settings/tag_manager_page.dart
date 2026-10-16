import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../common/widgets/empty_state.dart';
import 'storage_controller.dart';

/// 标签管理：物品与碎念共用标签池
class TagManagerPage extends ConsumerWidget {
  const TagManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageValue = ref.watch(tagUsageListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('标签管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新建标签'),
      ),
      body: usageValue.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.sell_outlined,
              title: '还没有标签',
              subtitle: '标签可用于物品分类、碎念筛选',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = list[index];
              return ListTile(
                title: Text(entry.tag.name),
                subtitle: Text('被引用 ${entry.count} 次'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      tooltip: '重命名',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _rename(context, ref, entry.tag.id, entry.tag.name),
                    ),
                    IconButton(
                      tooltip: '删除',
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _delete(context, ref, entry.tag.id, entry.tag.name, entry.count),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingState(),
        error: (error, stack) => ErrorState(message: '$error'),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '想法 / 待办 / 灵感 / 数码'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(tagRepositoryProvider).ensure(name);
    ref.invalidate(tagUsageListProvider);
    ref.invalidate(tagsProvider);
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    int id,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名标签'),
        content: TextField(controller: controller, autofocus: true),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(tagRepositoryProvider).rename(id, name);
    ref.invalidate(tagUsageListProvider);
    ref.invalidate(tagsProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
    int count,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除标签「$name」？'),
        content: Text(
          count == 0
              ? '该标签还没有被使用。'
              : '该标签被引用 $count 次，删除后相关物品 / 碎念会失去这个标签（不会删除内容本身）。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(tagRepositoryProvider).delete(id);
    ref.invalidate(tagUsageListProvider);
    ref.invalidate(tagsProvider);
  }
}