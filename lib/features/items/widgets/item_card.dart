import 'package:flutter/material.dart';

import '../../../core/utils/time_utils.dart';
import '../../../domain/models/item_status.dart';
import '../../../domain/models/views.dart';
import '../../common/widgets/image_widgets.dart';

/// 物品卡片：缩略图 + 名称 + 位置 + 状态
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
  });

  final ItemWithImages entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = entry.item;
    final cover = entry.coverRelativePath;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              cover == null
                  ? Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: theme.colorScheme.outline,
                      ),
                    )
                  : Stack(
                      children: <Widget>[
                        LocalImage(
                          relativePath: cover,
                          width: 76,
                          height: 76,
                        ),
                        if (entry.images.length > 1)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${entry.images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        _StatusChip(status: entry.status),
                        if (item.location != null)
                          _MetaChip(
                            icon: Icons.place_outlined,
                            label: item.location!,
                          ),
                        if (item.price != null)
                          _MetaChip(
                            icon: Icons.payments_outlined,
                            label:
                                '${_trimNumber(item.price!)}${item.unit}',
                          ),
                      ],
                    ),
                    if (entry.warrantyExpiringSoon || entry.warrantyExpired) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.warrantyExpired
                            ? '质保已过期 ${-entry.daysToWarrantyEnd!} 天'
                            : '质保还剩 ${entry.daysToWarrantyEnd} 天',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: entry.warrantyExpired
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    if (item.buyDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '购于 ${TimeUtils.formatDate(TimeUtils.toDateTime(item.buyDate))}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  static String _trimNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color background;
    late final Color foreground;
    switch (status) {
      case ItemStatus.using:
        background = scheme.primaryContainer;
        foreground = scheme.onPrimaryContainer;
        break;
      case ItemStatus.idle:
        background = scheme.secondaryContainer;
        foreground = scheme.onSecondaryContainer;
        break;
      case ItemStatus.lend:
        background = scheme.tertiaryContainer;
        foreground = scheme.onTertiaryContainer;
        break;
      case ItemStatus.discarded:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.outline;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: theme.colorScheme.outline),
        const SizedBox(width: 3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }
}