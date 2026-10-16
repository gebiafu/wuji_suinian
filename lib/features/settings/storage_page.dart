import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../common/widgets/empty_state.dart';
import 'storage_controller.dart';

/// 存储统计：图片占用、数据库大小、清理孤儿图片
class StoragePage extends ConsumerWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsValue = ref.watch(storageStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('存储统计'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: () {
              ref.invalidate(storageStatsProvider);
              ref.invalidate(orphanCountProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: statsValue.when(
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('总占用', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      _formatBytes(stats.totalBytes),
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _StatRow(
                      label: '数据库（含 WAL）',
                      value: _formatBytes(stats.dbBytes),
                    ),
                    _StatRow(
                      label: '图片文件（${stats.imageCount} 张）',
                      value: _formatBytes(stats.imageBytes),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('数据量', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _StatRow(label: '物品', value: '${stats.itemCount} 条'),
                    _StatRow(label: '碎念', value: '${stats.noteCount} 条'),
                    _StatRow(label: '标签', value: '${stats.tagCount} 个'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('无引用图片', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      stats.orphanCount == 0
                          ? '没有发现无引用图片'
                          : '发现 ${stats.orphanCount} 张无引用图片，占用 '
                              '${_formatBytes(stats.orphanBytes)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '无引用图片指数据库中已没有记录指向的图片文件'
                      '（例如删除记录时选择了保留原图）。清理后无法恢复。',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: stats.orphanCount == 0
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('清理无引用图片？'),
                                  content: Text(
                                    '将删除 ${stats.orphanCount} 个文件，'
                                    '释放 ${_formatBytes(stats.orphanBytes)}，操作不可撤销。',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('取消'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('清理'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              final removed = await ref
                                  .read(storageServiceProvider)
                                  .cleanOrphans();
                              ref.invalidate(storageStatsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('已清理 $removed 个文件')),
                                );
                              }
                            },
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('清理无引用图片'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const LoadingState(label: '正在统计…'),
        error: (error, stack) => ErrorState(message: '$error'),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// 供其它页面复用的格式化方法
String formatBytes(int bytes) => StoragePage._formatBytes(bytes);