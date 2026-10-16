import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/providers/home_tab_provider.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/confirm_dialog.dart';

Widget _host(Widget child, {List<Override> overrides = const <Override>[]}) =>
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: const Size(1194, 834),
        builder:
            (BuildContext context, Widget? _) =>
                MaterialApp(home: Scaffold(body: Center(child: child))),
      ),
    );

Finder _gesture() => find.descendant(
  of: find.byType(WinaWordmark),
  matching: find.byType(GestureDetector),
);

void main() {
  testWidgets('le logo porte une zone de clic par défaut', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const WinaWordmark()));
    await tester.pump();

    expect(_gesture(), findsOneWidget);
  });

  testWidgets('tappable: false rend le logo inerte', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const WinaWordmark(tappable: false)));
    await tester.pump();

    expect(_gesture(), findsNothing);
  });

  // Sans la garde de `_goHome`, le tap atteindrait `AutoRouter.of(context)`,
  // absent de ce harnais : le test lèverait. Il échoue donc si la garde saute
  // ou passe après la navigation — c'est-à-dire si un match en cours peut de
  // nouveau être quitté par le logo, sans être abandonné ni effacé.
  testWidgets('un match en cours neutralise le retour accueil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const WinaWordmark(),
        overrides: <Override>[
          liveMatchProvider.overrideWith(
            (Ref ref) => LiveMatchNotifier()..start(const GameMatch()),
          ),
        ],
      ),
    );
    await tester.pump();

    await tester.tap(_gesture());
    await tester.pump();

    expect(tester.takeException(), isNull);
    // …mais il le dit : confirmation « Quitter le match ? » plutôt qu'un logo
    // muet, sans quoi un direct resté ouvert derrière un retour système rend
    // le logo inerte partout dans l'app.
    expect(find.byType(AppConfirmDialog), findsOneWidget);
  });

  // L'accueil est un IndexedStack : depuis les onglets IA / Statistiques /
  // Test équipe, `popUntil` + `navigate(HomeRoute)` sont des non-opérations —
  // seule la remise à zéro de l'onglet ramène réellement sur « Mon équipe ».
  testWidgets('le logo remet l\'onglet courant sur « Mon équipe »', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: <Widget>[
            const WinaWordmark(),
            Consumer(
              builder:
                  (BuildContext context, WidgetRef ref, Widget? child) =>
                      Text('tab=${ref.watch(homeTabProvider)}'),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    ProviderScope.containerOf(tester.element(find.byType(WinaWordmark)))
        .read(homeTabProvider.notifier)
        .state = 3;
    await tester.pump();
    expect(find.text('tab=3'), findsOneWidget);

    await tester.tap(_gesture());
    await tester.pump();
    // `AutoRouter` est absent de ce harnais : la navigation lève, la remise à
    // zéro de l'onglet la précède.
    tester.takeException();

    expect(find.text('tab=0'), findsOneWidget);
  });
}
