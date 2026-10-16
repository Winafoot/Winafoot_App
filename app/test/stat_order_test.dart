import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/view/widget/match_stats_board.dart';

/// `enabledStatKeys` est stocké dans l'ordre de clic de l'écran de paramétrage
/// (une stat activée après coup part en fin de liste). L'affichage doit
/// pourtant toujours suivre le catalogue : sinon l'écran live crée une carte
/// isolée par stat activée après coup, et le tableau comme le PDF ont leurs
/// colonnes dans un ordre arbitraire.
void main() {
  // Volontairement à l'envers du catalogue, avec une stat « duels » activée en
  // dernier et une clé inconnue.
  const List<String> stocke = <String>[
    'duelsAeriensPerdus',
    'inconnue',
    'butsSubis',
    'tirsCadres',
    'butsMarques',
    'interceptions',
    'duelsAeriens',
  ];

  test('enabledStatsInCatalogOrder suit le catalogue, pas le stockage', () {
    final List<String> keys =
        enabledStatsInCatalogOrder(stocke).map((StatDef s) => s.key).toList();

    expect(keys, <String>[
      'interceptions',
      'tirsCadres',
      'butsMarques',
      'butsSubis',
      'duelsAeriens',
      'duelsAeriensPerdus',
    ]);
  });

  test('une stat activée en dernier rejoint la carte de son thème', () {
    // Même regroupement en « runs » contigus que `_StatGrid` (écran live).
    final List<StatCategory> runs = <StatCategory>[];
    for (final StatDef s in enabledStatsInCatalogOrder(stocke)) {
      if (runs.isEmpty || runs.last != s.category) runs.add(s.category);
    }

    expect(runs, <StatCategory>[
      StatCategory.efficacite,
      StatCategory.tirs,
      StatCategory.offensives,
      StatCategory.gardienDefense,
      StatCategory.duels,
    ]);
  });

  testWidgets('MatchStatsBoard range les colonnes dans l\'ordre du catalogue', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2560, 1600);
    addTearDown(tester.view.reset);
    // Débordement en largeur propre au harnais : cf.
    // match_stats_board_alignment_test.dart.
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    final GameMatch match = const GameMatch().copyWith(
      composition: const MatchComposition(
        formationLabel: '1-0-0',
        playerCount: 1,
        slots: <FormationSlot>[
          FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
        ],
        assignments: <String?>['p1'],
        substituteIds: <String>[],
      ),
      enabledStatKeys: stocke,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchStatsBoard(
            live: (LiveMatchNotifier()..start(match)).state!,
            byId: <String, Player>{
              'p1': const Player(
                id: 'p1',
                firstName: 'Joueur',
                lastName: '1',
                strongFoot: StrongFoot.droit,
                position: PlayerPosition.gardien,
              ),
            },
          ),
        ),
      ),
    );

    final List<double> xs = <double>[
      for (final String label in const <String>[
        'Interception de ballons',
        'Tirs cadrés',
        'Buts marqués',
        'Buts subis',
        'Duels aériens gagnés',
        'Duels aériens perdus',
      ])
        tester.getTopLeft(find.text(label)).dx,
    ];
    expect(xs, orderedEquals(<double>[...xs]..sort()));
    expect(xs.toSet().length, xs.length);
  });
}
