import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/view/widget/app_loader.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(1194, 834),
  builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('affiche un CircularProgressIndicator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const AppLoader()));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('avec padding : entoure le loader d\'un Padding dédié', (
    WidgetTester tester,
  ) async {
    const EdgeInsets pad = EdgeInsets.all(24);
    await tester.pumpWidget(_host(const AppLoader(padding: pad)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final bool hasPad = tester
        .widgetList<Padding>(find.byType(Padding))
        .any((Padding p) => p.padding == pad);
    expect(hasPad, isTrue);
  });
}
