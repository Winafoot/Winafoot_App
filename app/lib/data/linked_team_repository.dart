import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wina/config/skeleton_config.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';

/// Une équipe liée au compte propriétaire (un compte Firebase par équipe).
class LinkedTeam {
  const LinkedTeam({
    required this.uid,
    required this.teamName,
    required this.identifier,
    required this.teamIndex,
    this.category,
    this.division,
    this.teamFormat,
    this.playerCount,
  });

  factory LinkedTeam.fromDoc(String uid, Map<String, dynamic> data) {
    final String email = (data['email'] as String?) ?? '';
    return LinkedTeam(
      uid: uid,
      teamName: (data['teamName'] as String?) ?? '',
      identifier: email.split('@').first,
      teamIndex: (data['teamIndex'] as int?) ?? 0,
      category: TeamCategory.values.asNameMap()[data['category']],
      division: TeamDivision.values.asNameMap()[data['division']],
      teamFormat: PlayerCount.fromValue(data['teamFormat']),
      playerCount: data['playerCount'] is int ? data['playerCount'] as int : null,
    );
  }

  final String uid;
  final String teamName;

  /// L'identifiant de connexion se lit dans l'adresse technique (`<identifiant>@equipes.wina.invalid`).
  final String identifier;
  final int teamIndex;

  /// Lus sur la fiche `users/{uid}` de l'équipe (le propriétaire y a accès) ; absents : `null`.
  final TeamCategory? category;
  final TeamDivision? division;
  final PlayerCount? teamFormat;

  /// Compteur tenu par le serveur à chaque création ou suppression de joueur. Les joueurs eux-mêmes ne
  /// sont lisibles que par le compte de l'équipe, d'où ce compteur pour l'affichage du propriétaire.
  final int? playerCount;
}

/// Erreurs métier de createLinkedTeam (messages posés par le serveur).
enum LinkedTeamError { identifierTaken, quotaReached, noSubscription, invalid, other }

class LinkedTeamException implements Exception {
  const LinkedTeamException(this.error);
  final LinkedTeamError error;
}

abstract class LinkedTeamRepository {
  static HttpsCallable _callable(String name) => FirebaseFunctions.instanceFor(region: kCloudRegion).httpsCallable(name);

  /// Équipes liées du propriétaire connecté, en temps réel, par `teamIndex`
  /// (autorisé par la règle `ownerUid == request.auth.uid`, Task 1).
  static Stream<List<LinkedTeam>> watch(String ownerUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> s) {
          final List<LinkedTeam> teams = s.docs.map((d) => LinkedTeam.fromDoc(d.id, d.data())).toList();
          teams.sort((a, b) => a.teamIndex.compareTo(b.teamIndex));
          return teams;
        });
  }

  static Future<void> create({
    required String identifier,
    required String password,
    required String teamName,
    required String category,
    required String division,
    required int teamFormat,
  }) async {
    try {
      await _callable('createLinkedTeam').call<dynamic>(<String, dynamic>{
        'identifier': identifier,
        'password': password,
        'teamName': teamName,
        'category': category,
        'division': division,
        'teamFormat': teamFormat,
      });
    } on FirebaseFunctionsException catch (e) {
      throw LinkedTeamException(mapError(e.code, e.message));
    }
  }

  static Future<void> resetPassword({required String uid, required String password}) async {
    await _callable('resetLinkedTeamPassword').call<dynamic>(<String, dynamic>{'uid': uid, 'password': password});
  }

  static LinkedTeamError mapError(String code, String? message) {
    if (code == 'already-exists') return LinkedTeamError.identifierTaken;
    if (code == 'failed-precondition' && message == 'team-quota-reached') return LinkedTeamError.quotaReached;
    if (code == 'failed-precondition' && message == 'no-active-subscription') return LinkedTeamError.noSubscription;
    if (code == 'invalid-argument') return LinkedTeamError.invalid;
    return LinkedTeamError.other;
  }

  /// Uid du compte connecté, ou `null`.
  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
}
