import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/item_status.dart';
import '../../domain/models/views.dart';
import '../common/widgets/empty_state.dart';
import 'items_controller.dart';

/// 轻量统计看板：物品总数、分类统计、总价值
class ItemStatsPage extends ConsumerWidget {
  const ItemStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsValue = ref.watch(itemStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('物品统计')),
      body: statsValue.when(
        data: (stats) => _StatsBody(stats: stats),
        loading: () => const LoadingState(),
        error: (error, stack) => ErrorState(message: '$error'),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final ItemStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCategory = stats.categoryCounts.values.isEmpty
        ? 1
        : stats.categoryCounts.values.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                label: '物品总数',
                value: '${stats.totalCount}',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: '总价值',
                value: stats.totalValue.toStringAsFixed(2),
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('状态分布', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final status in ItemStatus.values)
              Chip(
                label: Text(
                  '${status.label} ${stats.statusCounts[status] ?? 0}',
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('分类统计', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (stats.categoryCounts.isEmpty)
          Text('暂无分类数据', style: theme.textTheme.bodySmall)
        else
          for (final entry in stats.categoryCounts.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: Text(entry.key)),
                      Text('${entry.value} 件'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: maxCategory == 0 ? 0 : entry.value / maxCategory,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 24),
        Text(
          '统计基于当前筛选条件（在列表页顶部筛选后回到本页查看）',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}