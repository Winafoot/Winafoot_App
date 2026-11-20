import 'package:flutter/foundation.dart';
import 'package:wina/models/player.dart';

/// Nombre de joueurs sur le terrain (page « Choisissez le nombre de joueurs »),
/// et format du club (`users/{uid}.teamFormat`, posé par le back-office).
enum PlayerCount {
  eleven(11, 20),
  eight(8, 14),
  five(5, 9);

  const PlayerCount(this.value, this.maxSquadSize);

  final int value;

  /// Plafond d'effectif d'un club de ce format (5 → 9, 8 → 14, 11 → 20).
  final int maxSquadSize;

  String get label => '$value';

  /// Format lu dans Firestore. `null` si la valeur est absente ou hors
  /// {5, 8, 11} : l'app ne doit jamais déduire un plafond d'une donnée douteuse.
  static PlayerCount? fromValue(Object? raw) {
    for (final PlayerCount c in values) {
      if (raw is num && raw == c.value) return c;
    }
    return null;
  }
}

/// Emplacement d'un joueur dans une composition, en coordonnées normalisées sur
/// le terrain (portrait) : [x] 0 (gauche) → 1 (droite), [y] 0 (but adverse, en
/// haut) → 1 (son propre but, en bas).
@immutable
class FormationSlot {
  const FormationSlot({required this.role, required this.x, required this.y});

  /// Construit un emplacement depuis un document Firestore. Tolérant : rôle
  /// inconnu ou coordonnées absentes retombent sur des valeurs sûres.
  factory FormationSlot.fromJson(Map<dynamic, dynamic> json) => FormationSlot(
    role:
        PlayerPosition.values.asNameMap()[json['role']] ??
        PlayerPosition.milieu,
    x: (json['x'] as num?)?.toDouble() ?? 0.5,
    y: (json['y'] as num?)?.toDouble() ?? 0.5,
  );

  final PlayerPosition role;
  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is FormationSlot &&
      other.role == role &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(role, x, y);
}

/// Schéma tactique : libellé (« 4-4-1-1 »), nombre de joueurs et emplacements.
@immutable
class Formation {
  const Formation({
    required this.label,
    required this.playerCount,
    required this.slots,
  });

  final String label;
  final int playerCount;
  final List<FormationSlot> slots;

  @override
  bool operator ==(Object other) =>
      other is Formation &&
      other.label == label &&
      other.playerCount == playerCount &&
      listEquals(other.slots, slots);

  @override
  int get hashCode => Object.hash(label, playerCount, Object.hashAll(slots));
}

const PlayerPosition _g = PlayerPosition.gardien;
const PlayerPosition _d = PlayerPosition.defenseur;
const PlayerPosition _m = PlayerPosition.milieu;
const PlayerPosition _a = PlayerPosition.attaquant;

/// Répartit [n] emplacements d'un même rôle sur une ligne horizontale [y].
List<FormationSlot> _line(PlayerPosition role, double y, int n) {
  if (n <= 0) return const <FormationSlot>[];
  if (n == 1) {
    return <FormationSlot>[FormationSlot(role: role, x: 0.5, y: y)];
  }
  const double margin = 0.14;
  final double span = 1 - 2 * margin;
  return <FormationSlot>[
    for (int i = 0; i < n; i++)
      FormationSlot(role: role, x: margin + span * i / (n - 1), y: y),
  ];
}

/// Construit une composition à partir de son libellé (« 4-3-3 »).
///
/// Le gardien est placé au fond (y 0.90), puis chaque chiffre forme une ligne
/// horizontale : le premier chiffre = défenseurs, le dernier = attaquants, et
/// toutes les lignes intermédiaires = milieux. Les lignes sont réparties du bas
/// (défense, y 0.72) vers le haut (attaque, y 0.20). Une ligne à 0 joueur (ex.
/// « 3-4-0 ») est ignorée mais conserve sa place dans l'étagement.
Formation _fromLabel(String label, int playerCount) {
  final List<int> bands = label
      .split('-')
      .map(int.parse)
      .toList(growable: false);
  final int n = bands.length;
  const double yBottom = 0.72;
  const double yTop = 0.20;

  final List<FormationSlot> slots = <FormationSlot>[..._line(_g, 0.90, 1)];
  for (int i = 0; i < n; i++) {
    final int count = bands[i];
    if (count <= 0) continue;
    final double y = n == 1 ? 0.48 : yBottom - (yBottom - yTop) * i / (n - 1);
    final PlayerPosition role = i == 0 ? _d : (i == n - 1 ? _a : _m);
    slots.addAll(_line(role, y, count));
  }
  return Formation(label: label, playerCount: playerCount, slots: slots);
}

/// Composition à emplacements explicites, d'après les planches de référence : [players] donne le rôle et la
/// position en pourcentage du terrain, [x] de la gauche (0) à la droite (100) et [y] mesuré depuis son propre
/// but (0) vers le but adverse (100). Convertis ici dans le repère de l'app (y 0 = but adverse, en haut).
Formation _fromPercent(
  String label,
  int playerCount,
  List<(PlayerPosition, double, double)> players,
) => Formation(
  label: label,
  playerCount: playerCount,
  slots: <FormationSlot>[
    for (final (PlayerPosition role, double x, double y) in players)
      FormationSlot(role: role, x: x / 100, y: 1 - y / 100),
  ],
);

