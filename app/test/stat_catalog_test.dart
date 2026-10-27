import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/career_stats.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/live_match_providers.dart';

/// Catalogue des 33 statistiques (9 thèmes du client) et calcul unique des 5
/// statistiques calculées (`readStat`, `formatPercent`, visibilité).
void main() {
  // « X % » avec l'espace insécable du format.
  String pct(String v) => '$v %';

  group('catalogue', () {
    test('33 statistiques : 28 saisies (bascules) + 5 calculées', () {
      expect(kStatCatalog, hasLength(33));
      expect(kStatToggles, hasLength(28));
      expect(
        kStatCatalog.where((StatDef s) => s.isCalculated).map((s) => s.key),
        <String>[
          'totalPasses',
          'pourcentagePasses',
          'totalTirs',
          'nombreCentres',
          'totalTirsSubis',
        ],
      );
    });

    test('clés uniques ; les 30 clés historiques encore au catalogue sont conservées', () {
      final List<String> keys = <String>[
        for (final StatDef s in kStatCatalog) s.key,
      ];
      expect(keys.toSet(), hasLength(33));
      // Clés persistées dans `playerStats` / `enabledStatKeys` : n'en renommer
      // aucune (les libellés, eux, changent librement).
      const List<String> historiques = <String>[
        'recuperations',
        'passesReussies',
        'passesManquees',
        'totalPasses',
        'pourcentagePasses',
        'pertesBallons',
        'tirsCadres',
        'tirsNonCadres',
        'passesDecisives',
        'butsMarques',
        'butsSubis',
        'arretsGardien',
        'tirsSubisHors',
        'tirsSubisDans',
        'totalTirsSubis',
        'controleReussi',
        'controleManque',
        'horsJeu',
        'duelsAeriens',
        'duelsAeriensPerdus',
        'penaltysSubis',
        'penaltysCrees',
        'nombreCentres',
        'passesProfondeur',
        'centresReussis',
        'centresRates',
        'fautesCommises',
        'fautesSubies',
        'cartonsJaunes',
        'cartonsRouges',
      ];
      expect(historiques, hasLength(30));
      expect(keys, containsAll(historiques));
      expect(keys.toSet().difference(historiques.toSet()), <String>{
        'totalTirs',
        'duelsGagnes',
        'duelsPerdus',
      });
    });

    test('9 thèmes du client, contigus et dans l\'ordre de l\'enum', () {
      expect(StatCategory.values.map((StatCategory c) => c.label), <String>[
        'Statistiques passes',
        "Statistiques d'efficacité",
        'Statistiques tirs',
        'Statistiques offensives',
        'Coups de pied arrêtés',
        'Fautes et sanctions',
        'Gardien et défense',
        'Technique',
        'Duels et actions spéciales',
      ]);
      // Même regroupement en « runs » que `_StatGrid` (écran live) : un thème
      // coupé en deux donnerait deux cartes.
      final List<StatCategory> runs = <StatCategory>[];
      for (final StatDef s in kStatCatalog) {
        if (runs.isEmpty || runs.last != s.category) runs.add(s.category);
      }
      expect(runs, StatCategory.values);
    });

    test('libellés et ordre du mail du client', () {
      expect(kStatCatalog.map((StatDef s) => s.label), <String>[
        'Passes réussies',
        'Passes manquées',
        'Total passes',
        'Réussite de passes',
        'Passes en profondeur',
        'Récupérations de ballons',
        'Tirs cadrés',
        'Tirs non cadrés',
        'Total tirs',
        'Passes décisives',
        'Buts marqués',
        'Centres réussis',
        'Centres manqués',
        'Nombre de centres',
        'Penaltys obtenus',
        'Penaltys subis',
        'Fautes commises',
        'Fautes subies',
        'Cartons jaunes',
        'Cartons rouges',
        'Hors-jeu',
        'Buts subis',
        'Arrêts du gardien',
        'Tirs subis hors de la surface',
        'Tirs subis dans la surface',
        'Total tirs subis',
        'Contrôles réussis',
        'Contrôles manqués',
        'Pertes de ballons',
        'Duels aériens gagnés',
        'Duels aériens perdus',
        'Duels gagnés',
        'Duels perdus',
      ]);
    });

    // Le bilan individuel est en Helvetica (Type1) : pas de glyphe au-delà de
    // U+00FF, donc pas de « ’ » (blanc en release), apostrophe droite. Le tiret
    // « — » n'en fait pas partie : il ne sert que dans le bilan collectif, en
    // Poppins.
    test('libellés et thèmes dessinables par Helvetica (PDF individuel)', () {
      final Iterable<String> textes = <String>[
        for (final StatDef s in kStatCatalog) s.label,
        for (final StatCategory c in StatCategory.values) c.label,
        formatPercent(1, 3),
      ];
      for (final String t in textes) {
        expect(t.runes.every((int r) => r <= 0xFF), isTrue, reason: t);
      }
    });

    test('les composantes d\'une calculée sont des stats saisies', () {
      // Sans quoi une calculée dépendrait d'une autre calculée (récursion
      // absente de `readStat`) ou d'une clé qui n'existe pas.
      final Set<String> saisies = <String>{
        for (final StatDef s in kStatToggles) s.key,
      };
      for (final StatDef s in kStatCatalog.where((s) => s.isCalculated)) {
        expect(saisies, containsAll(s.parts), reason: s.key);
      }
    });
  });

  group('readStat', () {
    // Valeurs du bilan collectif du client (1re mi-temps / 2e / total).
    const Map<String, int> mt1 = <String, int>{
      'passesReussies': 69,
      'passesManquees': 23,
      'tirsCadres': 5,
      'tirsNonCadres': 2,
      'centresReussis': 3,
      'centresRates': 4,
      'tirsSubisHors': 2,
      'tirsSubisDans': 3,
    };
    const Map<String, int> mt2 = <String, int>{
      'passesReussies': 65,
      'passesManquees': 31,
      'tirsCadres': 1,
      'tirsNonCadres': 6,
    };
    final Map<String, int> total = <String, int>{
      for (final String k in <String>{...mt1.keys, ...mt2.keys})
        k: (mt1[k] ?? 0) + (mt2[k] ?? 0),
    };

    test('Total passes = réussies + manquées', () {
      expect(readStat(mt1, 'totalPasses'), 92);
      expect(readStat(mt2, 'totalPasses'), 96);
      expect(readStat(total, 'totalPasses'), 188);
    });

    test('Total tirs = cadrés + non cadrés', () {
      expect(readStat(mt1, 'totalTirs'), 7);
      expect(readStat(mt2, 'totalTirs'), 7);
      expect(readStat(total, 'totalTirs'), 14);
    });

    test('Nombre de centres = réussis + manqués', () {
      expect(readStat(mt1, 'nombreCentres'), 7);
      expect(readStat(<String, int>{'centresReussis': 2}, 'nombreCentres'), 2);
    });

    test('Total tirs subis = hors surface + dans la surface', () {
      expect(readStat(mt1, 'totalTirsSubis'), 5);
    });

    test(
      'une stat saisie est lue telle quelle, 0 si absente ou sans données',
      () {
        expect(readStat(mt1, 'passesReussies'), 69);
        expect(readStat(mt1, 'butsMarques'), 0);
        expect(readStat(null, 'passesReussies'), 0);
        expect(readStat(null, 'totalPasses'), 0);
        expect(readStat(mt1, 'cle-inconnue'), 0);
      },
    );

    test('la valeur stockée sous une clé calculée est ignorée', () {
      const Map<String, int> ancien = <String, int>{
        'totalPasses': 999,
        'totalTirs': 999,
        'nombreCentres': 999,
        'totalTirsSubis': 999,
        'passesReussies': 1,
        'passesManquees': 1,
      };
      expect(readStat(ancien, 'totalPasses'), 2);
      expect(readStat(ancien, 'totalTirs'), 0);
      expect(readStat(ancien, 'nombreCentres'), 0);
      expect(readStat(ancien, 'totalTirsSubis'), 0);
    });
  });

  group('formatPercent', () {
    test('valeurs du bilan client : 2 décimales, virgule, arrondi', () {
      expect(formatPercent(69, 92), pct('75,00'));
      expect(formatPercent(65, 96), pct('67,71'));
      expect(formatPercent(134, 188), pct('71,28'));
    });

    test('Total match : somme des composantes puis %, pas moyenne', () {
      // Moyenne des deux mi-temps : (75,00 + 67,71) / 2 = 71,35 ≠ 71,28.
      expect(formatPercent(69 + 65, 92 + 96), pct('71,28'));
    });

    test('demi vers le haut, exact en entier', () {
      // 23/160 = 14,375 % ; `toStringAsFixed(2)` donnerait 14,37.
      expect(formatPercent(23, 160), pct('14,38'));
    });

    test('bornes : 0 %, 100 %', () {
      expect(formatPercent(0, 10), pct('0,00'));
      expect(formatPercent(10, 10), pct('100,00'));
    });

    test('aucune passe : tiret cadratin, pas 0,00 %', () {
      expect(formatPercent(0, 0), kStatNoValue);
      expect(kStatNoValue, '—');
    });
  });

  group('formatStat', () {
    StatDef def(String key) => kStatCatalog.firstWhere((s) => s.key == key);
    const Map<String, int> joueur = <String, int>{
      'passesReussies': 69,
      'passesManquees': 23,
      // Valeur d'un ancien match : ignorée au profit des composantes.
      'totalPasses': 999,
    };

    test('saisie : le nombre ; total : dérivé des composantes', () {
      expect(formatStat(joueur, def('passesReussies')), '69');
      expect(formatStat(joueur, def('totalPasses')), '92');
      expect(formatStat(joueur, def('butsMarques')), '0');
    });

    test('% de passes : au format du bilan, calculé sur les composantes', () {
      expect(formatStat(joueur, def('pourcentagePasses')), pct('75,00'));
    });

    test('aucune passe (ou aucun compteur) : tiret, jamais 0,00 %', () {
      expect(formatStat(null, def('pourcentagePasses')), kStatNoValue);
      expect(
        formatStat(const <String, int>{'tirsCadres': 2}, def('pourcentagePasses')),
        kStatNoValue,
      );
    });
  });

  group('visibilité des calculées', () {
    List<String> suivies(Iterable<String> keys) => <String>[
      for (final StatDef s in enabledStatsInCatalogOrder(keys)) s.key,
    ];

    test(
      'Total passes et Réussite de passes : les deux composantes suivies',
      () {
        expect(suivies(<String>['passesReussies']), <String>['passesReussies']);
        expect(suivies(<String>['passesManquees']), <String>['passesManquees']);
        expect(suivies(<String>['passesManquees', 'passesReussies']), <String>[
          'passesReussies',
          'passesManquees',
          'totalPasses',
          'pourcentagePasses',
        ]);
      },
    );

    test('Total tirs : une seule composante ne suffit pas', () {
      expect(suivies(<String>['tirsCadres']), <String>['tirsCadres']);
      expect(
        suivies(<String>['tirsCadres', 'tirsNonCadres']),
        contains('totalTirs'),
      );
    });

    test(
      'la clé d\'une calculée dans le stockage ne suffit pas (ancien match)',
      () {
        expect(
          suivies(<String>['totalPasses', 'nombreCentres', 'totalTirsSubis']),
          isEmpty,
        );
      },
    );

    test(
      'la clé stockée en plus ne change rien quand les composantes suivent',
      () {
        expect(
          suivies(<String>['passesReussies', 'passesManquees', 'totalPasses']),
          suivies(<String>['passesReussies', 'passesManquees']),
        );
      },
    );
  });

  group('défauts', () {
    test('aucune calculée stockée, toutes leurs composantes activées', () {
      final List<String> defauts = defaultEnabledStatKeys();
      final Set<String> calculees = <String>{
        for (final StatDef s in kStatCatalog)
          if (s.isCalculated) s.key,
      };
      expect(defauts.toSet().intersection(calculees), isEmpty);
      expect(
        defauts,
        containsAll(<String>[
          'passesReussies',
          'passesManquees',
          'tirsCadres',
          'tirsNonCadres',
          'centresReussis',
          'centresRates',
          'tirsSubisHors',
          'tirsSubisDans',
        ]),
      );
      // Défauts d'avant, hors calculées, toujours activés.
      expect(defauts, containsAll(<String>['recuperations', 'fautesCommises']));
      expect(defauts, hasLength(19));
    });

    test('avec les défauts, les 5 calculées sont visibles', () {
      final Set<String> visibles = <String>{
        for (final StatDef s in enabledStatsInCatalogOrder(
          defaultEnabledStatKeys(),
        ))
          s.key,
      };
      expect(
        visibles,
        containsAll(<String>[
          'totalPasses',
          'pourcentagePasses',
          'totalTirs',
          'nombreCentres',
          'totalTirsSubis',
        ]),
      );
    });
  });

  // Régression B1 : les totaux ne vivaient que dans l'écran live ; le bilan
  // collectif, le tableau, les PDF et « Détail joueur » lisaient 0. Ici, des
  // `playerStats` produits par `bump` (donc sans aucun total stocké).
  group('toggleKeys', () {
    test('garde les bascules dans l\'ordre, écarte calculées et inconnues', () {
      expect(
        toggleKeys(<String>[
          'totalPasses',
          'tirsCadres',
          'pourcentagePasses',
          'cleInconnue',
          'passesReussies',
          'nombreCentres',
        ]),
        <String>['tirsCadres', 'passesReussies'],
      );
    });

    test('les 4 clés calculées des anciens défauts ne comptent pas', () {
      // Anciens matchs : `enabledStatKeys` portait aussi 4 clés calculées.
      final List<String> anciens = <String>[
        ...defaultEnabledStatKeys(),
        'totalPasses',
        'pourcentagePasses',
        'totalTirsSubis',
        'nombreCentres',
      ];
      expect(toggleKeys(anciens), defaultEnabledStatKeys());
    });
  });

  test('des stats saisies au direct donnent des totaux dans le bilan', () {
    final LiveMatchNotifier n =
        LiveMatchNotifier()..start(
          const GameMatch().copyWith(
            composition: const MatchComposition(
              formationLabel: '1-0-0',
              playerCount: 1,
              slots: <FormationSlot>[
                FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
              ],
              assignments: <String?>['p1'],
            ),
            enabledStatKeys: defaultEnabledStatKeys(),
          ),
        );
    n.selectPlayer('p1');
    void bump(String key, int times) {
      for (int i = 0; i < times; i++) {
        n.bump(statKey: key, statLabel: key, playerName: 'X', delta: 1);
      }
    }

    bump('passesReussies', 3);
    bump('passesManquees', 1);
    bump('tirsCadres', 2);

    // Ni total ni % n'ont été saisis…
    expect(n.state!.playerStats['p1']!.keys, <String>{
      'passesReussies',
      'passesManquees',
      'tirsCadres',
    });
    // …mais tous les lecteurs les dérivent.
    expect(n.state!.statValue('p1', 'totalPasses'), 4);
    expect(n.state!.statValue('p1', 'totalTirs'), 2);

    final List<CollectifRow> rows = collectifRows(
      GameMatch(
        enabledStatKeys: defaultEnabledStatKeys(),
        playerStats: n.state!.playerStats,
      ),
    );
    String valeur(String label) =>
        rows.firstWhere((CollectifRow r) => r.label == label).value;
    expect(valeur('Total passes'), '4');
    expect(valeur('Réussite de passes'), pct('75,00'));
    expect(valeur('Total tirs'), '2');
  });
}
