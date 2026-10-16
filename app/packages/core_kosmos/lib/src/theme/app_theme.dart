import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';

/// {@category Config}
/// {@category Theme}
///
/// Permet de stocker les thèmes Custom de l'application.
/// Vous pouvez aussi retrouver et configurer le [ThemeData] de l'application.
///
class AppTheme {
  static Future<void> initDarkMode() async {
    darkMode = await LocalConfigController.getData<bool>("isDarkMode");
  }

  static bool? darkMode;

  Map<String, dynamic> theme = {};

  void addTheme<T>(String themeName, T newTheme, {T? darkTheme}) {
    if (theme[themeName] != null) {
      printInDebug(
          "[Warning] theme $themeName already exist and will be override.");
    }
    theme[themeName] = newTheme;

    if (darkTheme != null) {
      theme["$themeName-dark"] = darkTheme;
    }
  }

  T? fetchTheme<T>(String themeName) => theme[themeName];
  T? fetchDarkTheme<T>(String themeName) =>
      theme.containsKey("$themeName-dark") ? theme["$themeName-dark"] : null;

  final ThemeData? themeData;
  final ThemeData? themeDataDark;

  AppTheme({this.themeData, this.themeDataDark});

  static bool isDark() => GetIt.instance.isRegistered<AppTheme>()
      ? GetIt.instance<AppTheme>().themeData?.brightness == Brightness.dark
      : false;

  static Brightness getBrightness() => GetIt.instance.isRegistered<AppTheme>()
      ? GetIt.instance<AppTheme>().themeData?.brightness ?? Brightness.light
      : Brightness.light;

  void dumpLog() {
    printWarning("AppTheme: ${theme.toString()}");
    printInfo("----------------------------------------");
    printInfo("Theme:\n");
    for (final i in theme.keys) {
      printInfo("  $i: ${theme[i]} && ${theme[i].runtimeType}");
    }
    printInfo("----------------------------------------");
  }

  static Future<bool> isDarkMode() async {
    return await LocalConfigController.getData<bool>("isDarkMode") ?? false;
  }

  static Future<void> setDarkMode(bool isDarkMode) async {
    await LocalConfigController.setData("isDarkMode", boolValue: isDarkMode);
  }
}

T loadThemeData<T>(T? theme, String themeName, T Function() constructor,
    {bool isDark = false}) {
  return theme ??
      (GetIt.instance.isRegistered<AppTheme>()
          ? GetIt.instance<AppTheme>()
              .fetchTheme<T>(isDark ? "$themeName-dark" : themeName)
          : null) ??
      constructor();
}

final isDarkModeProvider = ChangeNotifierProvider.autoDispose<DarkModeProvider>(
    (ref) => DarkModeProvider());

class DarkModeProvider extends ChangeNotifier {
  late bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  DarkModeProvider() {
    _isDarkMode = AppTheme.darkMode ?? false;
  }

  void setIsDarkMode(bool value) async {
    _isDarkMode = value;
    AppTheme.darkMode = value;
    notifyListeners();
    await LocalConfigController.setData("isDarkMode", boolValue: value);
  }
}

// Provider to fetch the dark mode value asynchronously

// StateProvider that initializes with false and updates when the async value is available
