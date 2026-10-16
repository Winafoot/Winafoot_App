import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:skeleton/view/widget/parent/auth_parent.dart';

/// Fond « terrain » de l'écran de connexion.
///
/// Le socle expose le crochet de thème `emailLoginPageBackground`, que
/// `LoginPage` transmet à `AuthParent.backgroundPage`. Mais `AuthParent` ne
/// rendait ce fond que dans sa branche `_buildPhone`, atteinte uniquement en
/// dessous de 800 dp de large. Wina étant verrouillée en paysage sur un
/// gabarit 1194x834, elle passe toujours par `_buildWeb` : le crochet était
/// structurellement inopérant et l'écran restait gris uni.
///
/// Le correctif est une modification locale du skeleton intégré au dépôt
/// (packages/README.md). Ce test en est le garde-fou : il échoue si le
/// skeleton d'origine est repris sans cette modification.
void main() {
  // `AuthParent.init()` ne renseigne `lightTheme` que si un `AppTheme` est
  // enregistre dans GetIt ; sans lui le champ `late` du socle leve. On fournit
  // donc le minimum, comme le fait `Application.launch` en production.
  setUp(() {
    if (!GetIt.instance.isRegistered<AppTheme>()) {
      GetIt.instance.registerSingleton<AppTheme>(
        AppTheme(themeData: ThemeData.light(), themeDataDark: ThemeData.dark()),
      );
    }
    // `AuthParent.config` lit `getAppModel()` : sans lui, GetIt leve avant
    // meme d'atteindre le rendu du fond.
    if (!GetIt.instance.isRegistered<AppModel>()) {
      GetIt.instance.registerSingleton<AppModel>(
        AppModel<Object?>(
          appTitle: 'test',
          userConfig: UserConfig<Object?>(
            fromJson: (Map<String, dynamic>? json, String? userType) => null,
          ),
        ),
      );
    }
  });

  testWidgets('AuthParent rend backgroundPage sur un gabarit tablette', (
    WidgetTester tester,
  ) async {
    // Surface réelle de la tablette de recette : bien au-dessus de la balise
    // PHONE (800 dp), donc branche `_buildWeb`.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1194, 834);
    addTearDown(tester.view.reset);

    final Key background = UniqueKey();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          // `AuthParent.build` passe par `getResponsiveValue`, qui exige un
          // `ResponsiveWrapper` ancetre. On reprend la configuration reelle de
          // l'app (breakpoints par defaut, PHONE a 800 dp) : c'est elle qui
          // fait tomber Wina dans `_buildWeb` et non `_buildPhone`.
          builder: (BuildContext context, Widget? child) =>
              ResponsiveWrapper.builder(
            child,
            minWidth: 450,
            breakpoints: const <ResponsiveBreakpoint>[
              ResponsiveBreakpoint.tag(800, name: PHONE),
              ResponsiveBreakpoint.tag(1100, name: TABLET),
              ResponsiveBreakpoint.tag(double.infinity, name: DESKTOP),
            ],
          ),
          home: AuthParent(
            showBackButton: false,
            backgroundPage: Container(key: background, color: Colors.green),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(background),
      findsOneWidget,
      reason:
          'Le fond fourni à AuthParent.backgroundPage n\'est pas rendu : la '
          'modification locale du skeleton (packages/README.md) a été perdue.',
    );
  });
}
