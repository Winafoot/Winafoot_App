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

/// Vrais libellés fr-FR (lus sur disque) : sans eux `.tr()` rend la clé brute
/// et le compteur « X / 37 sélectionnées » n'est pas vérifiable.
class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// Écran « Paramétrez les statistiques » : 37 bascules (les 5 stats calculées
/// n'en sont pas), un titre par thème, chaque thème entier dans une seule des 3
/// colonnes, et un compteur qui ne compte que les bascules.
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

  String compteur(int n) => '$n / 37 sélectionnées';

  int allumees(WidgetTester tester) =>
      tester
          .widgetList<Switch>(find.byType(Switch))
          .where((Switch s) => s.value)
          .length;

  testWidgets('37 bascules : les 5 stats calculées n\'y figurent pas', (
    WidgetTester tester,
  ) async {
    await open(tester);

    expect(find.byType(Switch), findsNWidgets(37));
    for (final StatDef s in kStatCatalog) {
      expect(
        find.text(s.label),
        s.isCalculated ? findsNothing : findsOneWidget,
        reason: s.label,
      );
    }
  });

  testWidgets('chaque thème reste entier dans une colonne, sous son titre', (
    WidgetTester tester,
  ) async {
    await open(tester);

    final Map<StatCategory, Offset> titre = <StatCategory, Offset>{
      for (final StatCategory c in StatCategory.values)
        c: tester.getTopLeft(find.text(c.label)),
    };

    // 3 colonnes ; les titres lus colonne par colonne, de haut en bas, suivent
    // l'ordre des thèmes du client.
    expect(<int>{
      for (final Offset o in titre.values) o.dx.round(),
    }, hasLength(3));
    final List<StatCategory> lecture =
        StatCategory.values.toList()..sort((StatCategory a, StatCategory b) {
          final int parColonne = titre[a]!.dx.compareTo(titre[b]!.dx);
          return parColonne != 0
              ? parColonne
              : titre[a]!.dy.compareTo(titre[b]!.dy);
        });
    expect(lecture, StatCategory.values);

    // Chaque bascule a, pour titre le plus proche au-dessus dans sa colonne,
    // celui de son propre thème : aucun thème coupé ni entrelacé.
    for (final StatDef s in kStatToggles) {
      final Offset label = tester.getTopLeft(find.text(s.label));
      final StatCategory? titreAuDessus =
          (titre.entries
                  .where(
                    (MapEntry<StatCategory, Offset> e) =>
                        (e.value.dx - label.dx).abs() < 60 &&
                        e.value.dy < label.dy,
                  )
                  .toList()
                ..sort(
                  (
                    MapEntry<StatCategory, Offset> a,
                    MapEntry<StatCategory, Offset> b,
                  ) => b.value.dy.compareTo(a.value.dy),
                ))
              .firstOrNull
              ?.key;
      expect(titreAuDessus, s.category, reason: s.label);
    }
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

      expect(find.byType(Switch), findsNWidgets(37));
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
