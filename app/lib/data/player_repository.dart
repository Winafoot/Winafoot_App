import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wina/config/skeleton_config.dart';
import 'package:wina/models/formation.dart' show PlayerCount;
import 'package:wina/models/player.dart';

/// Accès à l'effectif du coach connecté, stocké dans la sous-collection
/// Firestore `users/{uid}/players`.
///
/// Un joueur n'est PAS un utilisateur : c'est une simple fiche (prénom, nom,
/// pied fort, poste) rattachée au document de l'utilisateur courant.
abstract class PlayerRepository {
  static const String _playersSubcollection = 'players';

  /// Document de l'utilisateur connecté (format du club, `teamFormat`).
  ///
  /// Lève une [StateError] si aucun utilisateur n'est authentifié.
  static DocumentReference<Map<String, dynamic>> _userDoc() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Aucun utilisateur connecté : effectif inaccessible.');
    }
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  /// Sous-collection des joueurs de l'utilisateur connecté.
  static CollectionReference<Map<String, dynamic>> _collection() =>
      _userDoc().collection(_playersSubcollection);

  /// Flux temps réel de l'effectif, ordonné par `order` (ordre d'affichage).
  static Stream<List<Player>> watchPlayers() {
    return _collection()
        .orderBy('order')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map((doc) => Player.fromDoc(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  /// Ajoute un joueur (id auto-généré). `order` par défaut = nombre actuel.
  ///
  /// La création passe par le callable `createPlayer` : les règles Firestore
  /// refusent toute création directe, car elles ne savent pas compter les
  /// documents d'une collection (un client modifié contournait le compteur).
  /// Le serveur applique le plafond sur le nombre réel de joueurs (format du
  /// club, sinon `app_config/config`) et répond
  /// `failed-precondition` quand l'effectif est complet.
  ///
  /// Lève une [SquadFullException] dans ce cas, pour afficher un message clair
  /// plutôt qu'une erreur réseau opaque.
  static Future<void> addPlayer(Player player, {int? order}) async {
    try {
      await _callable('createPlayer').call<dynamic>(<String, dynamic>{
        ...player.toJson(),
        if (order != null) 'order': order,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') throw const SquadFullException();
      rethrow;
    }
  }

  static HttpsCallable _callable(String name) =>
      FirebaseFunctions.instanceFor(region: kCloudRegion).httpsCallable(name);

  /// Plafond d'effectif de l'utilisateur connecté : celui de son format de club
  /// (`users/{uid}.teamFormat`) s'il est connu, sinon [configMaxSquadSize].
  ///
  /// Rien n'est mis en cache : le plafond dépend du compte, et un cache statique
  /// servirait au second compte connecté dans la session celui du premier. Une
  /// lecture illisible (hors ligne, pas de session) retombe sur le plafond
  /// historique, jamais sur celui d'un petit format.
  static Future<int> maxSquadSize() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _userDoc().get();
      final PlayerCount? format = PlayerCount.fromValue(
        doc.data()?['teamFormat'],
      );
      if (format != null) return format.maxSquadSize;
    } catch (_) {
      // Repli ci-dessous.
    }
    return configMaxSquadSize();
  }

  /// Plafond des comptes sans format de club, lu dans
  /// `app_config/config.max_players`. Repli sur [kMaxSquadSize] si le document,
  /// le champ ou le réseau manquent : mieux vaut le plafond historique qu'une
  /// création bloquée.
  static Future<int> configMaxSquadSize() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance
              .collection('app_config')
              .doc('config')
              .get();
      final Object? raw = doc.data()?['max_players'];
      return raw is int && raw > 0 ? raw : kMaxSquadSize;
    } catch (_) {
      return kMaxSquadSize;
    }
  }

  /// Met à jour les champs éditables d'un joueur existant.
  static Future<void> updatePlayer(Player player) async {
    final String? id = player.id;
    if (id == null) return;
    await _collection().doc(id).update(player.toJson());
  }

  /// Supprime définitivement un joueur, par le callable `deletePlayer` : le
  /// serveur recale aussi le compteur d'effectif, que le client ne peut plus
  /// écrire (les règles refusent la suppression directe).
  static Future<void> deletePlayer(String id) async {
    await _callable('deletePlayer').call<dynamic>(<String, dynamic>{'id': id});
  }
}
