import 'dart:io';
import 'package:core_kosmos/core_kosmos.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

abstract class HttpController {
  static Future<String?> downloadFileLocaly(String url, String path, String name) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      final file = await File('$path/$name').create(recursive: true);
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      printExcept(e);
      return null;
    }
  }
}
