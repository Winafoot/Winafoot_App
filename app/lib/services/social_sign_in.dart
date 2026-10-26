import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kosmos_auth/kosmos_auth.dart' show KosmosAuth;
import 'package:wina/config/skeleton_config.dart' show kCloudRegion;

/// Fournisseur « Se connecter avec… ».
enum SocialProvider { google, apple }

/// Issue d'une connexion Google / Apple.
enum SocialSignInOutcome {
  /// Le coach a fermé la fenêtre du fournisseur : rien à afficher.
  cancelled,

  /// Compte déjà connu : le coach est connecté.
  signedIn,

  /// Première connexion : la fiche coach vient d'être créée (reste « Finalisez
  /// votre profil »).
  created,

  /// Première connexion mais CGU refusées : le compte vient d'être supprimé.
  cguRefused,

  /// Échec ; [SocialSignInResult.message] dit pourquoi.
  failed,
}

class SocialSignInResult {
  const SocialSignInResult(this.outcome, [this.message]);

  final SocialSignInOutcome outcome;

  /// Message à afficher, uniquement pour [SocialSignInOutcome.failed].
  final String? message;

  bool get isSignedIn =>
      outcome == SocialSignInOutcome.signedIn ||
      outcome == SocialSignInOutcome.created;
}

/// Connexion Google / Apple d'un coach.
///
/// Firebase Auth connecte le compte (et le rattache à un compte e-mail existant
/// de même adresse). Une première connexion n'a pas de fiche `users/{uid}` : les
/// règles Firestore interdisent au client de la créer, c'est le callable
/// `completeSocialSignup` qui l'écrit, après acceptation des CGU.
abstract class SocialSignIn {
  /// [askCgu] demande l'acceptation des CGU à un nouveau coach (`true` : accepté).
  static Future<SocialSignInResult> signIn(
    SocialProvider provider, {
    required Future<bool> Function() askCgu,
  }) async {
    String? appleGivenName;
    final String? failure;
    switch (provider) {
      case SocialProvider.google:
        final account = await KosmosAuth.getGoogleCredential();
        if (account == null) {
          return const SocialSignInResult(SocialSignInOutcome.cancelled);
        }
        failure = (await KosmosAuth.signInWithGoogle(
          account,
        )).fold((String l) => l, (_) => null);
      case SocialProvider.apple:
        final String rawNonce = KosmosAuth.generateNonce();
        final credential = await KosmosAuth.getAppleCredential(
          rawNonce,
          KosmosAuth.sha256ofString(rawNonce),
        );
        if (credential == null) {
          return const SocialSignInResult(SocialSignInOutcome.cancelled);
        }
        // Apple ne donne le prénom qu'à la toute première connexion.
        appleGivenName = credential.givenName;
        failure = (await KosmosAuth.signInWithApple(
          credential,
          rawNonce,
        )).fold((String l) => l, (_) => null);
    }
    if (failure != null) {
      return SocialSignInResult(SocialSignInOutcome.failed, failure);
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SocialSignInResult(SocialSignInOutcome.failed);
    }

    try {
      if (await _hasProfile(user.uid)) {
        return const SocialSignInResult(SocialSignInOutcome.signedIn);
      }

      if (!await askCgu()) {
        await _discard(user);
        return const SocialSignInResult(SocialSignInOutcome.cguRefused);
      }

      await FirebaseFunctions.instanceFor(
        region: kCloudRegion,
      ).httpsCallable('completeSocialSignup').call(<String, dynamic>{
        'acceptedCgu': true,
        if (appleGivenName != null && appleGivenName.trim().isNotEmpty)
          'firstname': appleGivenName.trim(),
      });
      return const SocialSignInResult(SocialSignInOutcome.created);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[SocialSignIn] ${e.code} ${e.message}');
      await _discard(user);
      return SocialSignInResult(SocialSignInOutcome.failed, messageFor(e));
    } catch (e) {
      debugPrint('[SocialSignIn] $e');
      await _discard(user);
      return const SocialSignInResult(SocialSignInOutcome.failed);
    }
  }

  /// `users/{uid}` existe et porte `createdAt` (même test que le serveur).
  static Future<bool> _hasProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists && doc.data()?['createdAt'] != null;
  }

  /// Un compte tout juste créé sans fiche ne doit pas rester : supprimé s'il le
  /// peut (connexion récente), sinon simplement déconnecté.
  static Future<void> _discard(User user) async {
    try {
      await user.delete();
    } catch (_) {
      // Rien à faire de plus : la déconnexion suffit, la fiche sera créée à la
      // prochaine connexion.
    }
    await FirebaseAuth.instance.signOut();
  }

  @visibleForTesting
  static String? messageFor(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'resource-exhausted':
        return 'Trop de tentatives. Réessayez dans un moment.';
      case 'failed-precondition':
        final String? detail = e.message?.trim();
        return detail != null && detail.isNotEmpty ? detail : null;
      default:
        return null;
    }
  }
}
