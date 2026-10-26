import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wina/models/live_match_sync.dart';

/// Commande déposée par l'adjoint : `bump` (+1 / −1 d'une stat d'un joueur) ou `remove` (retrait d'un
/// événement de l'historique). Le coach l'applique avec sa logique habituelle, puis la supprime.
class LiveCommand {
  const LiveCommand({
    required this.id,
    required this.type,
    required this.eventId,
    this.playerId,
    this.playerName,
    this.statKey,
    this.statLabel,
    this.delta = 1,
  });

  factory LiveCommand.fromDoc(String id, Map<String, dynamic> data) =>
      LiveCommand(
        id: id,
        type: (data['type'] as String?) ?? '',
        eventId: (data['eventId'] as String?) ?? '',
        playerId: data['playerId'] as String?,
        playerName: data['playerName'] as String?,
        statKey: data['statKey'] as String?,
        statLabel: data['statLabel'] as String?,
        delta: (data['delta'] as num?)?.toInt() ?? 1,
      );

  final String id;
  final String type;
  final String eventId;
  final String? playerId;
  final String? playerName;
  final String? statKey;
  final String? statLabel;
  final int delta;
}

/// Match en direct partagé entre le coach et son adjoint, sous `users/{coach}/liveMatch/current`
/// (règles : le coach écrit l'état, l'adjoint le lit et dépose des commandes dans `commands`).
abstract class LiveMatchSyncRepository {
  static DocumentReference<Map<String, dynamic>> _doc(String coachUid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(coachUid)
          .collection('liveMatch')
          .doc('current');

  static CollectionReference<Map<String, dynamic>> _commands(String coachUid) =>
      _doc(coachUid).collection('commands');

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Coach ────────────────────────────────────────────────────────────────

  /// Publie l'état complet du match (écrase le précédent).
  static Future<void> publish(Map<String, dynamic> json) async {
    final String? uid = _uid;
    if (uid == null) return;
    await _doc(uid).set(<String, dynamic>{
      ...json,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ferme le match côté adjoint (fin ou abandon).
  static Future<void> end() async {
    final String? uid = _uid;
    if (uid == null) return;
    await _doc(uid).set(<String, dynamic>{
      'status': 'ended',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Supprime les commandes restées d'un match précédent, avant d'écouter les nouvelles.
  static Future<void> clearCommands() async {
    final String? uid = _uid;
    if (uid == null) return;
    final QuerySnapshot<Map<String, dynamic>> old = await _commands(uid).get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> d in old.docs) {
      await d.reference.delete();
    }
  }

  /// Nouvelles commandes de l'adjoint, dans l'ordre d'arrivée.
  static Stream<List<LiveCommand>> watchCommands() {
    final String? uid = _uid;
    if (uid == null) return const Stream<List<LiveCommand>>.empty();
    return _commands(uid).orderBy('createdAt').snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> s) => <LiveCommand>[
        for (final DocumentChange<Map<String, dynamic>> c in s.docChanges)
          if (c.type == DocumentChangeType.added && c.doc.data() != null)
            LiveCommand.fromDoc(c.doc.id, c.doc.data()!),
      ],
    );
  }

  static Future<void> deleteCommand(String id) async {
    final String? uid = _uid;
    if (uid == null) return;
    await _commands(uid).doc(id).delete();
  }

  // ── Adjoint ──────────────────────────────────────────────────────────────

  /// Match en cours du coach, en temps réel ; `null` tant qu'aucun match n'a commencé.
  static Stream<LiveMatchSnapshot?> watch(String coachUid) {
    return _doc(coachUid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> s,
    ) {
      return _parse(s.data());
    });
  }

  static LiveMatchSnapshot? _parse(Map<String, dynamic>? data) {
    if (data == null) return null;
    final Object? at = data['updatedAt'];
    return LiveMatchSnapshot.fromJson(<String, dynamic>{
      ...data,
      'updatedAtMs': at is Timestamp ? at.millisecondsSinceEpoch : null,
    });
  }

  /// Match laissé ouvert par le coach connecté (appli fermée ou plantée en plein match), ou `null`.
  static Future<LiveMatchSnapshot?> getCurrent() async {
    final String? uid = _uid;
    if (uid == null) return null;
    final DocumentSnapshot<Map<String, dynamic>> s = await _doc(uid).get();
    final LiveMatchSnapshot? snap = _parse(s.data());
    return snap == null || snap.ended ? null : snap;
  }

  static Future<void> sendBump(
    String coachUid, {
    required String eventId,
    required String playerId,
    required String playerName,
    required String statKey,
    required String statLabel,
    required int delta,
  }) {
    return _commands(coachUid).add(<String, dynamic>{
      'type': 'bump',
      'eventId': eventId,
      'playerId': playerId,
      'playerName': playerName,
      'statKey': statKey,
      'statLabel': statLabel,
      'delta': delta,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Demande au coach d'inverser (ou non) le sens du terrain.
  static Future<void> sendSwap(String coachUid, bool swapSides) {
    return _commands(coachUid).add(<String, dynamic>{
      'type': 'swap',
      'eventId': 'swap',
      'delta': swapSides ? 1 : -1,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendRemove(String coachUid, String eventId) {
    return _commands(coachUid).add(<String, dynamic>{
      'type': 'remove',
      'eventId': eventId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
