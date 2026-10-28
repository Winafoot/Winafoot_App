import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show FakeViewPadding;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/player.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/player_form.dart';

/// Formulaires sur un petit écran : ils tiennent sans défilement (réduits si
/// besoin) et l'ouverture du clavier ne les fait pas rétrécir — le contenu
/// défile pour laisser la place.
void main() {
  void useScreen(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  Widget host(Widget home, Size design) => ProviderScope(
    child: ScreenUtilInit(
      designSize: design,
      builder: (BuildContext context, _) => MaterialApp(home: home),
    ),
  );

  double maxScroll(WidgetTester tester) =>
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .maxScrollExtent;

  testWidgets('« Modifier joueur » : pas de défilement sur téléphone paysage', (
    WidgetTester tester,
  ) async {
    useScreen(tester, const Size(844, 390));
    await tester.pumpWidget(
      host(
        PlayerFormScaffold(
          title: 'Modifier un joueur',
          form: PlayerForm(
            initialFirstName: 'Jean',
            initialLastName: 'Dupont',
            initialFoot: StrongFoot.droit,
            initialPosition: PlayerPosition.milieu,
            submitLabel: 'Valider',
            onSubmit: (String a, String b, StrongFoot c, PlayerPosition d) async {},
          ),
        ),
        const Size(1194, 834),
      ),
    );
    await tester.pumpAndSettle();

    expect(maxScroll(tester), 0);
  });

  testWidgets('« Modifier joueur » : le clavier ne fait pas rétrécir le formulaire', (
    WidgetTester tester,
  ) async {
    useScreen(tester, const Size(844, 390));
    await tester.pumpWidget(
      host(
        PlayerFormScaffold(
          title: 'Modifier un joueur',
          form: PlayerForm(
            submitLabel: 'Valider',
            onSubmit: (String a, String b, StrongFoot c, PlayerPosition d) async {},
          ),
        ),
        const Size(1194, 834),
      ),
    );
    await tester.pumpAndSettle();
    final Size avant = tester.getSize(find.byType(PlayerForm));

    tester.view.viewInsets = const FakeViewPadding(bottom: 160);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PlayerForm)), avant);
    // Le contenu défile pour laisser la place au clavier.
    expect(maxScroll(tester), greaterThan(0));
  });

  testWidgets('inscription (portrait) : le clavier ne fait pas rétrécir la carte', (
    WidgetTester tester,
  ) async {
    useScreen(tester, const Size(390, 844));
    await tester.pumpWidget(
      host(
        CheckProfilScaffold(
          title: 'Créer mon compte',
          portraitOnPhone: true,
          // Assez de champs pour que la carte ne tienne plus dans l'écran réduit par le clavier.
          children: <Widget>[
            for (int i = 0; i < 6; i++) ...<Widget>[
              CpLabel('Champ $i'),
              CpTextField(controller: TextEditingController(), hint: 'champ'),
            ],
          ],
        ),
        const Size(390, 844),
      ),
    );
    await tester.pumpAndSettle();
    final Size avant = tester.getSize(find.byType(CpTextField).first);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(CpTextField).first), avant);

    // L'écran portrait verrouille l'orientation : on laisse son minuteur se terminer.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
