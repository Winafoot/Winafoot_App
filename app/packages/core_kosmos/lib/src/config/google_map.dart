import 'package:core_kosmos/core_kosmos.dart';

/// Configuration pour Google Maps.
class GoogleMapConfig extends PackageConfig {
  /// Clé canonique pour l'enregistrement dans AppModel.dependencies.packages
  static const String key = "google_map";

  GoogleMapConfig({
    this.googleMapApiKey,
  }) : super(key);

  final String? googleMapApiKey;
}

/// Récupère la configuration [GoogleMapConfig] depuis AppModel.
/// Retourne une instance par défaut si non enregistrée.
GoogleMapConfig getGoogleMapConfig() {
  final config = getAppModel().dependencies.packages[GoogleMapConfig.key];
  assert(
    config == null || config is GoogleMapConfig,
    'Type mismatch for ${GoogleMapConfig.key}: expected GoogleMapConfig, got ${config.runtimeType}',
  );
  return (config as GoogleMapConfig?) ?? GoogleMapConfig();
}
