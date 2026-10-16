import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/time_utils.dart';
import '../../domain/models/views.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/image_widgets.dart';
import 'item_form_page.dart';
import 'items_controller.dart';

/// 物品详情：大图浏览 + 全部字段 + 借出信息
class ItemDetailPage extends ConsumerWidget {
  const ItemDetailPage({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(itemDetailProvider(itemId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('物品详情'),
        actions: <Widget>[
          IconButton(
            tooltip: '复制信息',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () {
              final entry = value.value;
              if (entry == null) return;
              Clipboard.setData(ClipboardData(text: _summary(entry)));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('已复制物品信息')));
            },
          ),
          IconButton(
            tooltip: '编辑',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final entry = value.value;
              if (entry == null) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => ItemFormPage(initial: entry),
                ),
              );
            },
          ),
          IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, value.value),
          ),
        ],
      ),
      body: value.when(
        data: (entry) {
          if (entry == null) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: '物品不存在',
              subtitle: '可能已被删除，请返回列表刷新',
            );
          }
          return _DetailBody(entry: entry);
        },
        loading: () => const LoadingState(),
        error: (error, stack) => ErrorState(message: '$error'),
      ),
    );
  }

  static String _summary(ItemWithImages entry) {
    final item = entry.item;
    final buffer = StringBuffer()..writeln('【${item.name}】');
    if (item.location != null) buffer.writeln('位置：${item.location}');
    if (item.price != null) buffer.writeln('价格：${item.price}${item.unit}');
    if (item.buyChannel != null) buffer.writeln('渠道：${item.buyChannel}');
    if (item.buyDate != null) {
      buffer.writeln('购买日期：${TimeUtils.formatDate(TimeUtils.toDateTime(item.buyDate))}');
    }
    if (item.warrantyEndDate != null) {
      buffer.writeln(
        '质保到期：${TimeUtils.formatDate(TimeUtils.toDateTime(item.warrantyEndDate))}',
      );
    }
    buffer.writeln('状态：${entry.status.label}');
    if (item.lendTarget != null) buffer.writeln('借给：${item.lendTarget}');
    if (item.description != null) buffer.writeln('备注：${item.description}');
    return buffer.toString().trim();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ItemWithImages? entry,
  ) async {
    if (entry == null) return;
    var deleteImages = ref.read(settingsProvider).deleteImageWithItem;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('删除物品'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('确定删除「${entry.item.name}」吗？'),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: deleteImages,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) =>
                    setState(() => deleteImages = value ?? false),
                title: const Text('同时删除本地原图文件'),
                subtitle: Text(
                  deleteImages
                      ? '记录与原图都会删除，无法恢复'
                      : '仅删除数据库记录，原图保留（可在设置中清理）',
                ),
              ),
            ],
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
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(itemsControllerProvider.notifier)
        .remove(entry.item.id, deleteImages: deleteImages);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.entry});

  final ItemWithImages entry;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final theme = Theme.of(context);
    final images = entry.images.map((e) => e.relativePath).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: <Widget>[
        if (images.isNotEmpty)
          SizedBox(
            height: 260,
            child: PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ImageGalleryViewer(
                      relativePaths: images,
                      initialIndex: index,
                    ),
                  ),
                ),
                child: LocalImage(
                  relativePath: images[index],
                  fit: BoxFit.cover,
                  radius: 0,
                ),
              ),
            ),
          )
        else
          Container(
            height: 140,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const Text('暂无图片'),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  Chip(
                    label: Text(entry.status.label),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (entry.category != null)
                    Chip(
                      label: Text(entry.category!.name),
                      visualDensity: VisualDensity.compact,
                    ),
                  for (final tag in entry.normalTags)
                    Chip(
                      label: Text('#${tag.name}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(label: '存放位置', value: item.location),
              _InfoRow(
                label: '购买价格',
                value: item.price == null ? null : '${item.price} ${item.unit}',
              ),
              _InfoRow(label: '购买渠道', value: item.buyChannel),
              _InfoRow(
                label: '购买日期',
                value: TimeUtils.formatDate(TimeUtils.toDateTime(item.buyDate)),
              ),
              _InfoRow(
                label: '质保到期',
                value: TimeUtils.formatDate(
                  TimeUtils.toDateTime(item.warrantyEndDate),
                ),
                trailing: entry.daysToWarrantyEnd == null
                    ? null
                    : Text(
                        entry.warrantyExpired
                            ? '已过期 ${-entry.daysToWarrantyEnd!} 天'
                            : '还有 ${entry.daysToWarrantyEnd} 天',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: entry.warrantyExpired
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                      ),
              ),
              if (item.status == 'lend') ...<Widget>[
                const Divider(height: 32),
                Text('借出记录', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _InfoRow(label: '借给谁', value: item.lendTarget),
                _InfoRow(
                  label: '借出时间',
                  value:
                      TimeUtils.formatDate(TimeUtils.toDateTime(item.lendTime)),
                ),
                _InfoRow(
                  label: '预计归还',
                  value: TimeUtils.formatDate(
                    TimeUtils.toDateTime(item.expectReturnTime),
                  ),
                ),
              ],
              const Divider(height: 32),
              Text('备注 / 描述', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                (item.description == null || item.description!.isEmpty)
                    ? '（无）'
                    : item.description!,
                style: theme.textTheme.bodyMedium,
              ),
              const Divider(height: 32),
              _InfoRow(
                label: '创建时间',
                value: TimeUtils.formatDateTime(
                  TimeUtils.toDateTime(item.createAt),
                ),
              ),
              _InfoRow(
                label: '最后修改',
                value: TimeUtils.formatDateTime(
                  TimeUtils.toDateTime(item.updateAt),
                ),
              ),
              _InfoRow(label: '图片数量', value: '${entry.images.length} 张'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = (value == null || value!.trim().isEmpty) ? '—' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}