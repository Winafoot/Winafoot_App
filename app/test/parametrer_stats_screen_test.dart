import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/view/page/parametrer_stats_screen.dart';
import 'package:wina/view/widget/stat_tone.dart';

/// Vrais libellés fr-FR (lus sur disque) : sans eux `.tr()` rend la clé brute
/// et le compteur « X / 28 sélectionnées » n'est pas vérifiable.
class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// Écran « Paramétrez les statistiques » : 28 bascules (les 5 stats calculées
/// n'en sont pas) en 2 colonnes, « Perdus » et « Gagnés », et un compteur qui ne
/// compte que les bascules.
void main() {
  /// Ouvre l'écran par-dessus une page vide (« Valider » fait un `pop`) avec un
  /// brouillon dont `enabledStatKeys` vaut [keys]. Rend le conteneur pour lire
  /// le brouillon après « Valider ».
  Future<ProviderContainer> open(
    WidgetTester tester, {
    List<String> keys = const <String>[],
  }) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        matchDraftProvider.overrideWith(
          (ref) => MatchDraftNotifier()..setEnabledStats(keys),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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
                  home: const SizedBox(),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const ParametrerStatsScreen(),
          ),
        );
    await tester.pumpAndSettle();
    return container;
  }

  String compteur(int n) => '$n / 28 sélectionnées';

  int allumees(WidgetTester tester) =>
      tester
          .widgetList<Switch>(find.byType(Switch))
          .where((Switch s) => s.value)
          .length;

  testWidgets('28 bascules : les 5 stats calculées n\'y figurent pas', (
    WidgetTester tester,
  ) async {
    await open(tester);

    expect(find.byType(Switch), findsNWidgets(28));
    for (final StatDef s in kStatCatalog) {
      expect(
        find.text(s.label),
        s.isCalculated ? findsNothing : findsOneWidget,
        reason: s.label,
      );
    }
  });

  testWidgets('deux colonnes « Perdus » et « Gagnés » : chaque bascule dans celle de sa nature', (
    WidgetTester tester,
  ) async {
    await open(tester);

    final Offset perdus = tester.getTopLeft(find.text('Perdus'));
    final Offset gagnes = tester.getTopLeft(find.text('Gagnés'));
    expect(perdus.dx, lessThan(gagnes.dx));

    for (final StatSide side in <StatSide>[StatSide.bad, StatSide.good]) {
      final Offset titre = side == StatSide.bad ? perdus : gagnes;
      final Offset autre = side == StatSide.bad ? gagnes : perdus;
      double? dernierY;
      for (final StatDef s in statsOfSide(kStatToggles, side)) {
        final Offset label = tester.getTopLeft(find.text(s.label));
        // Dans la colonne de son titre…
        expect(
          (label.dx - titre.dx).abs(),
          lessThan((label.dx - autre.dx).abs()),
          reason: s.label,
        );
        // …sous ce titre, dans l'ordre de priorité de la colonne.
        expect(label.dy, greaterThan(titre.dy), reason: s.label);
        if (dernierY != null) {
          expect(label.dy, greaterThan(dernierY), reason: s.label);
        }
        dernierY = label.dy;
      }
    }

    // Toutes les bascules sont rangées dans l'une des deux colonnes.
    expect(
      statsOfSide(kStatToggles, StatSide.bad).length +
          statsOfSide(kStatToggles, StatSide.good).length,
      kStatToggles.length,
    );
  });

  testWidgets('le compteur suit les bascules : défauts, puis un décochage', (
    WidgetTester tester,
  ) async {
    await open(tester);

    final int defauts = defaultEnabledStatKeys().length;
    expect(find.text(compteur(defauts)), findsOneWidget);
    expect(allumees(tester), defauts);

    // 1re bascule : « Passes réussies », activée par défaut.
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(find.text(compteur(defauts - 1)), findsOneWidget);
  });

  testWidgets(
    'anciennes clés calculées ou inconnues : ignorées par le compteur, '
    'jamais réécrites par « Valider »',
    (WidgetTester tester) async {
      final ProviderContainer container = await open(
        tester,
        keys: const <String>[
          // Défauts d'avant les stats calculées : 4 clés calculées stockées.
          'totalPasses',
          'pourcentagePasses',
          'totalTirsSubis',
          'nombreCentres',
          'passesReussies',
          'tirsCadres',
          'cleInconnue',
        ],
      );

      expect(find.byType(Switch), findsNWidgets(28));
      expect(find.text(compteur(2)), findsOneWidget);
      expect(allumees(tester), 2);

      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect(
        container.read(matchDraftProvider).enabledStatKeys,
        unorderedEquals(<String>['passesReussies', 'tirsCadres']),
      );
    },
  );

  testWidgets('aucune bascule reconnue dans le brouillon : défauts', (
    WidgetTester tester,
  ) async {
    await open(tester, keys: const <String>['totalPasses', 'cleInconnue']);

    expect(
      find.text(compteur(defaultEnabledStatKeys().length)),
      findsOneWidget,
    );
  });
}
