import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/time_utils.dart';
import '../../domain/models/backup_models.dart';
import '../common/widgets/empty_state.dart';
import '../items/items_controller.dart';
import '../notes/notes_controller.dart';
import 'backup_actions.dart';
import 'backup_controller.dart';

/// 备份状态面板：备份 / 恢复 / 双向同步 / 快照 / 冲突 / 日志
class BackupCenterPage extends ConsumerStatefulWidget {
  const BackupCenterPage({super.key});

  @override
  ConsumerState<BackupCenterPage> createState() => _BackupCenterPageState();
}

class _BackupCenterPageState extends ConsumerState<BackupCenterPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupCenterProvider.notifier).load(withRemote: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(backupCenterProvider);
    final controller = ref.read(backupCenterProvider.notifier);
    final config = ref.watch(activeWebdavConfigProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份中心'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: () => controller.load(withRemote: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
        children: <Widget>[
          if (state.busy)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LinearProgressIndicator(),
                  const SizedBox(height: 6),
                  Text(state.busyLabel, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('状态面板', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  _Row(label: '当前配置', value: config?.name ?? '未配置'),
                  _Row(
                    label: '上次同步时间',
                    value: state.syncState?.lastSyncAt == null
                        ? '—'
                        : TimeUtils.formatDateTime(
                            TimeUtils.toDateTime(state.syncState!.lastSyncAt),
                          ),
                  ),
                  _Row(
                    label: '远端数据库指纹',
                    value: state.syncState?.dbMd5 == null
                        ? '—'
                        : state.syncState!.dbMd5!.substring(0, 8),
                  ),
                  _Row(label: '远端快照数量', value: '${state.snapshots.length}'),
                  if (state.remoteError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '远端访问失败：${state.remoteError}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: state.busy
                            ? null
                            : () => runBackupWithFeedback(context, ref),
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('立即备份'),
                      ),
                      OutlinedButton.icon(
                        onPressed: state.busy
                            ? null
                            : () => runSyncWithFeedback(context, ref),
                        icon: const Icon(Icons.sync),
                        label: const Text('双向同步'),
                      ),
                      OutlinedButton.icon(
                        onPressed: state.busy
                            ? null
                            : () => _restore(context, null, '最新备份'),
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('恢复最新'),
                      ),
                      OutlinedButton.icon(
                        onPressed: state.busy
                            ? null
                            : () async {
                                final keep = ref.read(settingsProvider).snapshotKeep;
                                final removed =
                                    await controller.pruneSnapshots(keep);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('已清理 $removed 份历史快照（保留 $keep 份）'),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('清理快照'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.lastReport?.conflicts.isNotEmpty ?? false) ...<Widget>[
            const SizedBox(height: 12),
            _ConflictCard(
              conflicts: state.lastReport!.conflicts,
              onKeepLocal: () async {
                final report = await controller.resolveWithLocal();
                ref.invalidate(itemsControllerProvider);
                ref.invalidate(notesControllerProvider);
                if (context.mounted) {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('已按本地数据覆盖远端'),
                      content: Text(report.message),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('知道了'),
                        ),
                      ],
                    ),
                  );
                }
              },
              onKeepRemote: () => _restore(context, null, '远端最新备份'),
            ),
          ],
          const SizedBox(height: 16),
          Text('历史快照', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          if (state.snapshots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: EmptyState(
                icon: Icons.history,
                title: '暂无快照',
                subtitle: '每次「立即备份」都会生成一份快照',
              ),
            )
          else
            for (final snapshot in state.snapshots)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(
                    snapshot.createdAt == null
                        ? snapshot.id
                        : TimeUtils.formatDateTime(snapshot.createdAt),
                  ),
                  subtitle: Text(
                    '数据库 ${(snapshot.dbSize / 1024).toStringAsFixed(1)} KB · '
                    '图片 ${snapshot.imageCount} 张'
                    '${snapshot.md5 == null ? '' : ' · md5 ${snapshot.md5!.substring(0, 8)}'}',
                  ),
                  trailing: TextButton(
                    onPressed: state.busy
                        ? null
                        : () => _restore(context, snapshot, snapshot.id),
                    child: const Text('恢复'),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text('同步日志', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (state.logs.isNotEmpty)
                TextButton(
                  onPressed: () => controller.clearLogs(),
                  child: const Text('清空'),
                ),
            ],
          ),
          if (state.logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('还没有备份 / 同步记录', style: theme.textTheme.bodySmall),
            )
          else
            for (final log in state.logs)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  log.status == 'success'
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: log.status == 'success'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                title: Text('${_typeLabel(log.type)} · ${log.status}'),
                subtitle: Text(
                  '${TimeUtils.formatDateTime(TimeUtils.toDateTime(log.createAt))}'
                  '${log.message == null ? '' : '\n${log.message}'}',
                ),
              ),
        ],
      ),
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'backup':
        return '备份';
      case 'restore':
        return '恢复';
      case 'sync':
        return '同步';
      case 'export':
        return '导出';
      case 'import':
        return '导入';
      default:
        return type;
    }
  }

  Future<void> _restore(
    BuildContext context,
    SnapshotInfo? snapshot,
    String label,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复将覆盖本地数据'),
        content: Text(
          '确定使用「$label」覆盖当前本地数据吗？\n\n'
          '流程：下载远端数据库 → 校验 md5（失败则拒绝恢复）→ '
          '本地留底到 restore_backup 目录 → 覆盖本地。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final report = await ref
        .read(backupCenterProvider.notifier)
        .runRestore(snapshot);
    ref.invalidate(itemsControllerProvider);
    ref.invalidate(notesControllerProvider);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.success ? '恢复完成' : '恢复失败'),
        content: Text(report.message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflicts,
    required this.onKeepLocal,
    required this.onKeepRemote,
  });

  final List<ConflictItem> conflicts;
  final Future<void> Function() onKeepLocal;
  final Future<void> Function() onKeepRemote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text('同步冲突（${conflicts.length}）',
                    style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            for (final conflict in conflicts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '· ${conflict.kind == 'db' ? '数据库' : '图片'}  '
                  '${conflict.label}\n'
                  '  本地：${TimeUtils.formatDateTime(conflict.localModified)}  '
                  '远端：${TimeUtils.formatDateTime(conflict.remoteModified)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '为避免数据错乱，系统不会自动合并。冲突副本已保存在本地 conflict 目录。',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => onKeepLocal(),
                  child: const Text('以本地为准'),
                ),
                FilledButton(
                  onPressed: () => onKeepRemote(),
                  child: const Text('以远端为准'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}