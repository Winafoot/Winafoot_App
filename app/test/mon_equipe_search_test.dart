import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/notification_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/providers/search_providers.dart';
import 'package:wina/models/custom_composition.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/view/page/mon_equipe_screen.dart';

import 'support/fake_search_service.dart';

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

const List<Player> _roster = <Player>[
  Player(
    id: 'p1',
    firstName: 'Léa',
    lastName: 'Martin',
    strongFoot: StrongFoot.droit,
    position: PlayerPosition.gardien,
  ),
  Player(
    id: 'p2',
    firstName: 'Hugo',
    lastName: 'Durand',
    strongFoot: StrongFoot.gauche,
    position: PlayerPosition.defenseur,
  ),
  Player(
    id: 'p3',
    firstName: 'Inès',
    lastName: 'Marteau',
    strongFoot: StrongFoot.droit,
    position: PlayerPosition.milieu,
  ),
];

Future<FakeSearchService> _pump(
  WidgetTester tester, {
  List<Player> roster = _roster,
}) async {
  tester.view.physicalSize = const Size(1194, 834);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
  final FakeSearchService service = FakeSearchService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        searchServiceProvider.overrideWithValue(service),
        authUidProvider.overrideWith((ref) => Stream<String?>.value(null)),
        coachProfileProvider.overrideWith(
          (ref) => Stream<CoachProfile>.value(const CoachProfile()),
        ),
        playersStreamProvider.overrideWith(
          (ref) => Stream<List<Player>>.value(roster),
        ),
        maxSquadSizeProvider.overrideWith((ref) async => 20),
        customCompositionsProvider.overrideWith(
          (ref) => Stream<List<CustomComposition>>.value(
            const <CustomComposition>[],
          ),
        ),
        finishedMatchesProvider.overrideWith(
          (ref) => Stream<List<GameMatch>>.value(const <GameMatch>[]),
        ),
        unreadNotificationCountProvider.overrideWith((ref) => 0),
      ],
      child: EasyLocalization(
        supportedLocales: const <Locale>[Locale('fr', 'FR')],
        startLocale: const Locale('fr', 'FR'),
        path: 'assets/translations',
        assetLoader: const _DiskAssetLoader(),
        saveLocale: false,
        child: ScreenUtilInit(
          designSize: const Size(1194, 834),
          builder:
              (BuildContext context, _) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const MonEquipeScreen(),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

/// Le seul champ de l'onglet « Mon équipe » (les autres onglets de l'IndexedStack
/// sont hors champ) : on vise celui qui porte le placeholder de la barre.
Finder get _searchField =>
    find.widgetWithText(TextField, 'Rechercher un joueur');

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_searchField, text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  group('barre Joueurs de « Mon équipe »', () {
    testWidgets('visible dans l\'entête, tous les joueurs affichés au départ', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      expect(_searchField, findsOneWidget);
      expect(find.text('Léa Martin'), findsOneWidget);
      expect(find.text('Hugo Durand'), findsOneWidget);
      expect(find.text('Inès Marteau'), findsOneWidget);
    });

    testWidgets('filtre « prénom nom » (contains, minuscules)', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      await _type(tester, 'MART');

      expect(find.text('Léa Martin'), findsOneWidget);
      expect(find.text('Inès Marteau'), findsOneWidget);
      expect(find.text('Hugo Durand'), findsNothing);

      // Le prénom et le nom se cherchent ensemble, dans cet ordre.
      await _type(tester, 'hugo d');
      expect(find.text('Hugo Durand'), findsOneWidget);
      expect(find.text('Léa Martin'), findsNothing);
    });

    testWidgets('le compteur reste celui de l\'effectif complet', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      await _type(tester, 'hugo');

      expect(find.text('3 sur 20 joueurs'), findsOneWidget);
    });

    testWidgets('aucun joueur ne correspond : état vide', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      await _type(tester, 'zzz');

      expect(find.text('Léa Martin'), findsNothing);
      expect(find.text('Aucun joueur trouvé'), findsOneWidget);
    });

    testWidgets('effacer la saisie rend tout l\'effectif', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      await _type(tester, 'zzz');

      await tester.tap(find.byIcon(Iconsax.close_circle));
      await tester.pumpAndSettle();

      expect(find.text('Aucun joueur trouvé'), findsNothing);
      expect(find.text('Léa Martin'), findsOneWidget);
      expect(find.text('Hugo Durand'), findsOneWidget);
    });

    testWidgets('AUCUN appel au service de recherche', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service = await _pump(tester);

      await _type(tester, 'mart');
      await _type(tester, 'zzz');

      expect(service.callCount, 0);
    });

    testWidgets('effectif vide : l\'état vide de l\'effectif est conservé', (
      WidgetTester tester,
    ) async {
      await _pump(tester, roster: const <Player>[]);

      expect(find.text('Aucun joueur dans l’effectif'), findsOneWidget);
    });
  });
}
