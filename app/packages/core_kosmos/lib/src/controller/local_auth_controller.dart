import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Stockage des identifiants de la connexion biométrique.
abstract class LocalCredentialStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Stockage par défaut : trousseau iOS (accessible sur cet appareil
/// uniquement, appareil déverrouillé) et Keystore Android, via
/// [FlutterSecureStorage].
class SecureCredentialStore implements LocalCredentialStore {
  const SecureCredentialStore([
    this._storage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    ),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Connexion biométrique.
///
/// Les identifiants (e-mail et mot de passe) ne sont conservés que si
/// l'utilisateur a activé la connexion biométrique ([enableBiometrics]), et
/// alors uniquement dans le stockage sécurisé du système ([credentialStore]).
/// Ils sont effacés à la désactivation, à la déconnexion et, au lancement, si
/// la connexion biométrique n'est pas activée.
abstract class LocalAuthController {
  /// Drapeau local (SharedPreferences) : connexion biométrique activée.
  static const String biometricsFlagKey = "biometrics";

  /// Clés du stockage sécurisé.
  static const String emailKey = "local_auth_email";
  static const String passwordKey = "local_auth_password";

  /// Clés SharedPreferences des versions précédentes, purgées au lancement.
  static const List<String> legacyKeys = <String>["data", "email"];

  /// Stockage des identifiants, remplaçable dans les tests.
  static LocalCredentialStore credentialStore = const SecureCredentialStore();

  static Future<bool> isBiometricsEnabled() async =>
      (await LocalConfigController.getData<bool>(biometricsFlagKey)) ?? false;

  static Future<void> disbaleBiometrics() async {
    await LocalConfigController.setData(biometricsFlagKey, boolValue: false);
    await clearCredentials();
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("metadata")
        .doc("security")
        .update({
      "enableBiometricLogin": false,
    });
  }

  /// Active la connexion biométrique après une vérification biométrique
  /// réussie. Les identifiants sont enregistrés à la connexion par e-mail
  /// suivante ([rememberCredentials]).
  static Future<bool> enableBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();

    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    if (!canAuthenticate) return false;

    try {
      final bool didAuthenticate =
          await auth.authenticate(localizedReason: 'login');
      if (didAuthenticate) {
        await LocalConfigController.setData(biometricsFlagKey, boolValue: true);
        FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection("metadata")
            .doc("security")
            .update({
          "enableBiometricLogin": true,
        });
        return true;
      }
    } catch (e) {
      printExcept(e);
    }
    return false;
  }

  /// Après une connexion par e-mail réussie : enregistre les identifiants si
  /// la connexion biométrique est activée, sinon efface ceux qui resteraient.
  /// Ne lève jamais d'exception : la connexion ne dépend pas du stockage.
  static Future<void> rememberCredentials(String email, String password) async {
    try {
      if (!await isBiometricsEnabled()) {
        await clearCredentials();
        return;
      }
      await credentialStore.write(emailKey, email);
      await credentialStore.write(passwordKey, password);
    } catch (e) {
      printExcept(e);
    }
  }

  /// Identifiants de la connexion biométrique (e-mail, mot de passe), ou
  /// `null` si elle n'est pas activée ou si rien n'est enregistré.
  static Future<Tuple2<String, String>?> getLoginData() async {
    try {
      if (!await isBiometricsEnabled()) return null;
      final email = await credentialStore.read(emailKey);
      final password = await credentialStore.read(passwordKey);
      if (email == null || password == null) return null;
      return Tuple2(email, password);
    } catch (e) {
      printExcept(e);
      return null;
    }
  }

  /// Efface les identifiants du stockage sécurisé.
  static Future<void> clearCredentials() async {
    await credentialStore.delete(emailKey);
    await credentialStore.delete(passwordKey);
  }

  /// À la déconnexion : efface les identifiants, y compris ceux des versions
  /// précédentes, que la connexion biométrique soit activée ou non. Ne lève
  /// jamais d'exception.
  static Future<void> forgetCredentials() async {
    try {
      for (final key in legacyKeys) {
        await LocalConfigController.clearData(key);
      }
      await clearCredentials();
    } catch (e) {
      printExcept(e);
    }
  }

  /// Au lancement : retire les identifiants laissés dans SharedPreferences par
  /// les versions précédentes et, si la connexion biométrique n'est pas
  /// activée, ceux du stockage sécurisé (le trousseau iOS survit à une
  /// désinstallation). Ne lève jamais d'exception.
  static Future<void> purgeStoredCredentials() async {
    try {
      for (final key in legacyKeys) {
        await LocalConfigController.clearData(key);
      }
      if (!await isBiometricsEnabled()) await clearCredentials();
    } catch (e) {
      printExcept(e);
    }
  }
}
