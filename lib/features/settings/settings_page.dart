import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import 'about_page.dart';
import 'backup_center_page.dart';
import 'backup_actions.dart';
import 'backup_controller.dart';
import 'storage_page.dart';
import 'tag_manager_page.dart';
import 'webdav_config_page.dart';

/// Tab3：设置 & 备份中心
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final configs = ref.watch(webdavConfigsProvider);
    final logs = ref.watch(backupCenterProvider).logs;
    final lastBackup = logs.isEmpty ? null : logs.first;
    final activeId = settings.activeWebdavConfigId;
    var activeName = '未配置';
    for (final config in configs) {
      if (config.id == activeId) activeName = config.name;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置与备份')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          _SectionHeader(title: '外观'),
          ListTile(
            title: const Text('主题'),
            subtitle: const Text('深色 / 浅色 / 跟随系统'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox.shrink(),
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
                }
              },
              items: const <DropdownMenuItem<ThemeMode>>[
                DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('深色')),
              ],
            ),
          ),
          // 配色预设与明暗模式正交：樱花粉 / 天空蓝 / 毛玻璃等
          ListTile(
            title: const Text('主题风格'),
            subtitle: const Text('樱花粉 / 天空蓝 / 毛玻璃…'),
            trailing: DropdownButton<AppThemePreset>(
              value: settings.themePreset,
              underline: const SizedBox.shrink(),
              onChanged: (preset) {
                if (preset != null) {
                  ref.read(settingsProvider.notifier).setThemePreset(preset);
                }
              },
              items: <DropdownMenuItem<AppThemePreset>>[
                for (final preset in AppThemePreset.values)
                  DropdownMenuItem(value: preset, child: Text(preset.label)),
              ],
            ),
          ),
          ListTile(
            title: const Text('字体大小'),
            subtitle: Slider(
              value: settings.fontScale,
              min: 0.85,
              max: 1.4,
              divisions: 11,
              label: '${(settings.fontScale * 100).round()}%',
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).setFontScale(value),
            ),
            trailing: Text('${(settings.fontScale * 100).round()}%'),
          ),
          const Divider(),
          _SectionHeader(title: '备份与同步（WebDAV）'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('WebDAV 配置'),
            subtitle: Text(
              activeName == '未配置'
                  ? '未配置（数据仅保存在本机）'
                  : '当前使用：$activeName',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const WebdavConfigPage(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('备份中心'),
            subtitle: Text(
              lastBackup == null
                  ? '还没有备份记录'
                  : '上次操作：${lastBackup.type} ${lastBackup.status} · '
                      '${TimeUtils.formatDateTime(TimeUtils.toDateTime(lastBackup.createAt))}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const BackupCenterPage(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('立即备份到 WebDAV'),
            subtitle: const Text('上传数据库 + 图片，并生成 md5 校验与快照'),
            onTap: () => runBackupWithFeedback(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('双向同步'),
            subtitle: const Text('基于时间戳与上次同步记录，冲突不自动合并'),
            onTap: () => runSyncWithFeedback(context, ref),
          ),
          ListTile(
            title: const Text('快照保留份数'),
            subtitle: const Text('远端最多保留 N 份历史备份，防止坏文件覆盖唯一备份'),
            trailing: DropdownButton<int>(
              value: settings.snapshotKeep,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setSnapshotKeep(value);
                }
              },
              items: const <DropdownMenuItem<int>>[
                DropdownMenuItem(value: 3, child: Text('3 份')),
                DropdownMenuItem(value: 5, child: Text('5 份')),
                DropdownMenuItem(value: 10, child: Text('10 份')),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('App 切后台时自动备份'),
            subtitle: const Text('iOS 后台限制较多，触发时机不稳定'),
            value: settings.autoBackupOnBackground,
            onChanged: (value) => ref
                .read(settingsProvider.notifier)
                .setAutoBackupOnBackground(value),
          ),
          SwitchListTile(
            title: const Text('每日固定时间备份'),
            subtitle: Text(
              '当前时间：'
              '${settings.dailyBackupHour.toString().padLeft(2, '0')}:'
              '${settings.dailyBackupMinute.toString().padLeft(2, '0')}',
            ),
            value: settings.dailyBackupEnabled,
            onChanged: (value) => ref
                .read(settingsProvider.notifier)
                .setDailyBackup(enabled: value),
          ),
          if (settings.dailyBackupEnabled)
            ListTile(
              title: const Text('设置备份时间'),
              trailing: const Icon(Icons.schedule),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.dailyBackupHour,
                    minute: settings.dailyBackupMinute,
                  ),
                );
                if (picked != null) {
                  await ref.read(settingsProvider.notifier).setDailyBackup(
                        enabled: true,
                        hour: picked.hour,
                        minute: picked.minute,
                      );
                }
              },
            ),
          const Divider(),
          _SectionHeader(title: '数据导出 / 导入（兜底方案）'),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('导出 ZIP 备份包'),
            subtitle: const Text('打包数据库 + 全部图片，可保存或分享到微信 / QQ'),
            onTap: () => exportArchiveWithFeedback(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('从 ZIP 备份包导入'),
            subtitle: const Text('覆盖本地数据（含 md5 校验与二次确认）'),
            onTap: () => importArchiveWithFeedback(context, ref),
          ),
          const Divider(),
          _SectionHeader(title: '存储与图片'),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('存储统计与清理'),
            subtitle: const Text('查看数据库 / 图片占用，清理无引用图片'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const StoragePage(),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('拍照自动压缩'),
            subtitle: Text('当前质量 ${settings.compressQuality}（推荐开启，否则同步很慢）'),
            value: settings.compressImage,
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setCompress(enabled: value),
          ),
          if (settings.compressImage)
            ListTile(
              title: const Text('压缩质量'),
              subtitle: Slider(
                value: settings.compressQuality.toDouble(),
                min: 40,
                max: 95,
                divisions: 11,
                label: '${settings.compressQuality}',
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setCompress(
                      enabled: true,
                      quality: value.round(),
                    ),
              ),
            ),
          SwitchListTile(
            title: const Text('删除物品时同时删除原图'),
            subtitle: const Text('默认勾选状态，仍会在删除弹窗中再次确认'),
            value: settings.deleteImageWithItem,
            onChanged: (value) => ref
                .read(settingsProvider.notifier)
                .setDeleteImageWithItem(value),
          ),
          const Divider(),
          _SectionHeader(title: '提醒与标签'),
          SwitchListTile(
            title: const Text('质保到期提醒'),
            subtitle: Text('质保到期前 ${AppConstants.warrantyReminderDays} 天内提醒'),
            value: settings.warrantyReminderEnabled,
            onChanged: (value) async {
              await ref.read(settingsProvider.notifier).setWarrantyReminder(value);
              try {
                await ref.read(warrantyReminderServiceProvider).reschedule();
              } catch (_) {
                // ignore
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('标签管理'),
            subtitle: const Text('物品与碎念共用的标签池'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const TagManagerPage(),
              ),
            ),
          ),
          const Divider(),
          _SectionHeader(title: '数据安全'),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('一键清空全部数据'),
            subtitle: const Text('物品、碎念、标签、图片全部删除，需二次强确认'),
            onTap: () => clearAllDataWithFeedback(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => const AboutPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}