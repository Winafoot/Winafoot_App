import 'package:core_kosmos/core_kosmos.dart';
import 'package:device_info_plus/device_info_plus.dart';

abstract class OsController {
  static Future<bool> isAndroid13OrHigher() async {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    try {
      return double.parse(androidInfo.version.release) >= 13;
    } catch (_) {
      printExcept("Android version is ${androidInfo.version.release} and cannot be parsed");
      return false;
    }
  }
}
