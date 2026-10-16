import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wuji_suinian/data/services/webdav/webdav_client.dart';

const String _multistatus = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/dav/backup/</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype><d:collection/></d:resourcetype>
        <d:getlastmodified>Sat, 17 Oct 2026 01:00:00 GMT</d:getlastmodified>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/dav/backup/app.db</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:getcontentlength>2048</d:getcontentlength>
        <d:getlastmodified>Sat, 17 Oct 2026 01:05:00 GMT</d:getlastmodified>
        <d:getetag>"abc123"</d:getetag>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/dav/backup/%E4%B8%AD%E6%96%87.jpg</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:getcontentlength>10</d:getcontentlength>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';

void main() {
  group('multistatus 解析', () {
    test('解析目录、文件、大小、时间、etag、中文路径', () {
      final entries = WebdavClient.parseMultistatus(_multistatus);
      expect(entries.length, 3);

      expect(entries[0].isDirectory, isTrue);
      expect(entries[0].path, '/dav/backup/');

      expect(entries[1].isDirectory, isFalse);
      expect(entries[1].size, 2048);
      expect(entries[1].etag, 'abc123');
      expect(entries[1].modifiedMs, greaterThan(0));

      expect(entries[2].name, '中文.jpg');
    });

    test('空响应不抛异常', () {
      expect(WebdavClient.parseMultistatus(''), isEmpty);
    });
  });

  group('WebdavClient 请求', () {
    test('ping / list / put / get 使用正确的请求方法与请求头', () async {
      final requests = <http.Request>[];
      final store = <String, List<int>>{};

      final client = WebdavClient(
        baseUrl: 'https://dav.example.com/dav/backup',
        username: 'user',
        password: 'pass',
        client: MockClient((request) async {
          requests.add(request);
          final path = request.url.path;
          switch (request.method) {
            case 'PROPFIND':
              if (path.endsWith('/backup/app.db')) {
                return http.Response(_multistatus, 207);
              }
              return http.Response(_multistatus, 207);
            case 'PUT':
              store[path] = request.bodyBytes;
              return http.Response('', 201);
            case 'GET':
              final data = store[path];
              if (data == null) return http.Response('not found', 404);
              return http.Response.bytes(data, 200);
            case 'MKCOL':
              return http.Response('', 201);
            default:
              return http.Response('', 200);
          }
        }),
      );

      await client.ping();
      expect(requests.first.method, 'PROPFIND');
      expect(
        requests.first.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('user:pass'))}',
      );
      expect(requests.first.headers['Depth'], '0');

      final entries = await client.list('/');
      expect(entries, isNotEmpty);
      expect(requests.last.headers['Depth'], '1');

      await client.put('/db/app.db', <int>[1, 2, 3]);
      final downloaded = await client.get('/db/app.db');
      expect(downloaded, <int>[1, 2, 3]);
    });

    test('URI 编码中文文件名与空格', () {
      final client = WebdavClient(
        baseUrl: 'https://dav.example.com',
        username: 'u',
        password: 'p',
      );
      final uri = client.uriFor('images/我的 照片.jpg');
      expect(uri.toString(), contains('%E6%88%91'));
      expect(uri.toString(), contains('%20'));
    });

    test('404 视为文件不存在，不抛异常', () async {
      final client = WebdavClient(
        baseUrl: 'https://dav.example.com',
        username: 'u',
        password: 'p',
        client: MockClient((request) async => http.Response('', 404)),
      );
      expect(await client.exists('/db/app.db'), isFalse);
      expect(await client.list('/'), isEmpty);
    });

    test('MKCOL 返回 405（目录已存在）视为成功', () async {
      final client = WebdavClient(
        baseUrl: 'https://dav.example.com',
        username: 'u',
        password: 'p',
        client: MockClient((request) async => http.Response('', 405)),
      );
      await client.ensureDir('/backup/db');
    });

    test('上传失败抛出 WebdavException', () async {
      final client = WebdavClient(
        baseUrl: 'https://dav.example.com',
        username: 'u',
        password: 'p',
        client: MockClient((request) async => http.Response('', 507)),
      );
      expect(
        () => client.put('/db/app.db', <int>[1]),
        throwsA(isA<WebdavException>()),
      );
    });
  });
}