List<Formation> _build(List<String> labels, int playerCount) => <Formation>[
  for (final String label in labels) _fromLabel(label, playerCount),
];

final List<Formation> _formations11 = <Formation>[
  ..._build(<String>[
    '4-4-2',
    '4-3-3',
    '4-4-1-1',
    '4-2-3-1',
    '3-5-2',
    '4-5-1',
    '4-1-4-1',
    '4-1-2-1-2',
    '4-2-2-2',
    '4-3-1-2',
    '4-1-3-2',
    '4-3-2-1',
    '4-2-4',
    '5-4-1',
    '5-2-1-2',
    '5-3-2',
    '5-2-3',
    '3-1-4-2',
    '3-4-1-2',
    '3-1-5-1',
    '3-4-2-1',
    '3-4-3',
    '3-5-1-1',
  ], 11),
  // Défense à 5.
  _fromPercent('5-2-2-1', 11, <(PlayerPosition, double, double)>[
    (_g, 50, 7), // GB
    (_d, 9, 24), // DG
    (_d, 30, 24), // DCG
    (_d, 50, 24), // DC
    (_d, 70, 24), // DCD
    (_d, 91, 24), // DD
    (_m, 36, 44), // MC
    (_m, 64, 44), // MC
    (_a, 13, 63), // AG
    (_a, 87, 63), // AD
    (_a, 50, 84), // BU
  ]),
  _fromPercent('5-3-1-1', 11, <(PlayerPosition, double, double)>[
    (_g, 50, 7), // GB
    (_d, 9, 24), // DG
    (_d, 30, 24), // DCG
    (_d, 50, 24), // DC
    (_d, 70, 24), // DCD
    (_d, 91, 24), // DD
    (_m, 24, 46), // MC
    (_m, 50, 46), // MC
    (_m, 76, 46), // MC
    (_m, 50, 64), // MOC
    (_a, 50, 83), // BU
  ]),
  // Défense à 3.
  _fromPercent('3-2-4-1', 11, <(PlayerPosition, double, double)>[
    (_g, 50, 7), // GB
    (_d, 24, 22), // DCG
    (_d, 50, 22), // DC
    (_d, 76, 22), // DCD
    (_m, 36, 42), // MDC
    (_m, 64, 42), // MDC
    (_a, 11, 64), // AG
    (_m, 36, 64), // MOC
    (_m, 64, 64), // MOC
    (_a, 89, 64), // AD
    (_a, 50, 85), // BU
  ]),
  _fromPercent('3-1-2-1-3', 11, <(PlayerPosition, double, double)>[
    (_g, 50, 7), // GB
    (_d, 24, 22), // DCG
    (_d, 50, 22), // DC
    (_d, 76, 22), // DCD
    (_m, 50, 38), // MDC
    (_m, 20, 52), // MG
    (_m, 80, 52), // MD
    (_m, 50, 65), // MOC
    (_a, 16, 82), // AG
    (_a, 50, 82), // BU
    (_a, 84, 82), // AD
  ]),
  _fromPercent('3-3-1-3', 11, <(PlayerPosition, double, double)>[
    (_g, 50, 7), // GB
    (_d, 24, 22), // DCG
    (_d, 50, 22), // DC
    (_d, 76, 22), // DCD
    (_m, 13, 44), // MG
    (_m, 50, 44), // MDC
    (_m, 87, 44), // MD
    (_m, 50, 62), // MOC
    (_a, 16, 82), // AG
    (_a, 50, 82), // BU
    (_a, 84, 82), // AD
  ]),
  _fromPercent('3-2-2-3', 11, <(PlayerPosition, double, double)>[
    (_g, 50, 7), // GB
    (_d, 24, 22), // DCG
    (_d, 50, 22), // DC
    (_d, 76, 22), // DCD
    (_m, 36, 40), // MDC
    (_m, 64, 40), // MDC
    (_m, 13, 58), // MG
    (_m, 87, 58), // MD
    (_a, 16, 82), // AG
    (_a, 50, 82), // BU
    (_a, 84, 82), // AD
  ]),
];

final List<Formation> _formations8 = <Formation>[
  ..._build(<String>[
    '3-3-1',
    '3-2-2',
    '2-3-2',
    '2-4-1',
    '3-1-3',
    '2-2-3',
    '3-4-0',
    '4-2-1',
    '1-4-2',
    '3-2-1-1',
    '2-3-1-1',
    '2-2-1-2',
  ], 8),
  _fromPercent('3-1-2-1', 8, <(PlayerPosition, double, double)>[
    (_g, 50, 7), // GB
    (_d, 18, 23), // DG
    (_d, 50, 23), // DC
    (_d, 82, 23), // DD
    (_m, 50, 40), // MDC
    (_m, 18, 57), // MG
    (_m, 82, 57), // MD
    (_a, 50, 78), // BU
  ]),
];

final List<Formation> _formations5 = _build(<String>[
  '2-2',
  '1-2-1',
  '2-1-1',
  '1-3',
  '3-1',
  '1-1-2',
], 5);

/// Compositions standards disponibles pour un nombre de joueurs donné.
List<Formation> standardFormations(int playerCount) {
  switch (playerCount) {
    case 8:
      return _formations8;
    case 5:
      return _formations5;
    case 11:
    default:
      return _formations11;
  }
}
