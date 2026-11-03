import 'dart:convert';
import 'dart:io';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wina/view/widget/login_identifier_box.dart';

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('l\'identifiant est mis en avant, expliqué et copiable', (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('fr', 'FR')],
        startLocale: const Locale('fr', 'FR'),
        path: 'assets/translations',
        assetLoader: const _DiskAssetLoader(),
        saveLocale: false,
        child: Builder(
          builder:
              (BuildContext context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const Scaffold(
                  body: LoginIdentifierBox(identifier: 'u15-lyon', help: 'Explication de connexion'),
                ),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('IDENTIFIANT DE CONNEXION'), findsOneWidget);
    expect(find.text('u15-lyon'), findsOneWidget);
    expect(find.text('Explication de connexion'), findsOneWidget);
    expect(find.text('Copier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
