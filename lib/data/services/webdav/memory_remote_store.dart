import 'dart:typed_data';

import '../../../domain/models/backup_models.dart';
import 'remote_store.dart';

class _MemoryEntry {
  _MemoryEntry(List<int> bytes, this.modified)
      : bytes = Uint8List.fromList(bytes);

  Uint8List bytes;
  DateTime modified;
}

/// 内存远端存储：单元测试 / 离线演练用。
///
/// 支持目录结构（PROPFIND Depth:1 语义），以便测试快照目录列表等场景。
class MemoryRemoteStore implements RemoteStore {
  MemoryRemoteStore({this.latency = Duration.zero});

  final Duration latency;
  final Map<String, _MemoryEntry> _files = <String, _MemoryEntry>{};
  final Set<String> _dirs = <String>{};
  bool failNextUpload = false;

  String _key(String path) => path.replaceAll('\\', '/');

  String _trim(String path) {
    var key = _key(path);
    while (key.endsWith('/')) {
      key = key.substring(0, key.length - 1);
    }
    while (key.startsWith('/')) {
      key = key.substring(1);
    }
    return key;
  }

  /// 注册路径的所有父级目录（不包含自身）
  void _registerParentDirs(String key) {
    var current = key;
    while (true) {
      final index = current.lastIndexOf('/');
      if (index <= 0) break;
      current = current.substring(0, index);
      _dirs.add(current);
    }
  }

  @override
  Future<void> ping() async => _maybeDelay();

  @override
  Future<void> ensureDir(String path) async {
    _maybeDelay();
    final key = _trim(path);
    if (key.isEmpty) return;
    _registerParentDirs(key);
    _dirs.add(key);
  }

  @override
  Future<List<RemoteEntry>> list(String path) async {
    _maybeDelay();
    final base = _trim(path);
    final prefix = base.isEmpty ? '' : '$base/';
    final entries = <RemoteEntry>[];

    for (final dir in _dirs) {
      if (!dir.startsWith(prefix)) continue;
      final remainder = dir.substring(prefix.length);
      if (remainder.isEmpty || remainder.contains('/')) continue;
      entries.add(RemoteEntry(path: dir, isDirectory: true));
    }

    for (final entry in _files.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final remainder = entry.key.substring(prefix.length);
      if (remainder.isEmpty || remainder.contains('/')) continue;
      entries.add(
        RemoteEntry(
          path: entry.key,
          isDirectory: false,
          size: entry.value.bytes.length,
          lastModified: entry.value.modified,
        ),
      );
    }
    return entries;
  }

  @override
  Future<RemoteEntry?> stat(String path) async {
    _maybeDelay();
    final key = _trim(path);
    final entry = _files[key];
    if (entry != null) {
      return RemoteEntry(
        path: key,
        isDirectory: false,
        size: entry.bytes.length,
        lastModified: entry.modified,
      );
    }
    if (_dirs.contains(key)) {
      return RemoteEntry(path: key, isDirectory: true);
    }
    return null;
  }

  @override
  Future<void> upload(String path, List<int> bytes, {String? contentType}) async {
    _maybeDelay();
    if (failNextUpload) {
      failNextUpload = false;
      throw StateError('模拟上传中断');
    }
    final key = _trim(path);
    _registerParentDirs(key);
    _files[key] = _MemoryEntry(bytes, DateTime.now());
  }

  @override
  Future<Uint8List?> download(String path) async {
    _maybeDelay();
    final entry = _files[_trim(path)];
    return entry == null ? null : Uint8List.fromList(entry.bytes);
  }

  @override
  Future<void> delete(String path) async {
    _maybeDelay();
    final key = _trim(path);
    _files.removeWhere((k, value) => k == key || k.startsWith('$key/'));
    _dirs.removeWhere((k) => k == key || k.startsWith('$key/'));
  }

  @override
  Future<void> move(String from, String to) async {
    _maybeDelay();
    final source = _trim(from);
    final target = _trim(to);
    final entry = _files.remove(source);
    if (entry != null) {
      _files[target] = entry;
    }
    final movedDirs = _dirs
        .where((dir) => dir == source || dir.startsWith('$source/'))
        .toList();
    for (final dir in movedDirs) {
      _dirs.remove(dir);
      _dirs.add(target + dir.substring(source.length));
    }
  }

  /// 测试辅助：直接读取文件内容
  Uint8List? raw(String path) {
    final entry = _files[_trim(path)];
    return entry == null ? null : Uint8List.fromList(entry.bytes);
  }

  /// 测试辅助：写入并允许指定时间戳
  void seed(String path, List<int> bytes, {DateTime? modified}) {
    final key = _trim(path);
    _registerParentDirs(key);
    _files[key] = _MemoryEntry(bytes, modified ?? DateTime.now());
  }

  int get fileCount => _files.length;

  Set<String> get dirs => Set<String>.of(_dirs);

  void _maybeDelay() {
    if (latency > Duration.zero) {
      // 测试中可通过 latency 模拟网络耗时
    }
  }
}
