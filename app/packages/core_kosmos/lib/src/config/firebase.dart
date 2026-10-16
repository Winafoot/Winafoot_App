import 'package:firebase_core/firebase_core.dart';

/// {@category Config}
///
/// Permet de configurer Firebase pour l'application.
///
class FirebaseConfig {
  /// Options de configuration de Firebase.
  final FirebaseOptions? options;

  /// Active ou désactive le service Firebase.
  final bool enabled;

  /// Déconnecte automatique l'utilisateur au lancement de l'application.
  /// (Uniquement en mode Debug)
  final bool clearUserSessionOnDebugMode;

  const FirebaseConfig({
    this.options,
    this.enabled = true,
    this.clearUserSessionOnDebugMode = false,
  });
}
