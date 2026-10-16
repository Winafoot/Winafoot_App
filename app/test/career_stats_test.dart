import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/career_stats.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/player_stats.dart';
// Les deux fichiers exportent une classe `StatDef` distincte.
import 'package:wina/models/stat_catalog.dart' as catalogue;

void main() {
  group('aggregateCareerStats', () {
    test('liste vide → table vide', () {
      expect(aggregateCareerStats(const <GameMatch>[]), isEmpty);
    });

    test('un match : reprend les valeurs telles quelles', () {
      final result = aggregateCareerStats(<GameMatch>[
        const GameMatch(
          playerStats: <String, Map<String, int>>{
            'p1': <String, int>{'butsMarques': 2, 'interceptions': 5},
          },
        ),
      ]);
      expect(result['p1']!['butsMarques'], 2);
      expect(result['p1']!['interceptions'], 5);
    });

    test('plusieurs matchs : cumule par joueur et par clé', () {
      final result = aggregateCareerStats(<GameMatch>[
        const GameMatch(
          playerStats: <String, Map<String, int>>{
            'p1': <String, int>{'butsMarques': 2, 'passesReussies': 10},
          },
        ),
        const GameMatch(
          playerStats: <String, Map<String, int>>{
            'p1': <String, int>{'butsMarques': 1, 'corners': 3},
          },
        ),
      ]);
      expect(result['p1']!['butsMarques'], 3); // 2 + 1
      expect(result['p1']!['passesReussies'], 10); // présent dans un seul match
      expect(result['p1']!['corners'], 3);
    });

    test('joueurs distincts restent séparés', () {
      final result = aggregateCareerStats(<GameMatch>[
        const GameMatch(
          playerStats: <String, Map<String, int>>{
            'p1': <String, int>{'butsMarques': 2},
            'p2': <String, int>{'butsMarques': 4},
          },
        ),
      ]);
      expect(result['p1']!['butsMarques'], 2);
      expect(result['p2']!['butsMarques'], 4);
    });

    // « Détail joueur » et « Tester l'équipe » lisent ce cumul par `readStat` :
    // les totaux se dérivent des composantes cumulées, sans total stocké.
    test('les totaux se dérivent du cumul des composantes', () {
      final result = aggregateCareerStats(<GameMatch>[
        const GameMatch(
          playerStats: <String, Map<String, int>>{
            'p1': <String, int>{
              'passesReussies': 8,
              'passesManquees': 2,
              'tirsBloques': 1,
            },
          },
        ),
        const GameMatch(
          playerStats: <String, Map<String, int>>{
            'p1': <String, int>{
              'passesReussies': 1,
              'passesManquees': 4,
              'tirsCadres': 3,
            },
          },
        ),
      ]);
      expect(catalogue.readStat(result['p1'], 'totalPasses'), 15);
      expect(catalogue.readStat(result['p1'], 'totalTirs'), 4);
      expect(catalogue.readStat(result['p1'], 'totalTirsSubis'), 0);
    });

    test('ne modifie pas les matchs en entrée', () {
      const match = GameMatch(
        playerStats: <String, Map<String, int>>{
          'p1': <String, int>{'butsMarques': 2},
        },
      );
      aggregateCareerStats(<GameMatch>[match, match]);
      // Les valeurs d'origine restent intactes (pas de mutation en place).
      expect(match.playerStats['p1']!['butsMarques'], 2);
    });
  });

  group('teamStatTotals', () {
    test('somme les stats de tous les joueurs par clé', () {
      const match = GameMatch(
        playerStats: <String, Map<String, int>>{
          'p1': <String, int>{'butsMarques': 2, 'passesReussies': 8},
          'p2': <String, int>{'butsMarques': 1, 'passesReussies': 2},
        },
      );
      final totals = teamStatTotals(match);
      expect(totals['butsMarques'], 3);
      expect(totals['passesReussies'], 10);
    });
  });

  group('collectifRows', () {
    // Aucun total ni pourcentage dans `playerStats` (le direct n'en écrit
    // jamais) : le bilan les dérive des composantes suivies.
    const match = GameMatch(
      enabledStatKeys: <String>[
        'butsMarques',
        'passesReussies',
        'passesManquees',
      ],
      playerStats: <String, Map<String, int>>{
        'p1': <String, int>{
          'butsMarques': 2,
          'passesReussies': 8,
          'passesManquees': 2,
          'interceptions': 0, // non activée, jamais saisie : pas de ligne
        },
        'p2': <String, int>{
          'butsMarques': 1,
          'passesReussies': 2,
          'passesManquees': 8,
        },
      },
    );

    test('ne garde que les statistiques activées', () {
      final labels = collectifRows(match).map((r) => r.label).toList();
      final String interception =
          catalogue.kStatCatalog.firstWhere((s) => s.key == 'interceptions').label;
      expect(labels, contains('Buts marqués'));
      expect(labels, isNot(contains(interception)));
    });

    test('ajoute Total passes et Réussite de passes dès que les deux composantes sont suivies', () {
      expect(
        collectifRows(match).map((r) => r.label),
        <String>[
          'Passes réussies',
          'Passes manquées',
          'Total passes',
          'Réussite de passes',
          'Buts marqués',
        ],
      );
    });

    test('calcule Total passes depuis les composantes', () {
      final rows = collectifRows(match);
      // (8 + 2) réussies + (2 + 8) manquées
      expect(rows.firstWhere((r) => r.label == 'Total passes').value, '20');
    });

    test('calcule le pourcentage de passes réussies sur les sommes', () {
      final rows = collectifRows(match);
      final pct = rows.firstWhere((r) => r.label == 'Réussite de passes');
      // (8 + 2) réussies / 20 passes = 50 %, 2 décimales, espace insécable
      expect(pct.value, '50,00\u00A0%');
    });

    test('une valeur stockée sous une clé calculée est ignorée', () {
      const stale = GameMatch(
        enabledStatKeys: <String>['passesReussies', 'passesManquees'],
        playerStats: <String, Map<String, int>>{
          'p1': <String, int>{
            'passesReussies': 3,
            'passesManquees': 1,
            'totalPasses': 999,
          },
        },
      );
      final rows = collectifRows(stale);
      expect(rows.firstWhere((r) => r.label == 'Total passes').value, '4');
    });

    test('aucune passe : la réussite vaut un tiret, pas 0,00 %', () {
      const rien = GameMatch(
        enabledStatKeys: <String>['passesReussies', 'passesManquees'],
      );
      final rows = collectifRows(rien);
      expect(rows.firstWhere((r) => r.label == 'Total passes').value, '0');
      expect(
        rows.firstWhere((r) => r.label == 'Réussite de passes').value,
        catalogue.kStatNoValue,
      );
    });

    test('une composante non suivie masque le total et le pourcentage', () {
      const partiel = GameMatch(
        enabledStatKeys: <String>['passesReussies'],
        playerStats: <String, Map<String, int>>{
          'p1': <String, int>{'passesReussies': 3},
        },
      );
      expect(collectifRows(partiel).map((r) => r.label), <String>[
        'Passes réussies',
      ]);
    });

    // Une stat suivie en 1re mi-temps puis désactivée en pause, ou activée à la
    // mi-temps d'un match d'avant le découpage, n'est plus (ou pas) dans
    // `enabledStatKeys` alors que ses valeurs sont réelles : elle reste affichée.
    test('une stat hors sélection mais saisie garde sa ligne', () {
      const GameMatch desactivee = GameMatch(
        enabledStatKeys: <String>['butsMarques'],
        playerStats: <String, Map<String, int>>{
          'p1': <String, int>{'butsMarques': 1, 'corners': 4},
        },
      );
      final rows = collectifRows(desactivee);
      expect(rows.firstWhere((r) => r.label == 'Corners obtenus').value, '4');
    });

    test('formate les totaux bruts en chaîne', () {
      final rows = collectifRows(match);
      final buts = rows.firstWhere((r) => r.label == 'Buts marqués');
      expect(buts.value, '3');
    });
  });

  // Chiffres du bilan collectif du client (1re mi-temps 69/23 passes, 2e 65/31),
  // répartis sur deux joueurs. `playerStats` est le TOTAL du match, la 2e mi-temps
  // s'en déduit : c'est le contrat de GameMatch.statsFor.
  group('collectifRows par période', () {
    const List<String> suivies = <String>[
      'passesReussies',
      'passesManquees',
      'tirsCadres',
      'tirsNonCadres',
      'tirsBloques',
    ];
    const Map<String, Map<String, int>> premiere = <String, Map<String, int>>{
      'p1': <String, int>{
        'passesReussies': 40,
        'passesManquees': 13,
        'tirsCadres': 3,
        'tirsNonCadres': 2,
      },
      'p2': <String, int>{
        'passesReussies': 29,
        'passesManquees': 10,
        'tirsCadres': 2,
      },
    };
    const Map<String, Map<String, int>> total = <String, Map<String, int>>{
      'p1': <String, int>{
        'passesReussies': 75,
        'passesManquees': 33,
        'tirsCadres': 4,
        'tirsNonCadres': 8,
        'tirsBloques': 2,
      },
      'p2': <String, int>{
        'passesReussies': 59,
        'passesManquees': 21,
        'tirsCadres': 2,
        'tirsNonCadres': 0,
        'tirsBloques': 1,
      },
    };
    const GameMatch match = GameMatch(
      enabledStatKeys: suivies,
      firstHalfStatKeys: suivies,
      firstHalfStats: premiere,
      playerStats: total,
      half: 2,
      status: MatchStatus.finished,
    );

    String valeur(List<CollectifRow> rows, String label) =>
        rows.firstWhere((CollectifRow r) => r.label == label).value;

    test('1re mi-temps : seules ses valeurs, totaux et % dérivés', () {
      final List<CollectifRow> rows = collectifRows(
        match,
        MatchPeriod.firstHalf,
      );
      expect(valeur(rows, 'Passes réussies'), '69');
      expect(valeur(rows, 'Passes manquées'), '23');
      expect(valeur(rows, 'Total passes'), '92');
      expect(valeur(rows, 'Réussite de passes'), '75,00\u00A0%');
      expect(valeur(rows, 'Total tirs'), '7');
    });

    test('2e mi-temps : total moins 1re mi-temps', () {
      final List<CollectifRow> rows = collectifRows(
        match,
        MatchPeriod.secondHalf,
      );
      expect(valeur(rows, 'Passes réussies'), '65');
      expect(valeur(rows, 'Passes manquées'), '31');
      expect(valeur(rows, 'Total passes'), '96');
      expect(valeur(rows, 'Réussite de passes'), '67,71\u00A0%');
      expect(valeur(rows, 'Total tirs'), '10');
    });

    test('Total match : le % vient des sommes, pas d\'une moyenne', () {
      final List<CollectifRow> rows = collectifRows(match);
      expect(valeur(rows, 'Passes réussies'), '134');
      expect(valeur(rows, 'Total passes'), '188');
      // 134 / 188 = 71,28 % ; la moyenne (75 + 67,71) / 2 donnerait 71,36.
      expect(valeur(rows, 'Réussite de passes'), '71,28\u00A0%');
      expect(valeur(rows, 'Total tirs'), '17');
      expect(collectifRows(match, MatchPeriod.total), rows);
    });

    test('une stat activée à la mi-temps n\'est pas suivie en 1re mi-temps', () {
      const GameMatch tard = GameMatch(
        enabledStatKeys: <String>['passesReussies', 'butsMarques'],
        firstHalfStatKeys: <String>['passesReussies'],
        firstHalfStats: <String, Map<String, int>>{
          'p1': <String, int>{'passesReussies': 2},
        },
        playerStats: <String, Map<String, int>>{
          'p1': <String, int>{'passesReussies': 5, 'butsMarques': 1},
        },
        half: 2,
      );
      List<String> labels(MatchPeriod p) =>
          collectifRows(tard, p).map((CollectifRow r) => r.label).toList();

      expect(labels(MatchPeriod.firstHalf), <String>['Passes réussies']);
      expect(labels(MatchPeriod.secondHalf), <String>[
        'Passes réussies',
        'Buts marqués',
      ]);
      expect(labels(MatchPeriod.total), <String>[
        'Passes réussies',
        'Buts marqués',
      ]);
    });

    test('2e mi-temps non jouée : les stats du match, toutes à un tiret', () {
      const GameMatch court = GameMatch(
        enabledStatKeys: <String>['passesReussies', 'passesManquees'],
        firstHalfStatKeys: <String>['passesReussies', 'passesManquees'],
        firstHalfStats: <String, Map<String, int>>{
          'p1': <String, int>{'passesReussies': 3, 'passesManquees': 1},
        },
        playerStats: <String, Map<String, int>>{
          'p1': <String, int>{'passesReussies': 3, 'passesManquees': 1},
        },
      );
      final List<CollectifRow> seconde = collectifRows(
        court,
        MatchPeriod.secondHalf,
      );

      expect(seconde.map((CollectifRow r) => r.label), <String>[
        'Passes réussies',
        'Passes manquées',
        'Total passes',
        'Réussite de passes',
      ]);
      expect(
        seconde.every((CollectifRow r) => r.value == catalogue.kStatNoValue),
        isTrue,
      );
      // Le Total, lui, reste juste.
      expect(valeur(collectifRows(court), 'Total passes'), '4');
    });

    test('match ancien : mi-temps sans ligne, Total consultable', () {
      const GameMatch ancien = GameMatch(
        enabledStatKeys: <String>['butsMarques'],
        playerStats: <String, Map<String, int>>{
          'p1': <String, int>{'butsMarques': 2},
        },
      );

      expect(collectifRows(ancien, MatchPeriod.firstHalf), isEmpty);
      expect(collectifRows(ancien, MatchPeriod.secondHalf), isEmpty);
      expect(valeur(collectifRows(ancien), 'Buts marqués'), '2');
    });
  });

  group('collectifBlocks', () {
    const GameMatch match = GameMatch(
      // Passes et tirs seulement : les 7 autres thèmes n'ont aucune stat suivie.
      enabledStatKeys: <String>[
        'tirsCadres',
        'tirsNonCadres',
        'tirsBloques',
        'passesReussies',
        'passesManquees',
      ],
      playerStats: <String, Map<String, int>>{
        'p1': <String, int>{'passesReussies': 3, 'tirsCadres': 1},
      },
    );

    test('un bloc par thème suivi, dans l\'ordre du catalogue', () {
      final List<CollectifBlock> blocks = collectifBlocks(match);

      expect(blocks.map((CollectifBlock b) => b.category), <catalogue.StatCategory>[
        catalogue.StatCategory.passes,
        catalogue.StatCategory.tirs,
      ]);
      expect(blocks.first.rows.map((CollectifRow r) => r.label), <String>[
        'Passes réussies',
        'Passes manquées',
        'Total passes',
        'Réussite de passes',
      ]);
      expect(blocks.last.rows.map((CollectifRow r) => r.label), <String>[
        'Tirs cadrés',
        'Tirs non cadrés',
        'Tirs bloqués',
        'Total tirs',
      ]);
    });

    test('aucune stat suivie : aucun bloc', () {
      expect(collectifBlocks(const GameMatch()), isEmpty);
    });
  });

  group('statKeyForLabel', () {
    test('résout un libellé connu vers sa clé', () {
      expect(statKeyForLabel('Buts marqués'), 'butsMarques');
      expect(statKeyForLabel('Interception de ballons'), 'interceptions');
      expect(statKeyForLabel('Total tirs'), 'totalTirs');
    });

    test('renvoie null pour un libellé inconnu', () {
      expect(statKeyForLabel('Libellé inexistant'), isNull);
    });

    test('chaque libellé de la page « Détail joueur » a une clé', () {
      for (final List<StatDef> column in kPlayerStatColumns) {
        for (final StatDef stat in column) {
          expect(
            statKeyForLabel(stat.label),
            isNotNull,
            reason: 'Libellé sans clé catalogue : "${stat.label}"',
          );
        }
      }
    });

    // Sens inverse du test précédent : ferme le trou « stat ajoutée au
    // catalogue mais jamais affichée ». Le lien entre les deux listes se fait
    // par le LIBELLÉ, et un écart d'accent ne lève aucune erreur — il affiche
    // simplement une cellule à 0.
    test('toute stat suivie du catalogue est affichée dans « Détail joueur »', () {
      final Set<String> affichees = <String>{
        for (final List<StatDef> column in kPlayerStatColumns)
          for (final StatDef stat in column) stat.label,
      };
      final Set<String> attendues = <String>{
        for (final catalogue.StatDef stat in catalogue.kStatCatalog)
          if (!stat.bilanOnly) stat.label,
      };
      expect(affichees, attendues);
    });
  });
}
