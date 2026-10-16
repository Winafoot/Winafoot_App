import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/view/widget/header_divider.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(1194, 834),
  builder: (_, __) => MaterialApp(home: Scaffold(body: Center(child: child))),
);

void main() {
  testWidgets('rend un filet vertical de 1px de large', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const HeaderDivider()));
    await tester.pump();

    expect(find.byType(HeaderDivider), findsOneWidget);
    final Size size = tester.getSize(find.byType(HeaderDivider));
    expect(size.width, 1);
  });
}
