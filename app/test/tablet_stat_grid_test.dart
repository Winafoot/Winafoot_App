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

/// Saisie des statistiques sur tablette : 7 gros boutons au plus sur le premier
/// écran, en alternance gagné / perdu dans l'ordre de priorité ; 7 stats ou
/// moins : toutes, sans défilement ; au-delà, les autres sont plus bas.
void main() {
  const double hauteur = 700;
  const Player joueur = Player(
    id: 'p1',
    firstName: 'Joueur',
    lastName: 'Un',
    strongFoot: StrongFoot.droit,
    position: PlayerPosition.gardien,
  );

  Future<LiveMatchNotifier> pump(WidgetTester tester, List<String> keys) async {
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

  testWidgets('28 stats : 7 gros boutons, en alternance, le reste plus bas', (
    WidgetTester tester,
  ) async {
    await pump(tester, <String>[for (final StatDef s in kStatToggles) s.key]);

    expect(find.byType(BigStatTile), findsNWidgets(kFirstScreenStats));
    // Gagnés (droite) 4 : passes réussies, récupérations, tirs cadrés, contrôles réussis.
    for (final String l in <String>[
      'Passes réussies',
      'Récupérations de ballons',
      'Tirs cadrés',
      'Contrôles réussis',
    ]) {
      expect(tuile(l), findsOneWidget, reason: l);
    }
    // Perdus (gauche) 3 : passes manquées, pertes de ballons, tirs non cadrés.
    for (final String l in <String>[
      'Passes manquées',
      'Pertes de ballons',
      'Tirs non cadrés',
    ]) {
      expect(tuile(l), findsOneWidget, reason: l);
    }
    // La 4e stat perdue n'est plus un gros bouton : elle est plus bas.
    expect(tuile('Contrôles manqués'), findsNothing);
    expect(find.text('Contrôles manqués'), findsOneWidget);

    // Le premier écran ne montre que les 7 gros boutons.
    final double basDernier = tester.getBottomLeft(find.byType(BigStatTile).last).dy;
    expect(basDernier, lessThanOrEqualTo(hauteur));
    expect(
      tester.getTopLeft(find.text('Contrôles manqués')).dy,
      greaterThanOrEqualTo(hauteur),
    );
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
