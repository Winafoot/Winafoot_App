import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/view/page/bilan_collectif_screen.dart';
import 'package:wina/view/page/statistiques_matchs_screen.dart';
import 'package:wina/view/widget/bilan_scaffold.dart';

/// Vrais libellés fr-FR (lus sur disque) : sans eux `.tr()` rend la clé brute.
class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// Écran « Bilan collectif » : en-tête « équipe / adversaire » + période,
/// thèmes rangés deux par ligne, seules les stats suivies de la période, et
/// liens de période de la carte « Bilan » (grisés pour un match ancien).
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    String equipe = ' Vert le grand ',
  }) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          coachProfileProvider.overrideWith(
            (ref) => Stream<CoachProfile>.value(CoachProfile(teamName: equipe)),
          ),
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
                  home: home,
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Passes et tirs suivis dès la 1re mi-temps, butsMarques activé à la
  // mi-temps : 1re mi-temps 3 passes réussies + 1 manquée, total 5 + 2.
  const List<String> debut = <String>[
    'passesReussies',
    'passesManquees',
    'tirsCadres',
  ];
  const GameMatch decoupe = GameMatch(
    opponent: MatchOpponent(name: 'Villemoisson'),
    status: MatchStatus.finished,
    half: 2,
    enabledStatKeys: <String>[...debut, 'butsMarques'],
    firstHalfStatKeys: debut,
    firstHalfStats: <String, Map<String, int>>{
      'p1': <String, int>{'passesReussies': 3, 'passesManquees': 1},
    },
    playerStats: <String, Map<String, int>>{
      'p1': <String, int>{
        'passesReussies': 5,
        'passesManquees': 2,
        'butsMarques': 1,
      },
    },
  );

  testWidgets('1re mi-temps : équipe / adversaire, période, thèmes suivis', (
    tester,
  ) async {
    await pump(
      tester,
      const BilanCollectifScreen(match: decoupe, period: MatchPeriod.firstHalf),
    );

    expect(find.text('Vert le grand / Villemoisson'), findsOneWidget);
    // Libellé de période en en-tête (le titre de l'écran le porte aussi).
    expect(find.text('1ère mi-temps'), findsOneWidget);
    expect(find.text('Bilan collectif 1ère mi-temps'), findsOneWidget);
    // Seuls les thèmes suivis en 1re mi-temps : passes et tirs, pas offensives
    // (buts marqués n'a été activé qu'à la mi-temps) ni les autres.
    expect(find.text('Statistiques passes'), findsOneWidget);
    expect(find.text('Statistiques tirs'), findsOneWidget);
    expect(find.text('Statistiques offensives'), findsNothing);
    expect(find.text('Technique'), findsNothing);
    expect(find.text('Réussite de passes'), findsOneWidget);
    expect(find.text('75,00 %'), findsOneWidget);
    expect(find.text('Buts marqués'), findsNothing);
  });

  testWidgets('Total match par défaut, les deux premiers thèmes côte à côte', (
    tester,
  ) async {
    await pump(tester, const BilanCollectifScreen(match: decoupe));

    expect(find.text('Bilan collectif'), findsOneWidget);
    expect(find.text('Total match'), findsOneWidget);
    // Passes, tirs, offensives : trois thèmes, deux par ligne.
    final Offset passes = tester.getTopLeft(find.text('Statistiques passes'));
    final Offset tirs = tester.getTopLeft(find.text('Statistiques tirs'));
    final Offset offensives = tester.getTopLeft(
      find.text('Statistiques offensives'),
    );
    expect(tirs.dy, passes.dy);
    expect(tirs.dx, greaterThan(passes.dx));
    expect(offensives.dy, greaterThan(passes.dy));
    expect(offensives.dx, passes.dx);
    // 5 / 7 passes : la valeur vient des sommes du match.
    expect(find.text('71,43 %'), findsOneWidget);
  });

  testWidgets('2e mi-temps non jouée : des tirets, jamais des zéros', (
    tester,
  ) async {
    const GameMatch court = GameMatch(
      enabledStatKeys: debut,
      firstHalfStatKeys: debut,
      firstHalfStats: <String, Map<String, int>>{
        'p1': <String, int>{'passesReussies': 3},
      },
      playerStats: <String, Map<String, int>>{
        'p1': <String, int>{'passesReussies': 3},
      },
    );
    await pump(
      tester,
      const BilanCollectifScreen(match: court, period: MatchPeriod.secondHalf),
    );

    expect(find.text('2ème mi-temps'), findsOneWidget);
    // Passes réussies / manquées / total / réussite + tirs cadrés.
    expect(find.text(kStatNoValue), findsNWidgets(5));
    expect(find.text('0'), findsNothing);
  });

  testWidgets(
    'match ancien : 1re mi-temps indisponible, message, pas d\'export',
    (tester) async {
      const GameMatch ancien = GameMatch(
        enabledStatKeys: <String>['butsMarques'],
        playerStats: <String, Map<String, int>>{
          'p1': <String, int>{'butsMarques': 2},
        },
      );
      await pump(
        tester,
        const BilanCollectifScreen(
          match: ancien,
          period: MatchPeriod.firstHalf,
        ),
      );

      expect(
        find.text('Détail par mi-temps indisponible pour ce match.'),
        findsOneWidget,
      );
      expect(find.text('Statistiques offensives'), findsNothing);
      expect(find.text('Exporter en PDF'), findsNothing);
    },
  );

  testWidgets('sans nom d\'équipe ni d\'adversaire : repli lisible', (
    tester,
  ) async {
    await pump(
      tester,
      const BilanCollectifScreen(
        match: GameMatch(
          enabledStatKeys: <String>['butsMarques'],
          playerStats: <String, Map<String, int>>{
            'p1': <String, int>{'butsMarques': 1},
          },
        ),
      ),
    );

    expect(find.text('Vert le grand / Équipe adverse'), findsOneWidget);
  });

  /// Match minimal dont seul l'adversaire change : sert à mesurer l'en-tête.
  GameMatch contre(String adversaire) => GameMatch(
    opponent: MatchOpponent(name: adversaire),
    enabledStatKeys: const <String>['butsMarques'],
    playerStats: const <String, Map<String, int>>{
      'p1': <String, int>{'butsMarques': 1},
    },
  );

  testWidgets('nom court : « Exporter en PDF » reste collé au bord droit', (
    tester,
  ) async {
    await pump(tester, BilanCollectifScreen(match: contre('B')), equipe: 'A');

    // La colonne de l'écran couvre toute la largeur utile de la page.
    final Rect contenu = tester.getRect(
      find
          .ancestor(
            of: find.byType(BilanExportButton),
            matching: find.byType(Column),
          )
          .first,
    );
    expect(tester.getRect(find.byType(BilanExportButton)).right, contenu.right);
  });

  testWidgets('nom qui tient sur la ligne : jamais tronqué', (tester) async {
    // 25 caractères : plus que la moitié de la place libre, moins que la place
    // réellement disponible avant le bouton.
    const String equipes = 'Vert le grand / BBBBBBBBB';
    await pump(tester, BilanCollectifScreen(match: contre('BBBBBBBBB')));

    expect(
      tester
          .renderObject<RenderParagraph>(find.text(equipes))
          .didExceedMaxLines,
      isFalse,
    );
  });

  testWidgets('nom trop long : tronqué proprement, bouton toujours visible', (
    tester,
  ) async {
    await pump(tester, BilanCollectifScreen(match: contre('B' * 80)));

    expect(tester.takeException(), isNull);
    expect(
      tester
          .renderObject<RenderParagraph>(
            find.textContaining('Vert le grand / BBB'),
          )
          .didExceedMaxLines,
      isTrue,
    );
    expect(tester.getRect(find.byType(BilanExportButton)).right, 1154);
  });

  testWidgets('42 stats suivies : rien ne déborde à 1194 x 834', (
    tester,
  ) async {
    final List<String> toutes = <String>[
      for (final StatDef s in kStatCatalog) s.key,
    ];
    await pump(
      tester,
      BilanCollectifScreen(
        match: GameMatch(
          enabledStatKeys: toutes,
          playerStats: <String, Map<String, int>>{
            'p1': <String, int>{for (final String k in toutes) k: 12},
          },
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Statistiques passes'), findsOneWidget);
  });

  group('liens de période de la carte « Bilan »', () {
    Future<List<MatchPeriod>> tapper(
      WidgetTester tester, {
      required bool halvesAvailable,
      required List<String> liens,
    }) async {
      final List<MatchPeriod> ouvertes = <MatchPeriod>[];
      await pump(
        tester,
        Scaffold(
          body: BilanCard(
            title: 'Bilan collectif',
            halvesAvailable: halvesAvailable,
            onPeriod: ouvertes.add,
          ),
        ),
      );
      for (final String lien in liens) {
        await tester.tap(find.text(lien));
      }
      return ouvertes;
    }

    testWidgets('chaque lien transmet sa vraie période', (tester) async {
      expect(
        await tapper(
          tester,
          halvesAvailable: true,
          liens: <String>['Mi-temps 1', 'Mi-temps 2', 'Final'],
        ),
        <MatchPeriod>[
          MatchPeriod.firstHalf,
          MatchPeriod.secondHalf,
          MatchPeriod.total,
        ],
      );
    });

    testWidgets('match ancien : les mi-temps sont inertes, le Final marche', (
      tester,
    ) async {
      expect(
        await tapper(
          tester,
          halvesAvailable: false,
          liens: <String>['Mi-temps 1', 'Mi-temps 2', 'Final'],
        ),
        <MatchPeriod>[MatchPeriod.total],
      );
    });
  });
}
