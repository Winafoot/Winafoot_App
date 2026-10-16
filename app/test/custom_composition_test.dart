import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/custom_composition.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/player.dart';

void main() {
  group('CustomComposition', () {
    const CustomComposition compo = CustomComposition(
      name: 'Ma Super Compo',
      playerCount: 11,
      formationLabel: '4-4-1-1',
      slots: <FormationSlot>[
        FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
        FormationSlot(role: PlayerPosition.defenseur, x: 0.2, y: 0.7),
        FormationSlot(role: PlayerPosition.attaquant, x: 0.5, y: 0.2),
      ],
    );

    test('toJson sérialise nom, type custom, schéma et emplacements', () {
      final Map<String, dynamic> json = compo.toJson();
      expect(json['name'], 'Ma Super Compo');
      expect(json['type'], 'custom');
      expect(json['playerCount'], 11);
      expect(json['formationLabel'], '4-4-1-1');
      expect((json['slots'] as List<dynamic>).length, 3);
      expect((json['slots'] as List<dynamic>).first, <String, dynamic>{
        'role': 'gardien',
        'x': 0.5,
        'y': 0.9,
      });
    });

    test('fromDoc reconstruit la composition (avec createdAt Timestamp)', () {
      final Map<String, dynamic> json = <String, dynamic>{
        ...compo.toJson(),
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 29, 12)),
      };
      final CustomComposition parsed = CustomComposition.fromDoc('id1', json);
      expect(parsed.id, 'id1');
      expect(parsed.name, 'Ma Super Compo');
      expect(parsed.playerCount, 11);
      expect(parsed.formationLabel, '4-4-1-1');
      expect(parsed.slots.length, 3);
      expect(parsed.slots[1].role, PlayerPosition.defenseur);
      expect(parsed.slots[1].x, 0.2);
      expect(parsed.createdAt, DateTime(2026, 4, 29, 12));
    });

    test('round-trip toJson → fromDoc préserve les emplacements', () {
      final CustomComposition parsed = CustomComposition.fromDoc(
        'id2',
        compo.toJson(),
      );
      expect(parsed.slots, compo.slots);
    });

    test('fromDoc tolère un document incomplet', () {
      final CustomComposition parsed = CustomComposition.fromDoc(
        'id3',
        <String, dynamic>{},
      );
      expect(parsed.name, '');
      expect(parsed.playerCount, 11);
      expect(parsed.formationLabel, '');
      expect(parsed.slots, isEmpty);
      expect(parsed.createdAt, isNull);
    });

    test('toFormation expose une Formation équivalente', () {
      final Formation f = compo.toFormation();
      expect(f.label, '4-4-1-1');
      expect(f.playerCount, 11);
      expect(f.slots, compo.slots);
    });

    test('isFavorite est sérialisé puis relu', () {
      final CustomComposition fav = compo.copyWith(isFavorite: true);
      expect(fav.toJson()['isFavorite'], true);
      final CustomComposition parsed = CustomComposition.fromDoc(
        'id4',
        fav.toJson(),
      );
      expect(parsed.isFavorite, true);
    });

    test('isFavorite vaut false par défaut (document sans le champ)', () {
      final CustomComposition parsed = CustomComposition.fromDoc(
        'id5',
        <String, dynamic>{'name': 'X', 'playerCount': 8},
      );
      expect(parsed.isFavorite, false);
    });

    test('copyWith modifie les champs ciblés et garde les autres', () {
      final CustomComposition base = compo.copyWith(id: 'doc1');
      final CustomComposition edited = base.copyWith(
        name: 'Renommée',
        formationLabel: '4-3-3',
      );
      expect(edited.id, 'doc1');
      expect(edited.name, 'Renommée');
      expect(edited.formationLabel, '4-3-3');
      expect(edited.playerCount, base.playerCount);
      expect(edited.slots, base.slots);
      expect(edited.isFavorite, base.isFavorite);
    });
  });
}
