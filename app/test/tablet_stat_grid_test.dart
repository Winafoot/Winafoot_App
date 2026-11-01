import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/view/page/match_live_screen.dart';

/// Saisie des statistiques : 7 gros boutons par colonne (14) sur le premier écran de la tablette, 6 sur
/// téléphone, dans l'ordre de priorité ; 5 stats : toutes sans défilement ; au-delà, les autres sont plus bas.
void main() {
  const double hauteur = 700;
  const Player joueur = Player(
    id: 'p1',
    firstName: 'Joueur',
    lastName: 'Un',
    strongFoot: StrongFoot.droit,
    position: PlayerPosition.gardien,
  );

  Future<LiveMatchNotifier> pump(
    WidgetTester tester,
    List<String> keys, {
    int premierEcran = kFirstScreenStats,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1194, 834);
    addTearDown(tester.view.reset);
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    final LiveMatchNotifier notifier =
        LiveMatchNotifier()..start(
          GameMatch(
            composition: const MatchComposition(
              formationLabel: '1-0-0',
              playerCount: 1,
              slots: <FormationSlot>[
                FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
              ],
              assignments: <String?>['p1'],
            ),
            enabledStatKeys: keys,
          ),
        );
    // Comme l'écran : le joueur est sélectionné avant la saisie.
    notifier.selectPlayer('p1');
    final LiveMatch live = notifier.state!;
    final List<StatDef> stats = <StatDef>[
      for (final StatDef s in enabledStatsInCatalogOrder(keys))
        if (!s.bilanOnly) s,
    ];
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1194, 834),
        builder:
            (BuildContext context, Widget? _) => MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: hauteur,
                  child: SingleChildScrollView(
                    child: TabletStatGrid(
                      stats: stats,
                      live: live,
                      pid: 'p1',
                      player: joueur,
                      notifier: notifier,
                      viewportHeight: hauteur,
                      firstScreenStats: premierEcran,
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();
    return notifier;
  }

  Finder tuile(String label) => find.descendant(
    of: find.byType(BigStatTile),
    matching: find.text(label),
  );

  testWidgets('28 stats : 14 gros boutons (7 par colonne), le reste plus bas', (
    WidgetTester tester,
  ) async {
    await pump(tester, <String>[for (final StatDef s in kStatToggles) s.key]);

    // Tous en gros boutons de même taille ; seuls les 7 premiers de chaque colonne tiennent à l'écran.
    final Iterable<Element> tuiles = find.byType(BigStatTile).evaluate();
    expect(tuiles.length, greaterThan(2 * kFirstScreenStats));
    final double h = tester.getSize(find.byType(BigStatTile).first).height;
    for (int i = 0; i < tuiles.length; i++) {
      expect(tester.getSize(find.byType(BigStatTile).at(i)).height, h);
    }
    final int surEcran =
        find.byType(BigStatTile).evaluate().where((Element e) {
          final RenderBox b = e.renderObject! as RenderBox;
          return b.localToGlobal(Offset.zero).dy + b.size.height <= hauteur + 0.5;
        }).length;
    expect(surEcran, 2 * kFirstScreenStats);
    // Les plus prioritaires de chaque colonne sont des gros boutons.
    for (final String l in <String>[
      'Passes réussies',
      'Récupérations de ballons',
      'Passes manquées',
      'Pertes de ballons',
    ]) {
      expect(tuile(l), findsOneWidget, reason: l);
    }
  });

  testWidgets('téléphone : 12 gros boutons (6 par colonne) au premier écran', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      <String>[for (final StatDef s in kStatToggles) s.key],
      premierEcran: kPhoneFirstScreenStats,
    );

    final int surEcran =
        find.byType(BigStatTile).evaluate().where((Element e) {
          final RenderBox b = e.renderObject! as RenderBox;
          return b.localToGlobal(Offset.zero).dy + b.size.height <= hauteur + 0.5;
        }).length;
    expect(surEcran, 2 * kPhoneFirstScreenStats);
  });

  testWidgets('5 stats : toutes en gros boutons, rien en dessous', (
    WidgetTester tester,
  ) async {
    await pump(tester, <String>[
      'passesReussies',
      'passesManquees',
      'tirsCadres',
      'tirsNonCadres',
      'recuperations',
    ]);

    expect(find.byType(BigStatTile), findsNWidgets(5));
    expect(
      tester.getBottomLeft(find.byType(BigStatTile).last).dy,
      lessThanOrEqualTo(hauteur),
    );
  });

  testWidgets('un tap sur un gros bouton ajoute 1 à la stat du joueur', (
    WidgetTester tester,
  ) async {
    final LiveMatchNotifier notifier = await pump(tester, <String>[
      'passesReussies',
      'passesManquees',
    ]);

    await tester.tap(tuile('Passes réussies'));
    await tester.pump();

    expect(notifier.state!.statValue('p1', 'passesReussies'), 1);
    expect(notifier.state!.statValue('p1', 'passesManquees'), 0);
  });
}
