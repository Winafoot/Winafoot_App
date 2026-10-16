import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';

MatchComposition _comp(String label, {String? name}) => MatchComposition(
  formationLabel: label,
  playerCount: 3,
  slots: const <FormationSlot>[
    FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
    FormationSlot(role: PlayerPosition.defenseur, x: 0.5, y: 0.6),
    FormationSlot(role: PlayerPosition.attaquant, x: 0.5, y: 0.2),
  ],
  assignments: const <String?>['p1', 'p2', 'p3'],
  numbers: const <String, int>{'p1': 1, 'p2': 4, 'p3': 9},
  captainId: 'p2',
  substituteIds: const <String>['p4'],
  name: name,
);

void main() {
  group('GameMatch.compositionsUsed', () {
    test('retombe sur l\'unique composition quand la liste est vide', () {
      final GameMatch m = GameMatch(composition: _comp('4-4-2'));
      expect(m.compositionsUsed.map((MatchComposition c) => c.formationLabel),
          <String>['4-4-2']);
      expect(m.hasMultipleCompositions, isFalse);
    });

    test('utilise la liste quand plusieurs compositions ont servi', () {
      final GameMatch m = GameMatch(
        composition: _comp('4-4-2'),
        compositions: <MatchComposition>[
          _comp('4-4-1-1'),
          _comp('4-2-3-1', name: 'Ma Super Compo 2'),
        ],
      );
      expect(m.compositionsUsed.length, 2);
      expect(m.compositionsUsed.map((MatchComposition c) => c.formationLabel),
          <String>['4-4-1-1', '4-2-3-1']);
      expect(m.compositionsUsed[1].name, 'Ma Super Compo 2');
      expect(m.hasMultipleCompositions, isTrue);
    });

    test('liste vide quand aucune composition', () {
      const GameMatch m = GameMatch();
      expect(m.compositionsUsed, isEmpty);
      expect(m.hasMultipleCompositions, isFalse);
    });
  });

  group('Sérialisation', () {
    test('MatchComposition conserve le nom (toJson → fromJson)', () {
      final MatchComposition c = _comp('4-2-3-1', name: 'Ma Super Compo 2');
      final MatchComposition back = MatchComposition.fromJson(c.toJson());
      expect(back.name, 'Ma Super Compo 2');
      expect(back.formationLabel, '4-2-3-1');
      expect(back.captainId, 'p2');
    });

    test('nom null pour un schéma standard', () {
      final MatchComposition back = MatchComposition.fromJson(_comp('4-4-2').toJson());
      expect(back.name, isNull);
    });

    test('GameMatch round-trip préserve la liste des compositions', () {
      final GameMatch m = GameMatch(
        composition: _comp('4-4-1-1'),
        compositions: <MatchComposition>[
          _comp('4-4-1-1'),
          _comp('4-2-3-1', name: 'Ma Super Compo 2'),
        ],
      );
      final GameMatch back = GameMatch.fromDoc('id1', m.toJson());
      expect(back.compositions.length, 2);
      expect(back.compositionsUsed.map((MatchComposition c) => c.formationLabel),
          <String>['4-4-1-1', '4-2-3-1']);
      expect(back.compositions[1].name, 'Ma Super Compo 2');
      expect(back.hasMultipleCompositions, isTrue);
    });

    test('GameMatch sans liste n\'écrit pas le champ compositions', () {
      final GameMatch m = GameMatch(composition: _comp('4-4-2'));
      expect(m.toJson().containsKey('compositions'), isFalse);
      final GameMatch back = GameMatch.fromDoc('id2', m.toJson());
      expect(back.compositions, isEmpty);
      expect(back.compositionsUsed.single.formationLabel, '4-4-2');
    });
  });
}
