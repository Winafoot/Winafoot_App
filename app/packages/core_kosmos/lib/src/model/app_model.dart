import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';

/// {@category Application}
/// {@category Config}
/// {@category Model}
/// {@category Core}
///
/// Objet principal confenant toutes les configurations de l'application.
///
class AppModel<T extends Object?> {
  final String appTitle;

  final UserConfig<T> userConfig;
  final ThemeModeType forceThemeMode;
  final LocalizationConfig localization;
  final ResponsiveConfig responsive;
  final DependenciesConfig dependencies;
  final FirebaseConfig firebase;
  final Future<void> Function()? excuteAfterFirebaseInitialized;

  const AppModel({
    required this.appTitle,
    required this.userConfig,
    this.localization = const LocalizationConfig(),
    this.responsive = const ResponsiveConfig(),
    this.dependencies = const DependenciesConfig(packages: {}),
    this.firebase = const FirebaseConfig(),
    this.forceThemeMode = ThemeModeType.system,
    this.excuteAfterFirebaseInitialized,
  });

  DependenciesConfig getDependencies() => dependencies;

  S? getDependenciesFromName<S>(String name) {
    if (dependencies.packages.containsKey(name)) {
      return dependencies.packages[name]! as S;
    }
    return null;
  }

  void addDependencies({required String name, required PackageConfig config}) {
    if (dependencies.packages.containsKey(name) &&
        dependencies.packages[name] != null) {
      printInfo("Dependencies already contains $name");
      return;
    }
    dependencies.packages[name] = config;
  }

  void removeDependecies({required String name}) {
    dependencies.packages.remove(name);
  }
}

class ResponsiveConfig {
  /// Taile du design de l'application.
  /// @Default: const Size(375, 812)
  final Size size;

  /// Taille du design quand l'écran est en portrait. `null` : [size] reste
  /// utilisée quelle que soit l'orientation.
  final Size? portraitSize;

  /// Liste des breakpoints de l'application (séparation responsive).
  final List<ResponsiveBreakpoint> breakpoints;

  final double? maxWidth;
  final double minWidth;

  const ResponsiveConfig({
    this.size = const Size(375, 812),
    this.portraitSize,
    this.breakpoints = const [
      ResponsiveBreakpoint.tag(800, name: PHONE),
      ResponsiveBreakpoint.tag(1100, name: TABLET),
      ResponsiveBreakpoint.tag(double.infinity, name: DESKTOP),
    ],
    this.maxWidth,
    this.minWidth = 450,
  });
}

class LocalizationConfig {
  /// Liste des langages supportés par l'application.
  /// /!\ Les langues doivent avoir leur fichier de traduction dans le dossier '''assets/translations/''' de l'application.
  /// @Default: const [Locale("fr", "FR")]
  final List<Locale> supportedLocales;

  /// Langue par défaut de l'application.
  /// @Default: const [Locale("fr", "FR")]
  final Locale defaultLocale;

  /// Path des fichiers de traduction.
  /// @Default: "assets/translations"
  final String translationPath;

  final Iterable<LocalizationsDelegate<dynamic>>? delegates;

  const LocalizationConfig({
    this.supportedLocales = const [Locale("fr", "FR")],
    this.defaultLocale = const Locale("fr", "FR"),
    this.translationPath = "assets/translations",
    this.delegates = const [],
  });
}

/// Useful function
AppModel getAppModel() => GetIt.instance<AppModel>();

enum ThemeModeType { light, dark, system, useProvider }
