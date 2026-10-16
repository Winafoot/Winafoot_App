import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/foundation.dart';

/// {@category Controller}
/// {@category Config}
///
/// Permet d'intéraire avec la configuration de l'application.
/// Toutes les données sont sur le Firebase Firestore dans une
/// collection "app_config" et un document "metadata".
///
abstract class AppMetadataController {
  /// permet de récupérer la configuration de l'application.
  static Future<AppMetadataConfig?> getMetadataConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("app_config")
          .doc("metadata")
          .get();
      if (doc.exists) return AppMetadataConfig.fromJson(doc.data()!);
      return null;
    } catch (e) {
      printExcept(e);
      return null;
    }
  }

  /// Permet de récupérer et stocker la configuration de l'application.
  static Future<bool> stockMetadataForApp() async {
    if (GetIt.I.isRegistered<AppMetadataConfig>()) {
      await GetIt.I.unregister<AppMetadataConfig>();
    }

    final config = await getMetadataConfig();
    if (config != null) {
      GetIt.I.registerSingleton<AppMetadataConfig>(config);
      debugPrint('Metadata configuration (re)loaded successfully');
      return true;
    }

    return false;
  }

  static Future<AppMetadataConfig?> getMetadata() async {
    if (GetIt.I.isRegistered<AppMetadataConfig>())
      return GetIt.I<AppMetadataConfig>();
    return null;
  }
}
