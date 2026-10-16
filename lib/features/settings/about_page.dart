import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// 关于页：版本信息与隐私说明（离线优先，不强制联网）
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String appVersion = '0.4.0';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Column(
            children: <Widget>[
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  '物',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(AppConstants.appName, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '版本 $appVersion（本地版，不强制联网）',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('隐私说明', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(
                    '· 无账号体系、无埋点、无自建服务器；\n'
                    '· 所有数据保存在本机 SQLite 与 App 私有目录；\n'
                    '· 仅当你主动触发备份 / 同步时，数据才会通过 WebDAV 上传到你自己配置的空间；\n'
                    '· WebDAV 密码使用系统安全存储加密保存。',
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
                  Text('使用边界', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(
                    '· WebDAV 同步不支持多人实时协同，仅适合备份与单设备轮换（手机 A 备份 → 手机 B 恢复）；\n'
                    '· iOS 后台自动备份触发不稳定，建议手动备份或使用导出 ZIP；\n'
                    '· 数据库本身未加密（SQLCipher 可作为后续增强项）。',
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
                  Text('版本检测', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text('仅显示本地版本号，不联网检查更新。'),
                  const SizedBox(height: 4),
                  Text(
                    '当前本地版本：$appVersion',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}