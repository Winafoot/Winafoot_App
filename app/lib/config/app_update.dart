import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Mise à jour forcée, pilotée par `app_config/metadata` :
///
/// ```
/// minBuild: { android: <int>, ios: <int> }
/// storeUrl: { android: <string>, ios: <string> }
/// ```
///
/// Une version dont le numéro de build est inférieur à `minBuild` de sa
/// plateforme affiche l'écran bloquant [UpdateRequiredPage], avec un bouton
/// vers `storeUrl`. Champ absent, mal formé ou plateforme non renseignée :
/// aucun blocage.
abstract final class AppUpdate {
  static const String minBuildField = 'minBuild';
  static const String storeUrlField = 'storeUrl';

  /// Clé de la plateforme dans les maps `minBuild` et `storeUrl`, ou `null`
  /// hors Android et iOS.
  static String? platformKey([TargetPlatform? platform]) {
    switch (platform ?? defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return null;
    }
  }

  /// Build minimal exigé pour [platformKey], lu dans `metadata`.
  static int? minBuildFor(Map<String, dynamic>? metadata, String? platformKey) {
    final Object? value = _entry(metadata, minBuildField, platformKey);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Lien vers la fiche du store pour [platformKey], lu dans `metadata`.
  static String? storeUrlFor(
    Map<String, dynamic>? metadata,
    String? platformKey,
  ) {
    final Object? value = _entry(metadata, storeUrlField, platformKey);
    if (value is! String) return null;
    final String url = value.trim();
    return url.isEmpty ? null : url;
  }

  /// `true` si le build courant est connu et strictement inférieur au build
  /// minimal exigé.
  static bool isUpdateRequired({
    required int? currentBuild,
    required int? minBuild,
  }) {
    if (currentBuild == null || minBuild == null) return false;
    return currentBuild < minBuild;
  }

  /// Numéro de build de l'application installée (`versionCode` sur Android,
  /// `CFBundleVersion` sur iOS), ou `null` s'il n'est pas lisible.
  static Future<int?> currentBuildNumber() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return int.tryParse(info.buildNumber);
    } catch (_) {
      return null;
    }
  }

  static Object? _entry(
    Map<String, dynamic>? metadata,
    String field,
    String? platformKey,
  ) {
    if (metadata == null || platformKey == null) return null;
    final Object? map = metadata[field];
    if (map is! Map) return null;
    return map[platformKey];
  }
}
