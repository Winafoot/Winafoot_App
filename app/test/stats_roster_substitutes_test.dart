import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/view/page/statistiques_matchs_screen.dart';

/// Statistiques des remplaçants.
///
/// Le roster de l'écran « Statistiques matchs » ne groupait que par poste, et
/// ces groupes sont bâtis sur `slots`/`assignments` : un remplaçant n'occupant
/// aucun emplacement de schéma, il n'apparaissait dans aucun groupe et ses
/// statistiques étaient donc inatteignables depuis cet écran.
///
/// Ce test échoue si quelqu'un retire le groupe « Remplaçants », réintroduit un
/// numéro inventé pour un remplaçant qui n'en a pas, ou lui redonne le maillot
/// des titulaires.
void main() {
  const MatchComposition composition = MatchComposition(
    formationLabel: '1-1',
    playerCount: 2,
    slots: <FormationSlot>[
      FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
      FormationSlot(role: PlayerPosition.attaquant, x: 0.5, y: 0.2),
    ],
    assignments: <String?>['p1', 'p2'],
    substituteIds: <String>['p3', 'p4'],
    numbers: <String, int>{'p1': 1, 'p2': 9, 'p3': 17},
  );

  Map<String, Player> roster() => <String, Player>{
    for (int i = 1; i <= 4; i++)
      'p$i': Player(
        id: 'p$i',
        firstName: 'Joueur',
        lastName: '$i',
        strongFoot: StrongFoot.droit,
        position: PlayerPosition.milieu,
      ),
  };

  final String teamJersey = JerseyColorOption.rouge.asset;

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2560, 1600);
    addTearDown(tester.view.reset);

    // Les helpers de mise à l'échelle du socle se calent sur l'écran réel et
    // ne suivent pas la surface simulée : les lignes débordent en largeur sur
    // le harnais. Artefact de test, sans rapport avec ce qui est vérifié ici.
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Roster(
              composition: composition,
              byId: roster(),
              jerseyAsset: teamJersey,
              selectedPlayerId: null,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('les remplaçants figurent dans le roster des statistiques', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    // Les deux remplaçants sont listés, en plus des deux titulaires.
    expect(find.text('Joueur 3'), findsOneWidget);
    expect(find.text('Joueur 4'), findsOneWidget);
    expect(find.text('Joueur 1'), findsOneWidget);
    expect(find.text('Joueur 2'), findsOneWidget);
  });

  testWidgets('aucun numéro n\'est inventé pour un remplaçant qui n\'en a pas', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    // p3 a le numéro 17, p4 n'en a aucun : son maillot doit rester vide.
    expect(find.text('17'), findsOneWidget);
    // L'index d'emplacement servait de repli aux titulaires (i + 1). Appliqué
    // aux remplaçants il fabriquerait « 1 » et « 2 » en double.
    expect(find.text('1'), findsOneWidget); // le seul « 1 » est celui de p1
    expect(find.text('2'), findsNothing);
  });

  testWidgets('le maillot des remplaçants se distingue de celui des titulaires', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    final Iterable<Image> images =
        tester.widgetList<Image>(find.byType(Image)).cast<Image>();
    // `Image.asset` redimensionné (cacheWidth) enveloppe l'AssetImage dans un ResizeImage.
    String assetName(Image i) {
      final ImageProvider<Object> provider = i.image;
      return ((provider is ResizeImage ? provider.imageProvider : provider)
              as AssetImage)
          .assetName;
    }

    final Set<String> assets = images.map(assetName).toSet();
    expect(assets, contains(teamJersey));
    expect(assets, contains(subJerseyAsset(teamJersey)));
  });
}
