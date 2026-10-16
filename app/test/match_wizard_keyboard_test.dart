import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/view/widget/match_wizard.dart';

/// Le `Scaffold` extérieur reproduit l'imbrication réelle : les étapes sont
/// poussées sous le `Scaffold(body: AutoRouter())` du skeleton, qui remet
/// l'inset clavier de son body à zéro. Sans lui, un test passerait sur une
/// lecture `MediaQuery` que la production ne voit jamais.
Widget _host({double childHeight = 300}) => ScreenUtilInit(
  designSize: const Size(1194, 834),
  builder:
      (_, _) => MaterialApp(
        home: Scaffold(
          body: MatchWizardScaffold(
            title: 'Choix de l\'adversaire',
            bottomCta: const SizedBox(height: 52, width: 200),
            child: Center(
              child: Container(height: childHeight, color: Colors.green),
            ),
          ),
        ),
      ),
);

double _maxScroll(WidgetTester tester) =>
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .maxScrollExtent;

void main() {
  testWidgets('clavier fermé : le contenu ne défile pas (rendu inchangé)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump();

    expect(_maxScroll(tester), 0);
  });

  testWidgets('clavier ouvert : le contenu défile au lieu de déborder', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump();

    expect(_maxScroll(tester), greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('clavier ouvert, contenu court : le CTA flottant est dégagé', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(childHeight: 10));
    await tester.pump();

    // Le contenu tient dans le viewport : le seul défilement possible est le
    // dégagement de 92 dp. À 0, la branche est morte (défaut d'origine).
    expect(_maxScroll(tester), 92);
  });
}
