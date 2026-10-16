import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/view/page/settings/settings_node.dart';
import 'package:wina/view/page/settings/settings_page.dart';

/// Hôte minimal : un pane custom dont le contenu est plus haut que la fenêtre
/// disponible, ce qui reproduit la situation « clavier ouvert ».
Widget _host(WidgetBuilder contentBuilder) {
  return ScreenUtilInit(
    designSize: const Size(1194, 834),
    builder:
        (_, __) => MaterialApp(
          home: Scaffold(
            body: SettingsView(
              items: [
                SettingsItem(
                  title: 'Mon compte',
                  children: [
                    SettingsNode(
                      title: 'Sécurité',
                      contentBuilder: contentBuilder,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
  );
}

/// Contenu haut, mais dimensionné intrinsèquement : cas nominal.
Widget _tallColumn(BuildContext _) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: List<Widget>.generate(
      8,
      (int i) => SizedBox(height: 80, child: Text('champ $i')),
    ),
  );
}

void main() {
  testWidgets("le pane ne déborde pas quand la hauteur disponible est réduite "
      "(clavier ouvert)", (WidgetTester tester) async {
    // Fenêtre volontairement courte : 8 x 80 px de contenu ne tiennent pas.
    tester.view.physicalSize = const Size(1194, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_tallColumn));
    await tester.pumpAndSettle();

    // Ouvre le pane custom.
    await tester.tap(find.text('Sécurité'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // Le pane est déjà défilant : sa hauteur est infinie, donc un contentBuilder
  // qui renvoie un enfant flex (Expanded) lève une erreur de contraintes en
  // debug et rien du pane n'est peint. Ce test fige le contrat sur le
  // constructeur réel des panes « liens légaux », et vérifie au passage que la
  // page reste lisible quand le contenu Firestore est absent ou vide.
  testWidgets("le pane d'un lien légal s'affiche même sans contenu", (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final String? contenu in <String?>[null, '', '   ']) {
      await tester.pumpWidget(_host((_) => legalPaneContent(contenu)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sécurité').first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'contenu = $contenu');
      // `.last` = le titre DANS le pane (`.first` est la cellule de la colonne
      // de gauche, dimensionnée quoi qu'il arrive) : si la mise en page casse,
      // plus rien du pane n'est peint et cette taille est indisponible.
      expect(tester.getSize(find.text('Sécurité').last).height, greaterThan(0));
      // Repli affiché à la place d'un HtmlWidget vide.
      expect(_htmlTexts(tester), contains('bar.settings.no-content'));
    }

    // Et un contenu réel n'est pas remplacé par le repli.
    await tester.pumpWidget(
      _host((_) => legalPaneContent('<p>Mentions légales</p>')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sécurité').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_htmlTexts(tester), contains('Mentions légales'));
  });

  // Contrôle négatif : sans lui, les deux tests ci-dessus passeraient même si
  // l'hôte cessait de reproduire le défaut. Il fige le contrat du pane —
  // hauteur infinie, donc aucun enfant flex — que `legalPaneContent` respecte.
  testWidgets('un enfant flex dans un pane lève bien une erreur', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host((_) => const Expanded(child: Text('x'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sécurité').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNotNull);
  });
}

/// Textes rendus par les HtmlWidget du pane (ils produisent des RichText, que
/// find.text ne sait pas atteindre).
List<String> _htmlTexts(WidgetTester tester) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .map((RichText w) => w.text.toPlainText())
      .toList();
}
