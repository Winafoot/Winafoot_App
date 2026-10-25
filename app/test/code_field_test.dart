import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/view/widget/code_field.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(1194, 834),
  builder:
      (BuildContext context, Widget? _) =>
          MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('CpCodeField ne garde que les chiffres, 6 au plus', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(_host(CpCodeField(controller: controller)));

    await tester.enterText(find.byType(TextField), '12a4-5678');

    expect(controller.text, '124567');
  });

  testWidgets('CpCodeField appelle onCompleted dès le sixième chiffre', (
    WidgetTester tester,
  ) async {
    final List<String> completed = <String>[];
    await tester.pumpWidget(
      _host(
        CpCodeField(
          controller: TextEditingController(),
          onCompleted: completed.add,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '12345');
    expect(completed, isEmpty);

    await tester.enterText(find.byType(TextField), '123456');
    expect(completed, <String>['123456']);
  });

  testWidgets('ResendCodeLink bloque le renvoi pendant le compte à rebours', (
    WidgetTester tester,
  ) async {
    int sent = 0;
    await tester.pumpWidget(
      _host(
        ResendCodeLink(
          seconds: 2,
          onResend: () async {
            sent++;
            return true;
          },
        ),
      ),
    );

    expect(find.textContaining('Renvoyer le code dans 2 s'), findsOneWidget);
    await tester.tap(find.byType(ResendCodeLink));
    await tester.pump();
    expect(sent, 0);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Renvoyer le code'), findsOneWidget);

    await tester.tap(find.byType(ResendCodeLink));
    await tester.pump();
    expect(sent, 1);
    expect(find.textContaining('Renvoyer le code dans 2 s'), findsOneWidget);

    // Laisse le compte à rebours se terminer avant la fin du test.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
}
