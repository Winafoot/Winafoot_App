import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/view/widget/match_stats_board.dart';

/// `MatchStatsBoard` pose deux volets côte à côte — les noms à gauche, les
/// valeurs à droite — alignés uniquement par l'égalité de leurs hauteurs de
/// ligne. Rien ne les réaligne à l'exécution.
///
/// Un défilement vertical INTERNE à l'un des deux volets les laisse donc
/// dériver : le volet droit ne défile qu'à l'horizontale, si la colonne des
/// noms glisse toute seule le tableau affiche les statistiques d'un joueur en
/// face du nom d'un autre, sans aucun indice visuel. C'est ce qui a été
/// constaté en mi-temps et en fin de match — un coach y lisait le total d'un
/// titulaire en face d'un remplaçant jamais entré en jeu.
///
/// Le défilement vertical appartient donc à l'écran hôte, qui fait défiler la
/// carte entière. Ce test échoue si quelqu'un remet un scroll vertical dans le
/// widget.
void main() {
  LiveMatch seeded() {
    final GameMatch match = const GameMatch().copyWith(
      composition: const MatchComposition(
        formationLabel: '1-1-1',
        playerCount: 3,
        slots: <FormationSlot>[
          FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
          FormationSlot(role: PlayerPosition.defenseur, x: 0.5, y: 0.6),
          FormationSlot(role: PlayerPosition.attaquant, x: 0.5, y: 0.2),
        ],
        assignments: <String?>['p1', 'p2', 'p3'],
        substituteIds: <String>['p4', 'p5'],
      ),
      enabledStatKeys: const <String>['butsMarques'],
    );
    return (LiveMatchNotifier()..start(match)).state!;
  }

  Map<String, Player> roster() => <String, Player>{
    for (int i = 1; i <= 5; i++)
      'p$i': Player(
        id: 'p$i',
        firstName: 'Joueur',
        lastName: '$i',
        strongFoot: StrongFoot.droit,
        position: PlayerPosition.milieu,
      ),
  };

  Future<void> pump(WidgetTester tester) async {
    // Surface de la tablette de recette.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2560, 1600);
    addTearDown(tester.view.reset);

    // Les helpers de mise à l'échelle du socle se calent sur l'écran réel et
    // ne suivent pas la surface simulée : la colonne des noms déborde donc en
    // LARGEUR sur le harnais. C'est un artefact de test, sans rapport avec ce
    // qui est vérifié ici — l'axe des scrollables. On laisse passer ces seules
    // erreurs de débordement ; toute autre remonte normalement.
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchStatsBoard(live: seeded(), byId: roster()),
        ),
      ),
    );
  }

  testWidgets('ne porte aucun défilement vertical interne', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    final Iterable<Scrollable> scrollables =
        tester.widgetList<Scrollable>(find.byType(Scrollable));

    expect(
      scrollables.where((Scrollable s) => s.axisDirection == AxisDirection.down),
      isEmpty,
      reason:
          'Un scroll vertical dans le tableau désaligne les noms des valeurs : '
          'le défilement vertical doit rester à la charge de l’écran hôte.',
    );
  });

  testWidgets('conserve le défilement horizontal des statistiques', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    final Iterable<Scrollable> scrollables =
        tester.widgetList<Scrollable>(find.byType(Scrollable));

    expect(
      scrollables.where(
        (Scrollable s) => s.axisDirection == AxisDirection.right,
      ),
      isNotEmpty,
      reason:
          'Les colonnes de statistiques restent défilables à l’horizontale, '
          'c’est la pagination pilotée par les flèches ‹ ›.',
    );
  });
}
