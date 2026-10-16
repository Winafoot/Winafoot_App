import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wina/models/formation.dart';

/// Composition tactique **personnalisée**, créée par le coach et réutilisable
/// entre les matchs. Persistée dans `users/{uid}/compositions`.
///
/// Contrairement à une composition *standard* (constante de l'app, cf.
/// `formation.dart`), elle porte un nom libre, un libellé de schéma libre et des
/// emplacements de maillots positionnés à la main sur le terrain.
@immutable
class CustomComposition {
  const CustomComposition({
    this.id,
    required this.name,
    required this.playerCount,
    required this.formationLabel,
    required this.slots,
    this.isFavorite = false,
    this.createdAt,
    this.lastUsedAt,
  });

  /// Identifiant du document Firestore. `null` tant que non persistée.
  final String? id;
  final String name;
  final int playerCount;
  final String formationLabel;
  final List<FormationSlot> slots;

  /// Composition marquée comme favorite (cœur plein, remontée en tête de liste).
  final bool isFavorite;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;

  CustomComposition copyWith({
    String? id,
    String? name,
    int? playerCount,
    String? formationLabel,
    List<FormationSlot>? slots,
    bool? isFavorite,
  }) {
    return CustomComposition(
      id: id ?? this.id,
      name: name ?? this.name,
      playerCount: playerCount ?? this.playerCount,
      formationLabel: formationLabel ?? this.formationLabel,
      slots: slots ?? this.slots,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt,
    );
  }

  /// Vue [Formation] de la composition, pour réutiliser l'aperçu terrain
  /// ([FormationPitch]) et l'écran de placement, qui raisonnent sur des
  /// [Formation].
  Formation toFormation() => Formation(
    label: formationLabel,
    playerCount: playerCount,
    slots: slots,
  );

  /// Champs persistés (id et horodatages sont gérés par le repository).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'type': 'custom',
    'playerCount': playerCount,
    'formationLabel': formationLabel,
    'isFavorite': isFavorite,
    'slots': <Map<String, dynamic>>[
      for (final FormationSlot s in slots)
        <String, dynamic>{'role': s.role.name, 'x': s.x, 'y': s.y},
    ],
  };

  /// Construit une composition depuis un document Firestore. Tolérant aux
  /// valeurs manquantes ou inconnues (valeurs par défaut sûres).
  factory CustomComposition.fromDoc(String id, Map<String, dynamic> json) {
    final List<dynamic> rawSlots =
        (json['slots'] as List<dynamic>?) ?? const <dynamic>[];
    final Object? createdAt = json['createdAt'];
    final Object? lastUsedAt = json['lastUsedAt'];
    return CustomComposition(
      id: id,
      name: (json['name'] as String?) ?? '',
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 11,
      formationLabel: (json['formationLabel'] as String?) ?? '',
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      slots: <FormationSlot>[
        for (final dynamic s in rawSlots)
          if (s is Map) FormationSlot.fromJson(s),
      ],
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      lastUsedAt: lastUsedAt is Timestamp ? lastUsedAt.toDate() : null,
    );
  }
}
