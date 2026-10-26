import 'package:flutter/foundation.dart';

/// Poste d'un joueur sur le terrain.
///
/// Le libellé correspond à l'intitulé de la catégorie affichée sur la
/// page « Mon équipe » (au pluriel : entête de la colonne du poste).
enum PlayerPosition {
  gardien('Gardiens', 'Gardien'),
  defenseur('Défenseurs', 'Défenseur'),
  milieu('Milieux', 'Milieu'),
  attaquant('Attaquants', 'Attaquant');

  const PlayerPosition(this.label, this.singular);

  /// Libellé pluriel affiché en entête de colonne (« Mon équipe »).
  final String label;

  /// Libellé singulier affiché en puce sur la page « Détail joueur ».
  final String singular;
}

/// Pied fort d'un joueur.
enum StrongFoot {
  droit('Droit', 'Droitier'),
  gauche('Gauche', 'Gaucher');

  const StrongFoot(this.label, this.adjective);

  /// Libellé court (colonne « Pied Fort » de « Mon équipe »).
  final String label;

  /// Forme adjectivale affichée en puce sur la page « Détail joueur ».
  final String adjective;
}

/// Une fiche joueur de l'équipe.
///
/// IMPORTANT : un joueur n'est PAS un utilisateur de l'application. C'est une
/// simple fiche gérée par l'entraîneur : prénom, nom, pied fort et poste.
@immutable
class Player {
  const Player({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.strongFoot,
    required this.position,
  });

  /// Identifiant du document Firestore (`users/{uid}/players/{id}`).
  /// `null` tant que le joueur n'est pas encore persisté.
  final String? id;
  final String firstName;
  final String lastName;
  final StrongFoot strongFoot;
  final PlayerPosition position;

  /// « Prénom Nom » prêt à afficher.
  String get fullName => '$firstName $lastName';

  Player copyWith({
    String? id,
    String? firstName,
    String? lastName,
    StrongFoot? strongFoot,
    PlayerPosition? position,
  }) {
    return Player(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      strongFoot: strongFoot ?? this.strongFoot,
      position: position ?? this.position,
    );
  }

  /// Champs persistés (l'id et l'ordre/horodatage sont gérés par le repository).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'firstName': firstName,
    'lastName': lastName,
    'strongFoot': strongFoot.name,
    'position': position.name,
  };

  /// Construit un joueur depuis un document Firestore. Tolérant aux valeurs
  /// manquantes ou inconnues (retombe sur des valeurs par défaut sûres).
  factory Player.fromDoc(String id, Map<String, dynamic> json) {
    return Player(
      id: id,
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      strongFoot:
          StrongFoot.values.asNameMap()[json['strongFoot']] ?? StrongFoot.droit,
      position:
          PlayerPosition.values.asNameMap()[json['position']] ??
          PlayerPosition.milieu,
    );
  }
}

/// Plafond d'effectif par défaut. Pour un club dont le format est connu
/// (`users/{uid}.teamFormat`, cf. `PlayerCount.maxSquadSize`) le plafond en
/// dérive ; sinon il vit dans `app_config/config.max_players` (lu par
/// `PlayerRepository.maxSquadSize` et par les règles Firestore). Celle-ci n'est
/// que le repli hors ligne, et reste 20 : jamais le plafond d'un petit format.
const int kMaxSquadSize = 20;

/// Vrai dès que l'effectif atteint le plafond : plus aucune création possible.
///
/// Les effectifs déjà au-delà (créés avant l'introduction du plafond) restent
/// affichables tels quels — « 21 sur 20 joueurs » — seul l'ajout est refusé.
bool isSquadFull(int playerCount, {int max = kMaxSquadSize}) =>
    playerCount >= max;

/// Levée quand on tente d'ajouter un joueur à un effectif déjà complet.
class SquadFullException implements Exception {
  const SquadFullException();
}
