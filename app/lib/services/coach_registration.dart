import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kosmos_auth/kosmos_auth.dart' show KosmosAuth;
import 'package:wina/config/skeleton_config.dart' show kCloudRegion;

/// Cause d'un échec d'inscription, à traduire en message pour le coach.
enum RegistrationError {
  emailTaken,
  invalidInput,
  cguRefused,
  tooManyAttempts,
  network,
  unknown,
}

class RegistrationException implements Exception {
  const RegistrationException(this.error, [this.message]);

  final RegistrationError error;

  /// Message du serveur (en français), quand il est utile à l'affichage.
  final String? message;

  @override
  String toString() => 'RegistrationException($error)';
}

/// Inscription d'un coach (page 1) : callable `registerCoach`, connexion, puis
/// e-mail de vérification. Le profil du club se complète à la page 2.
abstract class CoachRegistration {
  static Future<void> register({
    required String email,
    required String password,
    required String firstname,
    required bool acceptedCgu,
  }) async {
    final String address = email.trim().toLowerCase();
    try {
      await FirebaseFunctions.instanceFor(
        region: kCloudRegion,
      ).httpsCallable('registerCoach').call(<String, dynamic>{
        'email': address,
        'password': password,
        'firstname': firstname.trim(),
        'acceptedCgu': acceptedCgu,
      });
    } on FirebaseFunctionsException catch (e) {
      throw RegistrationException(errorFromCode(e.code), e.message);
    } catch (_) {
      throw const RegistrationException(RegistrationError.network);
    }

    final UserCredential credential;
    try {
      credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: address,
        password: password,
      );
    } catch (_) {
      // Le compte existe : le coach peut se connecter à la main.
      throw const RegistrationException(RegistrationError.unknown);
    }

    final String? uid = credential.user?.uid;
    if (uid != null) {
      // Best-effort : un échec d'envoi ne doit pas bloquer l'entrée dans l'app.
      unawaited(KosmosAuth.sendEmailVerification(uid, region: kCloudRegion));
    }
  }

  @visibleForTesting
  static RegistrationError errorFromCode(String code) {
    switch (code) {
      case 'already-exists':
        return RegistrationError.emailTaken;
      case 'invalid-argument':
        return RegistrationError.invalidInput;
      case 'failed-precondition':
        return RegistrationError.cguRefused;
      case 'resource-exhausted':
        return RegistrationError.tooManyAttempts;
      case 'unavailable':
      case 'deadline-exceeded':
        return RegistrationError.network;
      default:
        return RegistrationError.unknown;
    }
  }
}
