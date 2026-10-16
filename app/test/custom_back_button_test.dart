import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/view/widget/custom_back_button.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(1194, 834),
  builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('rend le chevron arrow_circle_left et déclenche onTap', (
    WidgetTester tester,
  ) async {
    bool tapped = false;
    await tester.pumpWidget(
      _host(CustomBackButton(onTap: () => tapped = true)),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Iconsax.arrow_circle_left), findsOneWidget);

    await tester.tap(find.byType(CustomBackButton));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
