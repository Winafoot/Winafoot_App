import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show FakeViewPadding;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/view/page/creer_composition_screen.dart';

/// « Créer une composition » : le dialogue d'enregistrement (nom + schéma) reste
/// utilisable clavier ouvert — le bouton « Enregistrer » est atteignable, même
/// sur un petit écran où le dialogue ne tient pas au-dessus du clavier.
void main() {
  testWidgets('clavier ouvert sur petit écran : « Enregistrer » reste atteignable', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(tester.view.reset);
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(1194, 834),
          builder:
              (BuildContext context, _) =>
                  const MaterialApp(home: CreerCompositionScreen(playerCount: 11)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Ouvre le dialogue d'enregistrement (clés de traduction : pas de fichiers chargés).
    await tester.tap(find.text('app.creer-composition.cta-creer').first);
    await tester.pumpAndSettle();
    expect(find.text('utils.save'), findsOneWidget);

    // Le clavier s'ouvre sur le champ du nom.
    await tester.tap(find.byType(TextField).first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    // Le dialogue défile : on peut amener « Enregistrer » à l'écran, au-dessus du clavier.
    await tester.ensureVisible(find.text('utils.save'));
    await tester.pumpAndSettle();
    final Rect bouton = tester.getRect(find.text('utils.save'));
    expect(bouton.bottom, lessThanOrEqualTo(390 - 200));
    expect(bouton.top, greaterThanOrEqualTo(0));
  });
}
