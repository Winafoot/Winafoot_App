import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:wina/config/skeleton_config.dart';
import 'package:wina/models/app_notification.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';

/// Persistance des matchs sous `users/{uid}/matches`.
///
/// Le domaine « match » est 100 % client (aucune Cloud Function côté serveur).
abstract class MatchRepository {
  static CollectionReference<Map<String, dynamic>> _col() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Aucun utilisateur connecté.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matches');
  }

  /// Crée (si `match.id` est nul) ou met à jour le brouillon du match courant.
  /// Retourne l'identifiant du document.
  static Future<String> saveDraft(GameMatch match) async {
    final Map<String, dynamic> data = <String, dynamic>{
      ...match.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final String? id = match.id;
    if (id == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final DocumentReference<Map<String, dynamic>> ref = await _col().add(
        data,
      );
      return ref.id;
    }
    await _col().doc(id).set(data, SetOptions(merge: true));
    return id;
  }

  /// Nombre maximal de matchs relus par l'historique. Borne les lectures :
  /// chaque document porte les statistiques de 20 joueurs.
  static const int _historyLimit = 50;

  /// Flux des [_historyLimit] derniers matchs terminés (les plus récents
  /// d'abord). Le tri est fait par Firestore sur `finishedAt` : les brouillons
  /// et les matchs abandonnés n'ont pas ce champ et sont donc absents du
  /// résultat, ce qui évite l'index composite (where + orderBy).
  static Stream<List<GameMatch>> watchFinishedMatches() {
    return _col()
        .orderBy('finishedAt', descending: true)
        .limit(_historyLimit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                    GameMatch.fromDoc(d.id, d.data()),
              )
              .where((GameMatch m) => m.status == MatchStatus.finished)
              .toList(growable: false),
        );
  }

  /// Enregistre le résultat d'un match terminé (score, statistiques par joueur,
  /// durée) sur le document existant.
  static Future<void> finishMatch(String id, LiveMatch live) async {
    await _col().doc(id).set(<String, dynamic>{
      ...finishedPayload(live),
      'finishedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Émission au mieux, jamais attendue : l'enregistrement du match est
    // acquis dès le `set`, la notification ne doit ni le retarder ni le
    // faire échouer.
    unawaited(_notifyMatchFinished(id));
  }

  /// Champs du résultat d'un match terminé, hors `finishedAt` (horodaté par le
  /// serveur). Écrits par TOUS les chemins de fin de match (écran de direct en
  /// 2e mi-temps, écran de coupure « Fin du match »).
  @visibleForTesting
  static Map<String, dynamic> finishedPayload(LiveMatch live) {
    return <String, dynamic>{
      'status': 'finished',
      'scoreUs': live.scoreUs,
      'scoreThem': live.scoreThem,
      'elapsedSeconds': live.elapsedSeconds,
      // `playerStats` reste le TOTAL du match : cumul carrière et plafond de
      // cartons ne dépendent pas du découpage.
      'playerStats': live.playerStats,
      // Sélection en vigueur à la fin : celle du coup d'envoi ignorait les
      // stats activées ou désactivées en pause ou à la mi-temps.
      'enabledStatKeys': live.enabledStatKeys,
      // Découpage par mi-temps : la 2e se déduit (total − 1re) à la lecture.
      'half': live.half,
      'firstHalfStats': live.firstHalfStats,
      'firstHalfStatKeys': live.firstHalfStatKeys,
    };
  }

  /// Lit un match par son identifiant. `null` si le document n'existe plus
  /// (match supprimé depuis l'historique).
  static Future<GameMatch?> getMatch(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _col().doc(id).get();
    final Map<String, dynamic>? data = doc.data();
    return data == null ? null : GameMatch.fromDoc(doc.id, data);
  }

  /// Prévient le coach que son match est terminé.
  ///
  /// Les règles Firestore interdisent au client d'écrire dans
  /// `users/{uid}/notifications` (`allow create: if false`) : le callable
  /// `addNotification` est le seul écrivain possible.
  ///
  /// Tout échec est avalé : une notification perdue est sans conséquence, un
  /// match perdu ne l'est pas.
  static Future<void> _notifyMatchFinished(String matchId) async {
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFunctions.instanceFor(region: kCloudRegion)
          .httpsCallable('addNotification')
          .call<dynamic>(
            matchFinishedPayload(
              uid: uid,
              matchId: matchId,
              title: 'app.notifications.match-termine-titre'.tr(),
              body: 'app.notifications.match-termine-message'.tr(),
              ctaLabel: 'app.notifications.match-termine-cta'.tr(),
            ),
          );
    } catch (e) {
      // Avalé, mais tracé : sans cette ligne une notification qui n'arrive
      // jamais (HttpsError, retour `{error}` de la variante legacy) est
      // indiagnosticable. `debugPrint` disparaît en release.
      debugPrint('addNotification (match terminé) a échoué : $e');
    }
  }

  /// Charge utile du callable `addNotification` pour « Match terminé ».
  @visibleForTesting
  static Map<String, dynamic> matchFinishedPayload({
    required String uid,
    required String matchId,
    required String title,
    required String body,
    required String ctaLabel,
  }) {
    return <String, dynamic>{
      'addNotifTo': <String>[uid],
      // Exigé par la variante non authentifiée du callable, qui sinon échoue
      // en silence (elle retourne `{error}` au lieu de lever). Le wrapper
      // sécurisé, lui, l'écrase par l'uid de l'appelant : inoffensif.
      'senderId': uid,
      // Le coach est au premier plan quand il termine son match : le push ne
      // lui apprendrait rien, et il créerait dans la collection racine
      // `notifications` un document qu'il ne peut pas supprimer.
      'sendPushNotif': false,
      'internalNotifModel': <String, dynamic>{
        'title': title,
        'body': body,
        'type': kMatchFinishedNotificationType,
        // `entityId` alimente le bouton d'action de la carte in-app. Le
        // deeplink du push, lui, lit `route`/`entityId` à la racine du
        // document : contrat serveur, hors périmètre.
        'metadata': <String, dynamic>{
          'ctaLabel': ctaLabel,
          'entityId': matchId,
        },
      },
    };
  }

  /// Marque un match comme abandonné (quitté sans finaliser). Le résultat n'est
  /// pas enregistré : le match n'apparaît pas dans l'historique, filtré sur
  /// `finished` (cf. [watchFinishedMatches]).
  static Future<void> abandonMatch(String id) async {
    await _col().doc(id).set(<String, dynamic>{
      'status': MatchStatus.abandoned.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Supprime définitivement un match et ses statistiques
  /// (historique « Statistiques Matchs »).
  ///
  /// Aucun écran ne l'appelle aujourd'hui : l'écran « Statistiques matchs »
  /// ne propose pas de suppression. La méthode reste disponible pour une
  /// suppression de match.
  static Future<void> deleteMatch(String id) async {
    await _col().doc(id).delete();
  }
}
