import 'dart:convert';
import 'dart:io';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/view/page/gerer_maillots_screen.dart';

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

Widget _host() => ProviderScope(
  overrides: <Override>[
    jerseysProvider.overrideWith(
      (ref) => Stream<List<Jersey>>.value(const <Jersey>[
        Jersey(name: 'Domicile', color: JerseyColorOption.bleu),
        Jersey(name: 'Extérieur', color: JerseyColorOption.rouge),
      ]),
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
            home: const GererMaillotsScreen(),
          ),
    ),
  ),
);

/// Téléphone en paysage, comme l'app l'utilise (~800 × 360 dp).
void _phoneLandscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 360);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('téléphone : l\'écran des maillots s\'affiche sans erreur', (
    WidgetTester tester,
  ) async {
    _phoneLandscape(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Domicile'), findsOneWidget);
  });

  testWidgets('téléphone : modifier et supprimer sont touchables', (
    WidgetTester tester,
  ) async {
    _phoneLandscape(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final Finder edit = find.byIcon(Iconsax.edit_2).first;
    final Finder trash = find.byIcon(Iconsax.trash).first;
    final Size screen = tester.view.physicalSize;
    for (final Finder f in <Finder>[edit, trash]) {
      expect(f, findsOneWidget);
      final Offset c = tester.getCenter(f);
      expect(
        Rect.fromLTWH(0, 0, screen.width, screen.height).contains(c),
        isTrue,
        reason: 'l\'icône doit être dans l\'écran, elle est en $c',
      );
      // Un toucher à cet endroit atteint bien l'icône (rien ne la recouvre ni ne la coupe).
      expect(f.hitTestable(), findsOneWidget);
    }
  });

  testWidgets("téléphone : les fenêtres Modifier et Supprimer s'ouvrent sans erreur", (
    WidgetTester tester,
  ) async {
    _phoneLandscape(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Iconsax.edit_2).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Dialog), findsOneWidget);
    // Les boutons de la fenêtre restent atteignables malgré la faible hauteur d'un téléphone en paysage.
    expect(find.text('Annuler').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Iconsax.trash).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Dialog), findsOneWidget);
  });
}
