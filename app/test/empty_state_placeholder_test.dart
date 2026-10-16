import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/view/widget/empty_state_placeholder.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(1194, 834),
  builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('affiche icône, titre et sous-titre', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const EmptyStatePlaceholder(
          icon: Iconsax.notification_bing,
          title: 'Aucune notification',
          subtitle: 'Vous serez notifié ici.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Iconsax.notification_bing), findsOneWidget);
    expect(find.text('Aucune notification'), findsOneWidget);
    expect(find.text('Vous serez notifié ici.'), findsOneWidget);
  });

  testWidgets('sans icône ni sous-titre : seul le titre est rendu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const EmptyStatePlaceholder(title: 'Aucun résultat')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun résultat'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });
}
