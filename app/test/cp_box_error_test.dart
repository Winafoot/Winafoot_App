import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/check_profil_form.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(1194, 834),
  builder:
      (BuildContext context, Widget? _) =>
          MaterialApp(home: Scaffold(body: child)),
);

Border _borderOf(WidgetTester tester) {
  final Container box = tester.widget<Container>(
    find.descendant(of: find.byType(CpBox), matching: find.byType(Container)),
  );
  return (box.decoration! as BoxDecoration).border! as Border;
}

void main() {
  testWidgets('CpBox garde la bordure grise par défaut', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const CpBox(child: SizedBox())));
    await tester.pumpAndSettle();

    expect(_borderOf(tester).top.color, AppColor.divider);
  });

  testWidgets('CpBox passe la bordure au rouge quand error est vrai', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const CpBox(error: true, child: SizedBox())));
    await tester.pumpAndSettle();

    expect(_borderOf(tester).top.color, DefaultColor.error);
  });
}
