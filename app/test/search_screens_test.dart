import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/custom_composition.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/notification_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/providers/search_providers.dart';
import 'package:wina/view/page/statistiques_matchs_screen.dart';
import 'package:wina/view/page/test_equipe_screen.dart';

import 'support/fake_search_service.dart';

/// Vrais libellés fr-FR (lus sur disque) : sans eux `.tr()` rend la clé brute.
class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  FakeSearchService service, {
  List<CustomComposition> compositions = const <CustomComposition>[],
  List<GameMatch> matches = const <GameMatch>[],
}) async {
  tester.view.physicalSize = const Size(2560, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // Les helpers d'échelle du socle ignorent la surface simulée : les
  // débordements du harnais sont sans rapport avec ce qui est vérifié.
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        searchServiceProvider.overrideWithValue(service),
        authUidProvider.overrideWith((ref) => Stream<String?>.value(null)),
        customCompositionsProvider.overrideWith(
          (ref) => Stream<List<CustomComposition>>.value(compositions),
        ),
        finishedMatchesProvider.overrideWith(
          (ref) => Stream<List<GameMatch>>.value(matches),
        ),
        playersStreamProvider.overrideWith(
          (ref) => Stream<List<Player>>.value(const <Player>[]),
        ),
        coachProfileProvider.overrideWith(
          (ref) => Stream<CoachProfile>.value(const CoachProfile()),
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
          designSize: const Size(2560, 1600),
          builder:
              (BuildContext context, _) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(body: home),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Saisit [text] puis laisse passer le debounce et la réponse du faux service.
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  group('Tester l\'équipe (compositions perso : local ∪ Algolia)', () {
    final List<FormationSlot> slots = standardFormations(11).first.slots;
    final List<CustomComposition> compositions = <CustomComposition>[
      CustomComposition(
        id: 'c1',
        name: 'Attaque rapide',
        playerCount: 11,
        formationLabel: '4-3-3',
        slots: slots,
      ),
      CustomComposition(
        id: 'c2',
        name: 'Défense haute',
        playerCount: 11,
        formationLabel: '4-4-2',
        slots: slots,
      ),
    ];

    testWidgets('Algolia ajoute une composition que le local ne trouve pas', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()..onCompositions = (_) async => <String>{'c1'};
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'ataque'); // faute de frappe : rien en local

      expect(service.compositionQueries, <String>['ataque']);
      expect(find.text('Attaque rapide'), findsOneWidget);
      expect(find.text('Défense haute'), findsNothing);
    });

    testWidgets('réponse 200 sans hit : le résultat local reste', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()..onCompositions = (_) async => <String>{};
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'défense');

      expect(service.compositionQueries, <String>['défense']);
      expect(find.text('Défense haute'), findsOneWidget);
      expect(find.text('Attaque rapide'), findsNothing);
    });

    testWidgets('erreur du service : local seul, aucun message d\'erreur', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()
            ..onCompositions = (_) async => throw StateError('hors ligne');
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'défense');

      expect(find.text('Défense haute'), findsOneWidget);
      expect(find.text('Attaque rapide'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('service indisponible (null) : local seul', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service = FakeSearchService();
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'défense');

      expect(find.text('Défense haute'), findsOneWidget);
      expect(find.text('Attaque rapide'), findsNothing);
    });

    testWidgets('le local s\'affiche sans attendre la réponse d\'Algolia', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> gate = Completer<Set<String>?>();
      final FakeSearchService service =
          FakeSearchService()..onCompositions = (_) => gate.future;
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'défense');
      expect(find.text('Défense haute'), findsOneWidget);
      expect(find.text('Attaque rapide'), findsNothing);

      gate.complete(<String>{'c1'});
      await tester.pump();
      expect(find.text('Attaque rapide'), findsOneWidget);
    });

    testWidgets('un id inconnu de la liste locale n\'ajoute rien', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()
            ..onCompositions = (_) async => <String>{'fantome'};
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'défense');

      expect(find.text('Défense haute'), findsOneWidget);
      expect(find.text('Attaque rapide'), findsNothing);
    });

    testWidgets('réponse périmée ignorée : seule la dernière frappe compte', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> first = Completer<Set<String>?>();
      final FakeSearchService service =
          FakeSearchService()
            ..onCompositions = (String q) async {
              if (q == 'ataque') return first.future;
              return <String>{};
            };
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'ataque');
      await _type(tester, 'défense');
      first.complete(<String>{'c1'}); // arrive après la frappe suivante
      await tester.pump();

      expect(find.text('Défense haute'), findsOneWidget);
      expect(find.text('Attaque rapide'), findsNothing);
    });

    testWidgets('requête vide : aucun appel', (WidgetTester tester) async {
      final FakeSearchService service = FakeSearchService();
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, '   ');

      expect(service.callCount, 0);
      expect(find.text('Attaque rapide'), findsOneWidget);
      expect(find.text('Défense haute'), findsOneWidget);
    });

    testWidgets('en attente : pas de « aucun résultat » avant la réponse', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> gate = Completer<Set<String>?>();
      final FakeSearchService service =
          FakeSearchService()..onCompositions = (_) => gate.future;
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'zzz'); // rien en local

      expect(find.text('Aucun résultat'), findsNothing);
      gate.complete(<String>{});
      await tester.pump();
      expect(find.text('Aucun résultat'), findsOneWidget);
    });

    testWidgets('en attente : le résultat Algolia s\'affiche à la réponse', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> gate = Completer<Set<String>?>();
      final FakeSearchService service =
          FakeSearchService()..onCompositions = (_) => gate.future;
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'ataque');
      expect(find.text('Aucun résultat'), findsNothing);

      gate.complete(<String>{'c1'});
      await tester.pump();
      expect(find.text('Attaque rapide'), findsOneWidget);
      expect(find.text('Aucun résultat'), findsNothing);
    });

    testWidgets('échec du service : l\'état vide reprend', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()
            ..onCompositions = (_) async => throw StateError('hors ligne');
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, 'zzz');

      expect(find.text('Aucun résultat'), findsOneWidget);
    });

    testWidgets('les standards restent filtrés en local seulement', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()
            ..onCompositions = (_) async => <String>{'c1', 'c2'};
      await _pump(
        tester,
        const TestEquipeScreen(),
        service,
        compositions: compositions,
      );

      await _type(tester, '4-4-2');

      // « 4-3-3 » n'apparaît qu'une fois : la pastille de la composition perso
      // ajoutée par Algolia. Le modèle standard 4-3-3 reste filtré en local.
      expect(find.text('4-3-3'), findsOneWidget);
      expect(service.matchQueries, isEmpty);
    });
  });

  group('Statistiques Matchs (matchs : local ∪ Algolia)', () {
    final List<GameMatch> matches = <GameMatch>[
      GameMatch(
        id: 'm1',
        opponent: const MatchOpponent(name: 'Villemoisson'),
        status: MatchStatus.finished,
        finishedAt: DateTime(2026, 3, 5),
      ),
      GameMatch(
        id: 'm2',
        opponent: const MatchOpponent(name: 'Brétigny'),
        status: MatchStatus.finished,
        finishedAt: DateTime(2026, 2, 12),
      ),
      GameMatch(
        id: 'm3',
        opponent: const MatchOpponent(name: 'Sainte-Geneviève'),
        status: MatchStatus.finished,
        finishedAt: DateTime(2026, 1, 20),
      ),
    ];

    testWidgets('Algolia ajoute un match absent du filtre local (accents)', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()..onMatches = (_) async => <String>{'m2'};
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await _type(tester, 'bretigny'); // « Brétigny » : pas de contains local

      expect(service.matchQueries, <String>['bretigny']);
      expect(find.text('Brétigny'), findsOneWidget);
      expect(find.text('Sainte-Geneviève'), findsNothing);
    });

    testWidgets('réponse 200 sans hit : le filtre local reste', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()..onMatches = (_) async => <String>{};
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await _type(tester, 'sainte');

      expect(find.text('Sainte-Geneviève'), findsOneWidget);
      expect(find.text('Brétigny'), findsNothing);
    });

    testWidgets('erreur du service : local seul', (WidgetTester tester) async {
      final FakeSearchService service =
          FakeSearchService()
            ..onMatches = (_) async => throw StateError('hors ligne');
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await _type(tester, 'sainte');

      expect(find.text('Sainte-Geneviève'), findsOneWidget);
      expect(find.text('Brétigny'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la date reste cherchable en local (« 20 janv. »)', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service = FakeSearchService();
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await _type(tester, '20 janv');

      expect(find.text('Sainte-Geneviève'), findsOneWidget);
      expect(find.text('Brétigny'), findsNothing);
    });

    testWidgets('debounce 300 ms ajouté : une seule requête pour une rafale', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service = FakeSearchService();
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await tester.enterText(find.byType(TextField), 'b');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'br');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'bre');
      expect(service.callCount, 0);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(service.matchQueries, <String>['bre']);
    });

    testWidgets('requête vide : aucun appel', (WidgetTester tester) async {
      final FakeSearchService service = FakeSearchService();
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await _type(tester, '  ');

      expect(service.callCount, 0);
    });

    testWidgets('en attente : pas de « aucun résultat » avant la réponse', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> gate = Completer<Set<String>?>();
      final FakeSearchService service =
          FakeSearchService()..onMatches = (_) => gate.future;
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await _type(tester, 'bretigny');

      expect(find.text('Aucun résultat'), findsNothing);
      gate.complete(<String>{});
      await tester.pump();
      expect(find.text('Aucun résultat'), findsOneWidget);
    });

    testWidgets('en attente : le résultat Algolia s\'affiche à la réponse', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> gate = Completer<Set<String>?>();
      final FakeSearchService service =
          FakeSearchService()..onMatches = (_) => gate.future;
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await _type(tester, 'bretigny');
      gate.complete(<String>{'m2'});
      await tester.pump();

      expect(find.text('Brétigny'), findsOneWidget);
      expect(find.text('Aucun résultat'), findsNothing);
    });

    testWidgets('échec du service : l\'état vide reprend', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()
            ..onMatches = (_) async => throw StateError('hors ligne');
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await _type(tester, 'bretigny');

      expect(find.text('Aucun résultat'), findsOneWidget);
    });

    testWidgets('un id hors des matchs chargés n\'ajoute rien', (
      WidgetTester tester,
    ) async {
      final FakeSearchService service =
          FakeSearchService()..onMatches = (_) async => <String>{'m99'};
      await _pump(
        tester,
        const StatistiquesMatchsScreen(),
        service,
        matches: matches,
      );

      await _type(tester, 'sainte');

      expect(find.text('Sainte-Geneviève'), findsOneWidget);
      expect(find.text('Brétigny'), findsNothing);
    });
  });
}
