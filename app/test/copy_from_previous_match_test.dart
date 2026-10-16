import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/composition_providers.dart';

MatchComposition _comp({
  List<String?>? assignments,
  Map<String, int>? numbers,
  List<String>? substituteIds,
}) => MatchComposition(
  formationLabel: '4-4-2',
  playerCount: 3,
  slots: const <FormationSlot>[
    FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
    FormationSlot(role: PlayerPosition.defenseur, x: 0.5, y: 0.6),
    FormationSlot(role: PlayerPosition.attaquant, x: 0.5, y: 0.2),
  ],
  assignments: assignments ?? const <String?>['p1', 'p2', 'p3'],
  numbers: numbers ?? const <String, int>{'p1': 1, 'p2': 2, 'p3': 3, 'p4': 4},
  captainId: 'p2',
  substituteIds: substituteIds ?? const <String>['p4'],
  name: 'Ma Super Compo',
);

void main() {
  group('CompositionDraftNotifier.loadFromComposition', () {
    test('reconstruit le schéma, les placements, numéros, capitaine et '
        'remplaçants depuis une composition validée', () {
      final CompositionDraftNotifier n = CompositionDraftNotifier();
      n.loadFromComposition(_comp());

      expect(n.state.playerCount, 3);
      expect(n.state.formation?.label, '4-4-2');
      expect(n.state.formationName, 'Ma Super Compo');
      expect(n.state.assignments, <int, String>{0: 'p1', 1: 'p2', 2: 'p3'});
      expect(n.state.numbers, <String, int>{
        'p1': 1,
        'p2': 2,
        'p3': 3,
        'p4': 4,
      });
      expect(n.state.captainId, 'p2');
      expect(n.state.substituteIds, <String>{'p4'});
    });

    test('les emplacements non pourvus (null) ne sont pas ajoutés à la map '
        'de placements', () {
      final CompositionDraftNotifier n = CompositionDraftNotifier();
      n.loadFromComposition(_comp(assignments: <String?>['p1', null, 'p3']));

      expect(n.state.assignments, <int, String>{0: 'p1', 2: 'p3'});
      expect(n.state.placedCount, 2);
    });

    test('remplace intégralement un brouillon déjà en cours', () {
      final CompositionDraftNotifier n =
          CompositionDraftNotifier()
            ..setCount(11)
            ..setNumber('old', 7, isSubstitute: false)
            ..toggleCaptain('old');

      n.loadFromComposition(_comp());

      expect(n.state.numbers.containsKey('old'), isFalse);
      expect(n.state.captainId, 'p2');
      expect(n.state.playerCount, 3);
    });

    test('purge les numéros hors des deux grilles réunies', () {
      final CompositionDraftNotifier n = CompositionDraftNotifier();
      n.loadFromComposition(
        _comp(numbers: const <String, int>{'p1': 1, 'p2': 4, 'p3': 9, 'p4': 5}),
      );

      // playerCount = 3 : les deux grilles couvrent 1..8, le 9 de p3 sort.
      expect(n.state.numbers, <String, int>{'p1': 1, 'p2': 4, 'p4': 5});
    });

    test('garde le numéro d\'un remplaçant hérité de l\'ancien pool (1..N)', () {
      final CompositionDraftNotifier n = CompositionDraftNotifier();
      // Toutes les compositions déjà en base numérotent les remplaçants dans
      // 1..playerCount : ces numéros sont légitimes tant qu'aucun titulaire ne
      // les porte, les effacer laisserait le remplaçant maillot vide.
      n.loadFromComposition(
        _comp(numbers: const <String, int>{'p1': 1, 'p2': 3, 'p4': 2}),
      );

      expect(n.state.numbers, <String, int>{'p1': 1, 'p2': 3, 'p4': 2});
      expect(n.state.substituteIds, <String>{'p4'});
    });

    test('garde le numéro d\'un remplaçant entré en jeu (sorti du banc)', () {
      final CompositionDraftNotifier n = CompositionDraftNotifier();
      // `LiveMatchNotifier.substitute` retire l'entrant de `substituteIds` en
      // lui laissant son numéro de pool remplaçant : au rechargement de
      // « Modifier composition », ce numéro ne doit pas être purgé.
      n.loadFromComposition(
        _comp(
          numbers: const <String, int>{'p1': 1, 'p2': 5},
          substituteIds: const <String>[],
        ),
      );

      expect(n.state.numbers, <String, int>{'p1': 1, 'p2': 5});
    });

    test('le statut remplaçant suit le pool du numéro', () {
      final CompositionDraftNotifier n = CompositionDraftNotifier();
      // Même situation que ci-dessus, vue depuis « Attribuez les numéros » :
      // p2 porte le 5, au-dessus des 3 titulaires, donc un numéro de la grille
      // des remplaçants. Sans dérivation il revenait en maillot d'ÉQUIPE alors
      // que le 5 restait grisé dans la grille des remplaçants — les deux
      // anomalies signalées par le client.
      n.loadFromComposition(
        _comp(
          numbers: const <String, int>{'p1': 1, 'p2': 5},
          substituteIds: const <String>[],
        ),
      );

      expect(n.state.substituteIds, contains('p2'));
      // Le titulaire, lui, ne bascule pas.
      expect(n.state.substituteIds, isNot(contains('p1')));
    });

    test('un remplaçant hérité numéroté dans la plage titulaire reste au banc', () {
      final CompositionDraftNotifier n = CompositionDraftNotifier();
      // Compositions d'avant le pool contigu : le numéro tient dans
      // 1..playerCount, c'est `substituteIds` qui fait foi. Ne pas le déclasser.
      n.loadFromComposition(
        _comp(
          numbers: const <String, int>{'p1': 1, 'p4': 2},
          substituteIds: const <String>['p4'],
        ),
      );

      expect(n.state.substituteIds, <String>{'p4'});
    });

    test('purge le numéro d\'un remplaçant qui doublonne un titulaire', () {
      final CompositionDraftNotifier n = CompositionDraftNotifier();
      // Doublon déjà en base (écrit par un build antérieur à l'unicité
      // globale) : sans la purge, « Copier depuis un match précédent » le
      // ferait revenir intact. Le titulaire garde le numéro ; le remplaçant le
      // perd, donc sort aussi du bloc « Remplaçants » (sinon il réapparaîtrait
      // maillot vide en match).
      n.loadFromComposition(
        _comp(numbers: const <String, int>{'p1': 1, 'p4': 1}),
      );

      expect(n.state.numbers, <String, int>{'p1': 1});
      expect(n.state.substituteIds, isNot(contains('p4')));
    });
  });
}
