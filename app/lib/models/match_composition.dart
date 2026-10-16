import 'package:flutter/foundation.dart';
import 'package:wina/models/formation.dart';

/// Composition validée d'un match : schéma tactique + joueurs placés sur chaque
/// emplacement (titulaires), capitaine et remplaçants.
@immutable
class MatchComposition {
  const MatchComposition({
    required this.formationLabel,
    required this.playerCount,
    required this.slots,
    required this.assignments,
    this.numbers = const <String, int>{},
    this.captainId,
    this.substituteIds = const <String>[],
    this.name,
  });

  final String formationLabel;
  final int playerCount;

  /// Nom de la composition personnalisée (`null` pour un schéma standard).
  /// Affiché dans la colonne « Compositions utilisées » des statistiques.
  final String? name;

  /// Emplacements du schéma (ordonnés : gardien, défenseurs, milieux, attaquants).
  final List<FormationSlot> slots;

  /// Identifiant du joueur placé sur chaque emplacement (`null` = vide). Même
  /// longueur que [slots].
  final List<String?> assignments;

  /// Numéro de maillot attribué à chaque joueur : playerId → numéro.
  final Map<String, int> numbers;

  final String? captainId;
  final List<String> substituteIds;

  int get placedCount => assignments.where((String? a) => a != null).length;

  bool get isComplete => slots.isNotEmpty && placedCount == slots.length;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'formationLabel': formationLabel,
    'playerCount': playerCount,
    'slots': <Map<String, dynamic>>[
      for (final FormationSlot s in slots)
        <String, dynamic>{'role': s.role.name, 'x': s.x, 'y': s.y},
    ],
    'assignments': assignments,
    'numbers': numbers,
    'captainId': captainId,
    'substituteIds': substituteIds,
    'name': name,
  };

  factory MatchComposition.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSlots =
        (json['slots'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> rawAssign =
        (json['assignments'] as List<dynamic>?) ?? const <dynamic>[];
    return MatchComposition(
      formationLabel: (json['formationLabel'] as String?) ?? '',
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 0,
      slots: <FormationSlot>[
        for (final dynamic s in rawSlots)
          if (s is Map) FormationSlot.fromJson(s),
      ],
      assignments: <String?>[
        for (final dynamic a in rawAssign) a is String ? a : null,
      ],
      numbers: <String, int>{
        for (final MapEntry<dynamic, dynamic> e
            in ((json['numbers'] as Map<dynamic, dynamic>?) ??
                    const <dynamic, dynamic>{})
                .entries)
          if (e.key is String)
            e.key as String: (e.value as num?)?.toInt() ?? 0,
      },
      captainId: json['captainId'] as String?,
      substituteIds:
          ((json['substituteIds'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
      name: json['name'] as String?,
    );
  }
}
