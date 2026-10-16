import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../../domain/models/backup_models.dart';

/// WebDAV 请求异常。
class WebdavException implements Exception {
  const WebdavException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      statusCode == null ? message : '[$statusCode] $message';
}

/// 轻量 WebDAV 客户端（PROPFIND / MKCOL / PUT / GET / DELETE / MOVE）。
///
/// 说明：需求文档推荐使用第三方库，这里自建最小实现的原因：
/// 1. 需要完全控制请求头（坚果云 / 阿里云盘 WebDAV 对 header 有额外要求）；
/// 2. 备份流程需要 md5 校验 + 临时文件 + 原子替换，第三方库封装不够；
/// 3. 便于单元测试（可注入 http.Client 与 mock 响应）。
class WebdavClient {
  WebdavClient({
    required String baseUrl,
    required this.username,
    required this.password,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  })  : baseUrl = _normalizeBase(baseUrl),
        _client = client ?? http.Client();

  final String baseUrl;
  final String username;
  final String password;
  final Duration timeout;
  final http.Client _client;

  static String _normalizeBase(String url) {
    var value = url.trim();
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      'User-Agent': 'wuji-suishuinian/1.0 (offline-notes)',
      'Accept': '*/*',
      ...?extra,
    };
    return headers;
  }

  /// 把远端路径拼成完整 URL；路径按 `/` 分段做百分号编码。
  Uri uriFor(String path) {
    final segments = path
        .split('/')
        .where((e) => e.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    return Uri.parse('$baseUrl/$segments');
  }

  Future<void> close() async => _client.close();

  Future<void> ping() async {
    final response = await _send('PROPFIND', '/', depth: '0');
    if (!_isSuccess(response.statusCode)) {
      throw WebdavException(
        '连接失败，请检查地址 / 账号 / 密码',
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<RemoteEntry>> list(String path) async {
    final response = await _send('PROPFIND', path, depth: '1');
    if (response.statusCode == 404) return <RemoteEntry>[];
    if (!_isSuccess(response.statusCode)) {
      throw WebdavException(
        '读取目录失败: $path',
        statusCode: response.statusCode,
      );
    }
    return parseMultistatus(utf8.decode(response.bodyBytes, allowMalformed: true));
  }

  Future<RemoteEntry?> stat(String path) async {
    final response = await _send('PROPFIND', path, depth: '0');
    if (response.statusCode == 404) return null;
    if (!_isSuccess(response.statusCode)) {
      throw WebdavException('读取文件信息失败: $path', statusCode: response.statusCode);
    }
    final entries = parseMultistatus(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    );
    return entries.isEmpty ? null : entries.first;
  }

  Future<bool> exists(String path) async => (await stat(path)) != null;

  /// 逐级创建目录（已存在时服务端返回 405，视为成功）。
  Future<void> ensureDir(String path) async {
    final segments = path.split('/').where((e) => e.isNotEmpty).toList();
    var current = '';
    for (final segment in segments) {
      current = '$current/$segment';
      final response = await _send('MKCOL', current);
      if (response.statusCode == 405 || response.statusCode == 301) {
        continue;
      }
      if (!_isSuccess(response.statusCode)) {
        throw WebdavException('创建目录失败: $current', statusCode: response.statusCode);
      }
    }
  }

  Future<void> put(String path, List<int> bytes, {String? contentType}) async {
    final response = await _send(
      'PUT',
      path,
      body: bytes,
      extraHeaders: <String, String>{
        'Content-Type': contentType ?? 'application/octet-stream',
        'Content-Length': '${bytes.length}',
      },
    );
    if (!_isSuccess(response.statusCode)) {
      throw WebdavException('上传失败: $path', statusCode: response.statusCode);
    }
  }

  Future<Uint8List> get(String path) async {
    final response = await _send('GET', path);
    if (response.statusCode == 404) {
      throw WebdavException('远端文件不存在: $path', statusCode: 404);
    }
    if (!_isSuccess(response.statusCode)) {
      throw WebdavException('下载失败: $path', statusCode: response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<void> delete(String path) async {
    final response = await _send('DELETE', path);
    if (response.statusCode == 404) return;
    if (!_isSuccess(response.statusCode)) {
      throw WebdavException('删除失败: $path', statusCode: response.statusCode);
    }
  }

  Future<void> move(String from, String to, {bool overwrite = true}) async {
    final response = await _send(
      'MOVE',
      from,
      extraHeaders: <String, String>{
        'Destination': uriFor(to).toString(),
        'Overwrite': overwrite ? 'T' : 'F',
      },
    );
    if (!_isSuccess(response.statusCode)) {
      throw WebdavException('重命名失败: $from → $to', statusCode: response.statusCode);
    }
  }

  Future<http.Response> _send(
    String method,
    String path, {
    String? depth,
    List<int>? body,
    Map<String, String>? extraHeaders,
  }) async {
    final request = http.Request(method, uriFor(path));
    request.headers.addAll(_headers(extra: extraHeaders));
    if (depth != null) {
      request.headers['Depth'] = depth;
    }
    if (method == 'PROPFIND') {
      request.headers.putIfAbsent('Content-Type', () => 'application/xml; charset=utf-8');
    }
    if (body != null) {
      request.bodyBytes = body is Uint8List ? body : Uint8List.fromList(body);
    }
    final streamed = await _client.send(request).timeout(timeout);
    return http.Response.fromStream(streamed);
  }

  static bool _isSuccess(int code) => code >= 200 && code < 300;

  /// 解析 207 Multi-Status 响应。
  ///
  /// 使用了本地名匹配，兼容不同服务端的前缀（d: / D: / 无前缀）。
  static List<RemoteEntry> parseMultistatus(String xmlText) {
    final entries = <RemoteEntry>[];
    if (xmlText.trim().isEmpty) return entries;
    final document = XmlDocument.parse(xmlText);
    for (final response in document.findAllElements('response', namespaceUri: '*')) {
      final hrefElement =
          response.findAllElements('href', namespaceUri: '*').firstOrNull;
      final href = hrefElement?.innerText.trim();
      if (href == null || href.isEmpty) continue;

      var isDirectory = false;
      var size = 0;
      int? modifiedMs;
      String? etag;
      String? contentMd5;

      for (final propstat
          in response.findAllElements('propstat', namespaceUri: '*')) {
        final statusText = propstat
                .findAllElements('status', namespaceUri: '*')
                .firstOrNull
                ?.innerText
                .trim() ??
            '';
        if (statusText.isNotEmpty && !statusText.contains(' 200 ')) {
          continue;
        }
        final prop = propstat.findAllElements('prop', namespaceUri: '*').firstOrNull;
        if (prop == null) continue;

        final resourceType =
            prop.findAllElements('resourcetype', namespaceUri: '*').firstOrNull;
        if (resourceType != null &&
            resourceType
                .findAllElements('collection', namespaceUri: '*')
                .isNotEmpty) {
          isDirectory = true;
        }
        final lengthText = prop
            .findAllElements('getcontentlength', namespaceUri: '*')
            .firstOrNull
            ?.innerText
            .trim();
        size = int.tryParse(lengthText ?? '') ?? size;
        final modifiedText = prop
            .findAllElements('getlastmodified', namespaceUri: '*')
            .firstOrNull
            ?.innerText
            .trim();
        modifiedMs = _parseHttpDateMillis(modifiedText) ?? modifiedMs;
        final etagText = prop
            .findAllElements('getetag', namespaceUri: '*')
            .firstOrNull
            ?.innerText
            .trim();
        if (etagText != null && etagText.isNotEmpty) {
          etag = etagText.replaceAll('"', '');
        }
        final md5Text = prop
            .findAllElements('getcontentmd5', namespaceUri: '*')
            .firstOrNull
            ?.innerText
            .trim();
        if (md5Text != null && md5Text.isNotEmpty) contentMd5 = md5Text;
      }

      entries.add(
        RemoteEntry(
          path: Uri.decodeFull(href),
          isDirectory: isDirectory || href.endsWith('/'),
          size: size,
          lastModified:
              modifiedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(modifiedMs),
          etag: etag,
          contentMd5: contentMd5,
        ),
      );
    }
    return entries;
  }

  static int? _parseHttpDateMillis(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return HttpDate.parse(value).millisecondsSinceEpoch;
    } catch (_) {
      return null;
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final value in this) {
      return value;
    }
    return null;
  }
}