import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// md5 校验工具：备份上传 / 恢复前校验，防止坏文件覆盖唯一备份。
class HashUtils {
  HashUtils._();

  static String md5OfBytes(List<int> bytes) => md5.convert(bytes).toString();

  static String md5OfString(String text) => md5OfBytes(utf8Encode(text));

  static Future<String> md5OfFile(File file) async {
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  static Uint8List utf8Encode(String text) =>
      Uint8List.fromList(utf8.encode(text));
}