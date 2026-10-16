import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/custom_composition.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';

/// Documents Firestore malformés : le parsing doit dégrader proprement plutôt
/// que lever, sinon une seule ligne corrompue casse tout le stream Riverpod.
void main() {
  const Map<String, dynamic> validSlot = <String, dynamic>{
    'role': 'gardien',
    'x': 0.5,
    'y': 0.9,
  };

  group('CustomComposition.fromDoc dégradé', () {
    test('horodatage de mauvais type → null', () {
      final CustomComposition parsed = CustomComposition.fromDoc(
        'id',
        <String, dynamic>{
          'createdAt': '2026-04-29',
          'lastUsedAt': 1714388400000,
        },
      );
      expect(parsed.createdAt, isNull);
      expect(parsed.lastUsedAt, isNull);
    });

    test('emplacement non-Map ignoré, les valides sont conservés', () {
      final CustomComposition parsed = CustomComposition.fromDoc(
        'id',
        <String, dynamic>{
          'slots': <dynamic>['cassé', null, validSlot],
        },
      );
      expect(parsed.slots.length, 1);
      expect(parsed.slots.single.role, PlayerPosition.gardien);
    });
  });

  group('MatchComposition.fromJson dégradé', () {
    test('slot non-Map, numéro null, remplaçant null, assignation non-String', () {
      final MatchComposition parsed = MatchComposition.fromJson(
        <String, dynamic>{
          'slots': <dynamic>[42, validSlot],
          'assignments': <dynamic>['p1', 7, null],
          'numbers': <dynamic, dynamic>{'p1': null, 'p2': 9},
          'substituteIds': <dynamic>[null, 'p3'],
        },
      );
      expect(parsed.slots.length, 1);
      expect(parsed.assignments, <String?>['p1', null, null]);
      expect(parsed.numbers, <String, int>{'p1': 0, 'p2': 9});
      expect(parsed.substituteIds, <String>['p3']);
    });
  });

  group('GameMatch.fromDoc dégradé', () {
    test('clé de stat null et valeur de stat null ne lèvent pas', () {
      final GameMatch parsed = GameMatch.fromDoc('m1', <String, dynamic>{
        'enabledStatKeys': <dynamic>['but', null, 3],
        'playerStats': <dynamic, dynamic>{
          'p1': <dynamic, dynamic>{'but': null, 'passe': 2},
          'p2': 'pas une map',
        },
      });
      expect(parsed.enabledStatKeys, <String>['but']);
      expect(parsed.playerStats, <String, Map<String, int>>{
        'p1': <String, int>{'but': 0, 'passe': 2},
      });
    });

    test('composition non-Map dans compositions ignorée', () {
      final GameMatch parsed = GameMatch.fromDoc('m2', <String, dynamic>{
        'compositions': <dynamic>[
          'cassé',
          <String, dynamic>{
            'formationLabel': '4-4-2',
            'slots': <dynamic>[validSlot],
          },
        ],
      });
      expect(parsed.compositions.length, 1);
      expect(parsed.compositions.single.formationLabel, '4-4-2');
    });

    test('ancien document sans découpage : firstHalfStats null, mi-temps 1', () {
      final GameMatch parsed = GameMatch.fromDoc('m5', <String, dynamic>{
        'playerStats': <String, dynamic>{
          'p1': <String, dynamic>{'but': 1},
        },
      });
      expect(parsed.firstHalfStats, isNull);
      expect(parsed.firstHalfStatKeys, isEmpty);
      expect(parsed.half, 1);
    });

    test('carte de 1re mi-temps vide ≠ champ absent', () {
      final GameMatch parsed = GameMatch.fromDoc('m6', <String, dynamic>{
        'firstHalfStats': <String, dynamic>{},
      });
      expect(parsed.firstHalfStats, isNotNull);
      expect(parsed.firstHalfStats, isEmpty);
    });

    test('découpage mal formé : ignoré ou lu à 0, jamais de levée', () {
      final GameMatch parsed = GameMatch.fromDoc('m7', <String, dynamic>{
        'half': 'deux',
        'playerStats': 'cassé',
        'firstHalfStats': <dynamic, dynamic>{
          'p1': <dynamic, dynamic>{'but': null, 'passe': 'x', 'ok': 2, 3: 1},
          'p2': 'pas une map',
          4: <dynamic, dynamic>{'but': 1},
        },
        'firstHalfStatKeys': <dynamic>['but', null, 3],
      });
      expect(parsed.half, 1);
      expect(parsed.playerStats, isEmpty);
      expect(parsed.firstHalfStats, <String, Map<String, int>>{
        'p1': <String, int>{'but': 0, 'passe': 0, 'ok': 2},
      });
      expect(parsed.firstHalfStatKeys, <String>['but']);
    });

    test('firstHalfStats ni Map ni absent → null, firstHalfStatKeys non-liste', () {
      final GameMatch parsed = GameMatch.fromDoc('m8', <String, dynamic>{
        'firstHalfStats': <dynamic>['cassé'],
        'firstHalfStatKeys': 'cassé',
      });
      expect(parsed.firstHalfStats, isNull);
      expect(parsed.firstHalfStatKeys, isEmpty);
    });

    test('createdAt est relu depuis le document', () {
      final DateTime at = DateTime(2026, 4, 29, 12);
      final GameMatch parsed = GameMatch.fromDoc('m3', <String, dynamic>{
        'createdAt': Timestamp.fromDate(at),
      });
      expect(parsed.createdAt, at);
    });

    test('createdAt de mauvais type → null', () {
      final GameMatch parsed = GameMatch.fromDoc('m4', <String, dynamic>{
        'createdAt': 1714388400000,
      });
      expect(parsed.createdAt, isNull);
    });
  });

  // Les `name` d'enum sont le contrat de données (écrits tels quels dans
  // `users/{uid}` et dans l'adversaire de chaque match) : en retirer ou
  // renommer un rendrait leurs valeurs illisibles sans aucune erreur.
  group('TeamCategory / TeamDivision hérités', () {
    const List<String> categories = <String>[
      'seniors',
      'u19',
      'u17',
      'u15',
      'u13',
      'veterans',
    ];
    const List<String> divisions = <String>['d1', 'd2', 'd3', 'd4'];

    test('les noms historiques restent lisibles (profil coach)', () {
      for (final String n in categories) {
        expect(
          CoachProfile.fromJson(<String, dynamic>{'category': n}).category,
          isNotNull,
          reason: 'catégorie $n',
        );
      }
      for (final String n in divisions) {
        expect(
          CoachProfile.fromJson(<String, dynamic>{'division': n}).division,
          isNotNull,
          reason: 'division $n',
        );
      }
    });

    test("les noms historiques restent lisibles (adversaire d'un match)", () {
      final MatchOpponent parsed = MatchOpponent.fromJson(<String, dynamic>{
        'category': 'u13',
        'division': 'd4',
      });
      expect(parsed.category, TeamCategory.u13);
      expect(parsed.division, TeamDivision.d4);
    });

    test('valeur inconnue → null', () {
      final CoachProfile parsed = CoachProfile.fromJson(<String, dynamic>{
        'category': 'u99',
        'division': 'zz',
      });
      expect(parsed.category, isNull);
      expect(parsed.division, isNull);
    });
  });
}
