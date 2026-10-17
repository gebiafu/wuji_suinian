import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';

/// 关于页：版本 / 作者 / 仓库信息与隐私说明（离线优先，不强制联网）
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String appVersion = '0.5.0';
  static const String author = 'gebiafu';
  static const String repoUrl = 'https://github.com/gebiafu/wuji_suinian';

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
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
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
                  Text('作者与仓库', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _InfoRow(label: '作者', value: author),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Text('仓库：', style: theme.textTheme.bodyMedium),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => _copyLink(context),
                          child: Text(
                            'github.com/gebiafu/wuji_suinian',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '源码开放，欢迎 Star / Issue；点击上方链接可复制仓库地址。',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
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
                  Text('说明', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _LinkRow(
                    label: '隐私说明',
                    onTap: () => _showInfoDialog(context, '隐私说明', _privacyText),
                  ),
                  const Divider(height: 16),
                  _LinkRow(
                    label: '使用边界',
                    onTap: () => _showInfoDialog(context, '使用边界', _boundaryText),
                  ),
                  const Divider(height: 16),
                  _LinkRow(
                    label: '版本检测',
                    onTap: () => _showInfoDialog(
                      context,
                      '版本检测',
                      '仅显示本地版本号，不联网检查更新。\n\n当前本地版本：$appVersion',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const String _privacyText = '· 无账号体系、无埋点、无自建服务器；\n'
      '· 所有数据保存在本机 SQLite 与 App 私有目录；\n'
      '· 仅当你主动触发备份 / 同步时，数据才会通过 WebDAV 上传到你自己配置的空间；\n'
      '· WebDAV 密码使用系统安全存储加密保存；\n'
      '· 不申请通讯录 / 定位 / 麦克风等无关权限。';

  static const String _boundaryText = '· WebDAV 同步不支持多人实时协同，仅适合备份与单设备轮换'
      '（手机 A 备份 → 手机 B 恢复）；\n'
      '· iOS 后台自动备份触发不稳定，建议手动备份或使用导出 ZIP；\n'
      '· 数据库本身未加密（SQLCipher 可作为后续增强项）；\n'
      '· 大量图片场景建议开启拍照自动压缩，否则同步耗时明显增加。';

  void _copyLink(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: repoUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('仓库地址已复制到剪贴板')),
    );
  }

  Future<void> _showInfoDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// 超链接样式行（需求 5：隐私说明 / 使用边界等改为链接，点击弹窗展示全文）
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
