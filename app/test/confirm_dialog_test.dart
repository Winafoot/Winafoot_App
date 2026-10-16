import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/view/widget/confirm_dialog.dart';

Widget _host({
  required VoidCallback onPrimary,
  required VoidCallback onSecondary,
}) {
  return ScreenUtilInit(
    designSize: const Size(1194, 834),
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        body: AppConfirmDialog(
          title: 'Quitter le match ?',
          message:
              'Souhaitez-vous vraiment quitter le match ? Si vous quittez '
              'maintenant le match ne sera pas enregistré.',
          primaryLabel: 'Reprendre le match',
          onPrimary: onPrimary,
          secondaryLabel: 'Quitter quand même',
          onSecondary: onSecondary,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('affiche le titre et les deux boutons', (WidgetTester tester) async {
    await tester.pumpWidget(_host(onPrimary: () {}, onSecondary: () {}));
    await tester.pumpAndSettle();

    expect(find.text('Quitter le match ?'), findsOneWidget);
    expect(find.text('Reprendre le match'), findsOneWidget);
    expect(find.text('Quitter quand même'), findsOneWidget);
  });

  testWidgets('« Quitter quand même » déclenche l\'action secondaire', (
    WidgetTester tester,
  ) async {
    bool primary = false;
    bool secondary = false;
    await tester.pumpWidget(
      _host(onPrimary: () => primary = true, onSecondary: () => secondary = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quitter quand même'));
    await tester.pump();

    expect(secondary, isTrue);
    expect(primary, isFalse);
  });

  testWidgets('« Reprendre le match » déclenche l\'action principale', (
    WidgetTester tester,
  ) async {
    bool primary = false;
    await tester.pumpWidget(
      _host(onPrimary: () => primary = true, onSecondary: () {}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reprendre le match'));
    await tester.pump();

    expect(primary, isTrue);
  });
}
