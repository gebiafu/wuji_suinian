import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../data/services/webdav/webdav_client.dart';
import '../../domain/models/backup_models.dart';
import '../items/items_controller.dart';
import '../notes/notes_controller.dart';
import 'backup_controller.dart';
import 'storage_controller.dart';

/// 统一的「阻塞操作 + 结果提示」封装
Future<T?> _runBusy<T>(
  BuildContext context,
  String label,
  Future<T> future,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        children: <Widget>[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label)),
        ],
      ),
    ),
  );
  try {
    final result = await future;
    if (context.mounted) navigator.pop();
    return result;
  } catch (error) {
    if (context.mounted) navigator.pop();
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('操作失败'),
          content: Text(describeNetworkError(error)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    }
    return null;
  }
}

Future<bool> _ensureConfig(BuildContext context, WidgetRef ref) async {
  if (ref.read(activeWebdavConfigProvider) != null) return true;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('尚未配置 WebDAV'),
      content: const Text(
        '请先到「设置 → WebDAV 配置」中填写服务器地址、账号与密码。\n'
        '离线状态下也可以使用「导出 ZIP 备份包」作为兜底方案。',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
  return false;
}

Future<void> _showReport(
  BuildContext context,
  String title,
  BackupReport report,
) async {
  final buffer = StringBuffer(report.message);
  if (report.uploadedFiles > 0 || report.downloadedFiles > 0) {
    buffer.writeln();
    buffer.writeln();
    buffer.writeln(
      '上传 ${report.uploadedFiles} 个文件 · 下载 ${report.downloadedFiles} 个 · '
      '跳过 ${report.skippedFiles} 个',
    );
  }
  if (report.totalBytes > 0) {
    buffer.writeln('传输约 ${(report.totalBytes / 1024 / 1024).toStringAsFixed(2)} MB');
  }
  final duration = report.duration;
  if (duration != null) {
    buffer.writeln('耗时 ${duration.inSeconds} 秒');
  }
  if (report.conflicts.isNotEmpty) {
    buffer.writeln();
    buffer.writeln(
      '检测到 ${report.conflicts.length} 处冲突，已在本地生成冲突副本，'
      '未自动合并，请在备份中心选择以哪边为准。',
    );
  }
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(buffer.toString())),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

Future<void> runBackupWithFeedback(BuildContext context, WidgetRef ref) async {
  if (!await _ensureConfig(context, ref)) return;
  if (!context.mounted) return;
  final report = await _runBusy(
    context,
    '正在打包并上传（数据库 + 图片）…',
    ref.read(backupCenterProvider.notifier).runBackup(),
  );
  if (report != null && context.mounted) {
    await _showReport(context, report.success ? '备份完成' : '备份失败', report);
  }
}

Future<void> runSyncWithFeedback(BuildContext context, WidgetRef ref) async {
  if (!await _ensureConfig(context, ref)) return;
  if (!context.mounted) return;
  final report = await _runBusy(
    context,
    '正在双向同步…',
    ref.read(backupCenterProvider.notifier).runSync(),
  );
  if (report == null || !context.mounted) return;
  ref.invalidate(notesControllerProvider);
  ref.invalidate(itemsControllerProvider);
  await _showReport(context, report.success ? '同步完成' : '同步失败', report);
}

Future<void> exportArchiveWithFeedback(
  BuildContext context,
  WidgetRef ref,
) async {
  final service = ref.read(archiveServiceProvider);
  final db = ref.read(databaseProvider);
  final file = await _runBusy<File>(
    context,
    '正在打包 ZIP（数据库 + 图片）…',
    service.exportArchive(db: db),
  );
  if (file == null || !context.mounted) return;
  try {
    await db.backupRecordsDao.add(
      type: 'export',
      status: 'success',
      message: file.path,
      size: await file.length(),
    );
  } catch (_) {
    // ignore
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('导出完成'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('备份包已生成，可保存到本地或分享到微信 / QQ：'),
          const SizedBox(height: 8),
          SelectableText(
            file.path,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('完成'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await SharePlus.instance.share(
                ShareParams(
                  files: <XFile>[XFile(file.path)],
                  text: '物记碎念 · 本地备份包',
                ),
              );
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('分享失败：$error（可手动复制文件）')),
                );
              }
            }
          },
          icon: const Icon(Icons.share),
          label: const Text('分享'),
        ),
      ],
    ),
  );
}

Future<void> importArchiveWithFeedback(
  BuildContext context,
  WidgetRef ref,
) async {
  final picked = await FilePicker.pickFile(type: FileType.any);
  final path = picked?.path;
  if (path == null) return;

  final service = ref.read(archiveServiceProvider);
  final zipFile = File(path);
  final inspection = await service.inspect(zipFile);
  if (!context.mounted) return;
  if (!inspection.success) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('无法识别该文件'),
        content: Text(inspection.message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
    return;
  }

  final manifest = inspection.manifest!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('导入将覆盖本地数据'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('物品：${manifest.itemCount} 条'),
          Text('碎念：${manifest.noteCount} 条'),
          Text('图片：${manifest.imageCount} 张'),
          const SizedBox(height: 12),
          const Text(
            '导入前会把当前数据库留底到本地 restore_backup 目录，'
            '但仍建议先做一次导出。确定继续？',
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
          child: const Text('确认导入'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final outcome = await _runBusy(
    context,
    '正在导入并校验 md5…',
    () async {
      await ref.read(databaseProvider).close();
      final result = await service.importArchive(zipFile);
      await ref.read(databaseProvider.notifier).reload();
      return result;
    }(),
  );
  if (outcome == null || !context.mounted) return;
  ref.invalidate(notesControllerProvider);
  ref.invalidate(itemsControllerProvider);
  ref.invalidate(tagsProvider);
  ref.invalidate(backupCenterProvider);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(outcome.success ? '导入完成' : '导入失败'),
      content: Text(outcome.message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

Future<void> clearAllDataWithFeedback(
  BuildContext context,
  WidgetRef ref,
) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('清空全部数据？'),
      content: const Text('物品、碎念、标签与本地图片都会被删除，且无法撤销。'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('继续'),
        ),
      ],
    ),
  );
  if (first != true || !context.mounted) return;

  final second = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('最后确认'),
      content: const Text('确定要删除全部本地数据吗？建议先导出 ZIP 备份包。'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确认清空'),
        ),
      ],
    ),
  );
  if (second != true || !context.mounted) return;

  final result = await _runBusy<String>(
    context,
    '正在清空本地数据…',
    () async {
      final db = ref.read(databaseProvider);
      await db.wipeAll();
      final imagesDir = ref.read(appPathsProvider).imagesDir;
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
        await imagesDir.create(recursive: true);
      }
      return '已清空全部本地数据';
    }(),
  );
  ref.invalidate(notesControllerProvider);
  ref.invalidate(itemsControllerProvider);
  ref.invalidate(tagsProvider);
  ref.invalidate(storageStatsProvider);
  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result)));
  }
}