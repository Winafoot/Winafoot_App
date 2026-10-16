import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/notification_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/services/stats_pdf_export.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/view/page/bilan_individuel_screen.dart';
import 'package:wina/view/page/statistiques_matchs_screen.dart';
import 'package:wina/view/widget/match_stats_board.dart';

/// Vrais libellés fr-FR (lus sur disque) : sans eux `.tr()` rend la clé brute.
class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// Bilan individuel par période : `LiveMatch.fromFinished`, tableau de l'écran,
/// tableau du PDF, et le tableau partagé du récap de pause / fin de match
/// (cumul du match, totaux calculés).
void main() {
  const MatchComposition composition = MatchComposition(
    formationLabel: '1-1',
    playerCount: 2,
    slots: <FormationSlot>[
      FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
      FormationSlot(role: PlayerPosition.attaquant, x: 0.5, y: 0.2),
    ],
    assignments: <String?>['p1', 'p2'],
    numbers: <String, int>{'p1': 1, 'p2': 9},
  );
  const Map<String, Player> byId = <String, Player>{
    'p1': Player(
      id: 'p1',
      firstName: 'Alice',
      lastName: 'Un',
      strongFoot: StrongFoot.droit,
      position: PlayerPosition.gardien,
    ),
    'p2': Player(
      id: 'p2',
      firstName: 'Bob',
      lastName: 'Deux',
      strongFoot: StrongFoot.droit,
      position: PlayerPosition.attaquant,
    ),
  };

  // Passes suivies dès la 1re mi-temps, buts marqués activés à la mi-temps.
  // Alice : 1re mi-temps 3 réussies + 1 manquée, total 5 + 2 et 1 but, donc
  // 2e mi-temps 2 + 1 et 1 but. Bob : 1 + 1 en 1re, rien ensuite.
  // « totalPasses » : valeur qui traîne d'un ancien match, à ignorer.
  const List<String> debut = <String>['passesReussies', 'passesManquees'];
  const GameMatch decoupe = GameMatch(
    composition: composition,
    status: MatchStatus.finished,
    half: 2,
    enabledStatKeys: <String>[...debut, 'butsMarques'],
    firstHalfStatKeys: debut,
    firstHalfStats: <String, Map<String, int>>{
      'p1': <String, int>{'passesReussies': 3, 'passesManquees': 1},
      'p2': <String, int>{'passesReussies': 1, 'passesManquees': 1},
    },
    playerStats: <String, Map<String, int>>{
      'p1': <String, int>{
        'passesReussies': 5,
        'passesManquees': 2,
        'butsMarques': 1,
        'totalPasses': 99,
      },
      'p2': <String, int>{'passesReussies': 1, 'passesManquees': 1},
    },
  );
  // Terminé avant la reprise : 2e mi-temps non jouée.
  const GameMatch sansReprise = GameMatch(
    composition: composition,
    status: MatchStatus.finished,
    half: 1,
    enabledStatKeys: debut,
    firstHalfStatKeys: debut,
    firstHalfStats: <String, Map<String, int>>{
      'p1': <String, int>{'passesReussies': 3, 'passesManquees': 1},
    },
    playerStats: <String, Map<String, int>>{
      'p1': <String, int>{'passesReussies': 3, 'passesManquees': 1},
    },
  );
  // Enregistré avant le découpage par mi-temps : seul le Total existe.
  const GameMatch ancien = GameMatch(
    composition: composition,
    status: MatchStatus.finished,
    enabledStatKeys: debut,
    playerStats: <String, Map<String, int>>{
      'p1': <String, int>{'passesReussies': 4, 'passesManquees': 4},
    },
  );

  const String pct75 = '75,00 %';

  group('LiveMatch.fromFinished par période', () {
    test('1re mi-temps : ses stats et ses stats suivies', () {
      final LiveMatch live = LiveMatch.fromFinished(
        decoupe,
        MatchPeriod.firstHalf,
      );

      expect(live.playerStats['p1'], <String, int>{
        'passesReussies': 3,
        'passesManquees': 1,
      });
      expect(live.enabledStatKeys, debut);
    });

    test('2e mi-temps : total moins 1re mi-temps', () {
      final LiveMatch live = LiveMatch.fromFinished(
        decoupe,
        MatchPeriod.secondHalf,
      );

      expect(live.playerStats['p1']!['passesReussies'], 2);
      expect(live.playerStats['p1']!['butsMarques'], 1);
      expect(live.playerStats['p2']!['passesReussies'], 0);
      expect(live.enabledStatKeys, contains('butsMarques'));
    });

    test(
      'Total par défaut : le match entier, stats de 1re mi-temps comprises',
      () {
        // « tirsBloques » n'était suivie qu'en 1re mi-temps (désactivée à la
        // pause) : le Total la garde, comme le bilan collectif.
        const GameMatch desactivee = GameMatch(
          enabledStatKeys: <String>['passesReussies'],
          firstHalfStatKeys: <String>['passesReussies', 'tirsBloques'],
          firstHalfStats: <String, Map<String, int>>{
            'p1': <String, int>{'tirsBloques': 2},
          },
          playerStats: <String, Map<String, int>>{
            'p1': <String, int>{'tirsBloques': 2, 'passesReussies': 1},
          },
          half: 2,
        );

        final LiveMatch live = LiveMatch.fromFinished(desactivee);

        expect(live.playerStats['p1']!['passesReussies'], 1);
        expect(live.enabledStatKeys, containsAll(<String>['tirsBloques']));
      },
    );

    test('2e mi-temps non jouée : les colonnes du match, sans valeurs', () {
      final LiveMatch live = LiveMatch.fromFinished(
        sansReprise,
        MatchPeriod.secondHalf,
      );

      expect(live.playerStats, isEmpty);
      expect(live.enabledStatKeys, containsAll(debut));
    });

    test('match ancien : mi-temps sans stats ni colonnes, Total intact', () {
      final LiveMatch mt = LiveMatch.fromFinished(
        ancien,
        MatchPeriod.firstHalf,
      );
      final LiveMatch total = LiveMatch.fromFinished(ancien);

      expect(mt.playerStats, isEmpty);
      expect(mt.enabledStatKeys, isEmpty);
      expect(total.playerStats['p1']!['passesReussies'], 4);
      expect(total.enabledStatKeys, containsAll(debut));
    });
  });

  group('tableau du PDF individuel', () {
    /// Lignes (en-tête comprise) de chaque tableau du contenu : une par page.
    List<List<List<String>>> tableaux(List<pw.Widget> content) =>
        <List<List<String>>>[
          for (final pw.Table w in content.whereType<pw.Table>())
            <List<String>>[
              for (final pw.TableRow r in w.children)
                <String>[
                  for (final pw.Widget c in r.children)
                    ((c as pw.Container).child! as pw.Text).text.toPlainText(),
                ],
            ],
        ];

    List<List<String>> unePage(GameMatch match, MatchPeriod period) {
      final List<List<List<String>>> pages = tableaux(
        bilanIndividuelContent(match, byId, period),
      );
      expect(pages, hasLength(1));
      return pages.single;
    }

    test('1re mi-temps : valeurs de la mi-temps, total et % dérivés', () {
      expect(unePage(decoupe, MatchPeriod.firstHalf), <List<String>>[
        <String>[
          'Joueur',
          'N°',
          'Passes réussies',
          'Passes manquées',
          'Total passes',
          'Réussite de passes',
        ],
        <String>['Alice Un', '1', '3', '1', '4', pct75],
        <String>['Bob Deux', '9', '1', '1', '2', '50,00 %'],
      ]);
    });

    test('2e mi-temps : total − 1re, « — » quand aucune passe', () {
      expect(unePage(decoupe, MatchPeriod.secondHalf).skip(1), <List<String>>[
        <String>['Alice Un', '1', '2', '1', '3', '66,67 %', '1'],
        <String>['Bob Deux', '9', '0', '0', '0', kStatNoValue, '0'],
      ]);
    });

    test('Total : somme des deux mi-temps, la valeur stockée est ignorée', () {
      expect(unePage(decoupe, MatchPeriod.total).skip(1), <List<String>>[
        // 7 = 5 + 2 (et non les 99 traînant sous « totalPasses »), 5/7.
        <String>['Alice Un', '1', '5', '2', '7', '71,43 %', '1'],
        <String>['Bob Deux', '9', '1', '1', '2', '50,00 %', '0'],
      ]);
    });

    test('2e mi-temps non jouée : des tirets partout, jamais un 0', () {
      final List<List<String>> lignes = unePage(
        sansReprise,
        MatchPeriod.secondHalf,
      );

      expect(lignes.first, hasLength(6));
      for (final List<String> l in lignes.skip(1)) {
        expect(l.skip(2), everyElement(kStatNoValue));
      }
    });

    test('les 3 périodes se construisent avec la police du PDF réel', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final pw.ThemeData theme = await poppinsPdfTheme();
      for (final MatchPeriod p in MatchPeriod.values) {
        final pw.Document doc = buildBilanIndividuelDocument(
          match: sansReprise,
          byId: byId,
          title: 'Bilan individuel',
          period: p,
          theme: theme,
        );
        final List<int> bytes = await doc.save();

        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      }
    });
  });

  group('écran « Bilan individuel »', () {
    Future<void> pump(
      WidgetTester tester,
      Widget home, {
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
            playersStreamProvider.overrideWith(
              (Ref ref) => Stream<List<Player>>.value(byId.values.toList()),
            ),
            // Onglet « Statistiques matchs » : historique, profil, cloche.
            finishedMatchesProvider.overrideWith(
              (Ref ref) => Stream<List<GameMatch>>.value(matches),
            ),
            coachProfileProvider.overrideWith(
              (Ref ref) => Stream<CoachProfile>.value(const CoachProfile()),
            ),
            unreadNotificationCountProvider.overrideWith((Ref ref) => 0),
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
                    home: home,
                  ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('1re mi-temps : titre, colonnes et valeurs de la mi-temps', (
      tester,
    ) async {
      await pump(
        tester,
        const BilanIndividuelScreen(
          match: decoupe,
          period: MatchPeriod.firstHalf,
        ),
      );

      expect(find.text('Bilan individuel 1ère mi-temps'), findsOneWidget);
      expect(find.text('Réussite de passes'), findsOneWidget);
      expect(find.text('Total passes'), findsOneWidget);
      // Alice 3/4, Bob 1/2 ; les buts n'étaient pas suivis en 1re mi-temps.
      expect(find.text(pct75), findsOneWidget);
      expect(find.text('50,00 %'), findsOneWidget);
      expect(find.text('Buts marqués'), findsNothing);
      expect(find.text('Exporter en PDF'), findsOneWidget);
    });

    testWidgets('2e mi-temps : titre et valeurs de la 2e mi-temps', (
      tester,
    ) async {
      await pump(
        tester,
        const BilanIndividuelScreen(
          match: decoupe,
          period: MatchPeriod.secondHalf,
        ),
      );

      expect(find.text('Bilan individuel 2ème mi-temps'), findsOneWidget);
      expect(find.text('Buts marqués'), findsOneWidget);
      // Alice 2/3 ; Bob n'a rien fait : pas de %, pas de faux 0 %.
      expect(find.text('66,67 %'), findsOneWidget);
      expect(find.text(kStatNoValue), findsOneWidget);
    });

    testWidgets('Total par défaut : titre sans période, somme du match', (
      tester,
    ) async {
      await pump(tester, const BilanIndividuelScreen(match: decoupe));

      expect(find.text('Bilan individuel'), findsOneWidget);
      // Alice 5/7 : le « totalPasses » stocké (99) ne compte pas.
      expect(find.text('71,43 %'), findsOneWidget);
      expect(find.text('99'), findsNothing);
    });

    testWidgets('2e mi-temps non jouée : des tirets, jamais des zéros', (
      tester,
    ) async {
      await pump(
        tester,
        const BilanIndividuelScreen(
          match: sansReprise,
          period: MatchPeriod.secondHalf,
        ),
      );

      // 2 joueurs × 4 colonnes (réussies, manquées, total, %).
      expect(find.text(kStatNoValue), findsNWidgets(8));
      expect(find.text('0'), findsNothing);
      expect(find.text('Exporter en PDF'), findsOneWidget);
    });

    testWidgets(
      'match ancien : mi-temps indisponible, message et pas d\'export',
      (tester) async {
        await pump(
          tester,
          const BilanIndividuelScreen(
            match: ancien,
            period: MatchPeriod.firstHalf,
          ),
        );

        expect(
          find.text('Détail par mi-temps indisponible pour ce match.'),
          findsOneWidget,
        );
        expect(find.text('Réussite de passes'), findsNothing);
        expect(find.text('Exporter en PDF'), findsNothing);
      },
    );

    testWidgets('match ancien : le Total reste consultable', (tester) async {
      await pump(tester, const BilanIndividuelScreen(match: ancien));

      // 4 réussies / 8 passes.
      expect(find.text('50,00 %'), findsOneWidget);
      expect(find.text('Exporter en PDF'), findsOneWidget);
    });

    // Le lien de période de la carte « Bilan individuel » de l'onglet
    // « Statistiques matchs » ouvre le bilan de CETTE période (le popup de
    // choix du joueur s'intercale : aucun joueur n'est désigné sur le terrain).
    Future<void> ouvrirDepuisLHistorique(
      WidgetTester tester,
      GameMatch match,
      String lien,
    ) async {
      await pump(
        tester,
        const Scaffold(body: StatistiquesMatchsScreen()),
        matches: <GameMatch>[match],
      );
      // Deux cartes portent ce lien : « Bilan collectif » puis « individuel ».
      await tester.tap(find.text(lien).last);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'historique : « Mi-temps 2 » ouvre le bilan de la 2e mi-temps',
      (tester) async {
        await ouvrirDepuisLHistorique(tester, decoupe, 'Mi-temps 2');
        await tester.tap(find.text('Consulter'));
        await tester.pumpAndSettle();

        expect(find.text('Bilan individuel 2ème mi-temps'), findsOneWidget);
        expect(find.text('66,67\u00A0%'), findsOneWidget);
      },
    );

    testWidgets('historique : « Final » ouvre le bilan du Total', (
      tester,
    ) async {
      await ouvrirDepuisLHistorique(tester, decoupe, 'Final');
      await tester.tap(find.text('Consulter'));
      await tester.pumpAndSettle();

      expect(find.text('Bilan individuel'), findsOneWidget);
      expect(find.text('71,43\u00A0%'), findsOneWidget);
    });

    testWidgets('historique, match ancien : « Mi-temps 1 » est inerte', (
      tester,
    ) async {
      await ouvrirDepuisLHistorique(tester, ancien, 'Mi-temps 1');

      // Ni popup de choix du joueur, ni écran de bilan.
      expect(find.text('Consulter'), findsNothing);
      expect(find.text('Bilan individuel 1ère mi-temps'), findsNothing);
    });

    testWidgets(
      'récap pause / fin de match : cumul du match, totaux non nuls',
      (tester) async {
        // Le tableau est partagé : sans période, il montre le cumul du direct
        // (ici 3 réussies + 1 manquée pour Alice).
        final LiveMatch cumul = LiveMatch.fromGameMatch(
          const GameMatch(composition: composition, enabledStatKeys: debut),
        ).copyWith(
          playerStats: const <String, Map<String, int>>{
            'p1': <String, int>{'passesReussies': 3, 'passesManquees': 1},
          },
        );
        await pump(
          tester,
          Scaffold(body: MatchStatsBoard(live: cumul, byId: byId)),
        );

        expect(find.text('Total passes'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text(pct75), findsOneWidget);
      },
    );
  });
}
