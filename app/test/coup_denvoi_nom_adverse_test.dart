import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/view/page/coup_denvoi_step1_screen.dart';

/// Champ du nom adverse. Il s'affiche sur deux lignes au plus,
/// mais doit rester un champ mono-ligne à la saisie : sans
/// `textInputAction: done`, `maxLines: 2` en fait un champ multi-lignes et
/// Entrée insère un saut de ligne dans le nom.
Widget _host() => ProviderScope(
  overrides: <Override>[
    coachProfileProvider.overrideWith(
      (ref) => const Stream<CoachProfile>.empty(),
    ),
  ],
  child: ScreenUtilInit(
    designSize: const Size(1194, 834),
    builder: (_, _) => const MaterialApp(home: CoupDEnvoiStep1Screen()),
  ),
);

void main() {
  testWidgets('le nom adverse valide à Entrée, sans saut de ligne', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump();

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textInputAction, TextInputAction.done);
    expect(field.maxLength, 40);
  });
}
