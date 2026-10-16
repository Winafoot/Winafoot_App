import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/view/widget/jersey_form.dart';
import 'package:wina/view/widget/match_wizard.dart';

/// On monte `LabeledPillDropdown` seul plutôt que `CoupDEnvoiStep2Screen` :
/// cet écran observe `jerseysProvider`, qui remonte jusqu'à FirebaseAuth. Il
/// faudrait trois overrides pour tester une seule ligne de rendu.
Widget _host({bool withThumbnail = true}) => ScreenUtilInit(
  designSize: const Size(1194, 834),
  builder:
      (_, _) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: LabeledPillDropdown<JerseyColorOption>(
                label: 'Couleur du maillot',
                value: JerseyColorOption.blanc,
                values: JerseyColorOption.values,
                labelOf: (JerseyColorOption c) => c.label,
                leadingOf:
                    withThumbnail
                        ? (JerseyColorOption c) => ShirtIcon(asset: c.asset)
                        : null,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
);

void main() {
  testWidgets(
    'le sélecteur de maillot adverse affiche une vignette par couleur',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1194, 834);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());
      await tester.pump();

      await tester.tap(find.byType(DropdownButton<JerseyColorOption>));
      await tester.pumpAndSettle();

      // Sans `leadingOf` branché, ce compte vaut 0 : c'est l'assertion qui
      // échoue avant le correctif et qu'aucun accident ne peut satisfaire.
      expect(
        find.byType(ShirtIcon),
        findsAtLeastNWidgets(JerseyColorOption.values.length),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sans leadingOf, le dropdown reste inchangé (catégorie, division, effectif)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1194, 834);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(withThumbnail: false));
      await tester.pump();

      await tester.tap(find.byType(DropdownButton<JerseyColorOption>));
      await tester.pumpAndSettle();

      // Les 3 autres appelants du widget ne passent rien : aucun visuel ne
      // doit apparaître, et la disposition ne doit pas déborder.
      expect(find.byType(ShirtIcon), findsNothing);
      expect(find.text(JerseyColorOption.blanc.label), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
