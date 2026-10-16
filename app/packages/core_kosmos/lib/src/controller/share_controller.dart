import 'package:share_plus/share_plus.dart';

abstract class ShareController {
  static Future<void> shareApplication(String message) async {
    await Share.share(message);
  }
}