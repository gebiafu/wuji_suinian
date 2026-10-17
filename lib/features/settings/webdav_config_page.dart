import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/services/webdav/webdav_client.dart';
import '../../domain/models/backup_models.dart';

/// WebDAV 配置管理：支持多套配置切换
class WebdavConfigPage extends ConsumerWidget {
  const WebdavConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(webdavConfigsProvider);
    final activeId = ref.watch(settingsProvider).activeWebdavConfigId;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV 配置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '数据只在你自己的 WebDAV 空间中转，不上传第三方云。'
                '密码使用 flutter_secure_storage 加密保存，不写入数据库或普通配置文件。',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (configs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: <Widget>[
                  Icon(Icons.cloud_off, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('还没有配置，点击右下角新增'),
                ],
              ),
            ),
          for (final config in configs)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  config.id == activeId
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: config.id == activeId ? theme.colorScheme.primary : null,
                ),
                title: Text(config.name),
                subtitle: Text(
                  '${config.serverUrl}\n远端目录：/${config.remoteDir} · 账号：${config.username}',
                ),
                isThreeLine: true,
                onTap: () => ref
                    .read(webdavConfigsProvider.notifier)
                    .setActive(config.id),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              WebdavConfigEditPage(initial: config),
                        ),
                      );
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('删除配置「${config.name}」？'),
                          content: const Text('仅删除本机配置，远端备份文件不会被删除。'),
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
                      if (confirmed == true) {
                        await ref
                            .read(webdavConfigsProvider.notifier)
                            .remove(config.id);
                      }
                    }
                  },
                  itemBuilder: (context) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'edit', child: Text('编辑')),
                    PopupMenuItem<String>(value: 'delete', child: Text('删除')),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const WebdavConfigEditPage(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新增配置'),
      ),
    );
  }
}

class WebdavConfigEditPage extends ConsumerStatefulWidget {
  const WebdavConfigEditPage({super.key, this.initial});

  final WebdavConfig? initial;

  @override
  ConsumerState<WebdavConfigEditPage> createState() =>
      _WebdavConfigEditPageState();
}

class _WebdavConfigEditPageState extends ConsumerState<WebdavConfigEditPage> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '坚果云');
  late final TextEditingController _url =
      TextEditingController(text: widget.initial?.serverUrl ?? '');
  late final TextEditingController _username =
      TextEditingController(text: widget.initial?.username ?? '');
  late final TextEditingController _password = TextEditingController();
  late final TextEditingController _remoteDir =
      TextEditingController(text: widget.initial?.remoteDir ?? 'backup');
  bool _obscure = true;
  bool _testing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = widget.initial?.id;
    if (id != null && id.isNotEmpty) {
      // 已保存的密码从加密存储中回填（仅用于测试连接，不会明文落库）
      ref.read(secureStoreProvider).read(_passwordKey(id)).then((value) {
        if (value != null && mounted) {
          _password.text = value;
        }
      });
    }
  }

  String _passwordKey(String id) => 'webdav_password_$id';

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _username.dispose();
    _password.dispose();
    _remoteDir.dispose();
    super.dispose();
  }

  WebdavConfig _build() => WebdavConfig(
        id: widget.initial?.id ?? '',
        name: _name.text.trim().isEmpty ? 'WebDAV' : _name.text.trim(),
        serverUrl: _url.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
        remoteDir: _remoteDir.text.trim().isEmpty ? 'backup' : _remoteDir.text.trim(),
      );

  Future<void> _test() async {
    final config = _build();
    if (config.serverUrl.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先填写服务器地址')));
      return;
    }
    setState(() => _testing = true);
    try {
      final client = WebdavClient(
        baseUrl: joinRemoteUrl(config.serverUrl, config.remoteDir),
        username: config.username,
        password: config.password,
      );
      await client.ensureDir('');
      await client.ping();
      await client.close();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('连接成功，账号密码可用')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('连接失败：${describeNetworkError(error)}')));
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final config = _build();
    if (config.serverUrl.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('服务器地址不能为空')));
      return;
    }
    setState(() => _saving = true);
    try {
      final saved =
          await ref.read(webdavConfigsProvider.notifier).save(config);
      await ref.read(webdavConfigsProvider.notifier).setActive(saved.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? '新增 WebDAV 配置' : '编辑 WebDAV 配置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: '配置名称',
              hintText: '例如：坚果云 / 阿里云盘 WebDAV',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: '服务器地址 *',
              hintText: 'https://dav.jianguoyun.com/dav/',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remoteDir,
            decoration: const InputDecoration(
              labelText: '远端备份目录',
              hintText: 'backup',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _username,
            decoration: const InputDecoration(labelText: '账号'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: '密码 / 应用密码',
              helperText: '加密保存在系统安全存储中',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('测试连接'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '远端会自动创建固定结构：<目录>/db/、<目录>/images/、<目录>/md5/、'
            '<目录>/snapshots/、<目录>/state/。\n'
            '注意：WebDAV 不提供实时协同，仅适合备份与单设备轮换同步（手机 A 备份 → 手机 B 恢复）。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}