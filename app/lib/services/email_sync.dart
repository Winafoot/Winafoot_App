import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Recopie dans `users/{uid}.email` l'adresse de Firebase Auth quand elle a
/// changé.
///
/// Le changement d'adresse passe par `verifyBeforeUpdateEmail` : Firebase Auth
/// ne bascule sur la nouvelle adresse qu'après le clic sur le lien reçu. Le
/// document Firestore est donc mis à jour ensuite, au lancement, à chaque
/// connexion et au retour de l'app au premier plan, à partir du compte
/// rechargé.
abstract final class EmailSync {
  static AppLifecycleListener? _lifecycle;
  static StreamSubscription<User?>? _authSubscription;
  static bool _running = false;

  /// Adresse à écrire dans Firestore, ou `null` s'il n'y a rien à faire.
  static String? emailToWrite({
    required String? authEmail,
    required String? storedEmail,
  }) {
    if (authEmail == null || authEmail.isEmpty) return null;
    if (authEmail == storedEmail) return null;
    return authEmail;
  }

  /// Branche la synchronisation : état de connexion (premier événement au
  /// lancement, puis chaque connexion) et retour au premier plan.
  static void start() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (user != null) unawaited(sync());
    });
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(sync()));
  }

  /// Recharge le compte connecté et met à jour `users/{uid}.email` si
  /// l'adresse a changé. Ne lève jamais d'exception.
  static Future<void> sync() async {
    if (_running) return;
    _running = true;
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      final User? refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed == null) return;
      final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
          .instance
          .collection('users')
          .doc(refreshed.uid);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();
      if (!snapshot.exists) return;
      final Object? stored = snapshot.data()?['email'];
      final String? email = emailToWrite(
        authEmail: refreshed.email,
        storedEmail: stored is String ? stored : null,
      );
      if (email != null) await ref.update(<String, dynamic>{'email': email});
    } catch (e, st) {
      developer.log(
        'Synchronisation de l\'adresse e-mail impossible',
        name: 'EmailSync',
        error: e,
        stackTrace: st,
      );
    } finally {
      _running = false;
    }
  }
}
