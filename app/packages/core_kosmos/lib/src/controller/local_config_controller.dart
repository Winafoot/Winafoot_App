import 'package:shared_preferences/shared_preferences.dart';

/// {@category Controller}
///
/// Permet d'intéragir avec les données locales. (En utilisant
/// le package [shared_preferences](https://pub.dev/packages/shared_preferences))
abstract class LocalConfigController {
  static Future<T?> getData<T>(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final dynamic data = prefs.get(key);

    return data is T ? data : null;
  }

  static Future<void> setData(
    String key, {
    bool? boolValue,
    double? doubleValue,
    int? intValue,
    String? stringValue,
    List<String>? stringListValue,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (boolValue != null) {
      await prefs.setBool(key, boolValue);
    } else if (doubleValue != null) {
      await prefs.setDouble(key, doubleValue);
    } else if (intValue != null) {
      await prefs.setInt(key, intValue);
    } else if (stringValue != null) {
      await prefs.setString(key, stringValue);
    } else if (stringListValue != null) {
      await prefs.setStringList(key, stringListValue);
    }
  }

  static Future<void> clearData(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
