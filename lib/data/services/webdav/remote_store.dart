import 'dart:typed_data';

import '../../../domain/models/backup_models.dart';
import 'webdav_client.dart';

/// 远端存储抽象：便于用内存实现做单元测试，也便于日后接入其它协议。
abstract class RemoteStore {
  Future<void> ping();

  Future<void> ensureDir(String path);

  Future<List<RemoteEntry>> list(String path);

  Future<RemoteEntry?> stat(String path);

  Future<void> upload(String path, List<int> bytes, {String? contentType});

  Future<Uint8List?> download(String path);

  Future<void> delete(String path);

  Future<void> move(String from, String to);
}

/// WebDAV 实现。
class WebdavRemoteStore implements RemoteStore {
  WebdavRemoteStore(this.client);

  final WebdavClient client;

  @override
  Future<void> ping() => client.ping();

  @override
  Future<void> ensureDir(String path) => client.ensureDir(path);

  @override
  Future<List<RemoteEntry>> list(String path) => client.list(path);

  @override
  Future<RemoteEntry?> stat(String path) => client.stat(path);

  @override
  Future<void> upload(String path, List<int> bytes, {String? contentType}) =>
      client.put(path, bytes, contentType: contentType);

  @override
  Future<Uint8List?> download(String path) async {
    try {
      return await client.get(path);
    } on WebdavException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> delete(String path) => client.delete(path);

  @override
  Future<void> move(String from, String to) => client.move(from, to);

  Future<void> close() => client.close();
}