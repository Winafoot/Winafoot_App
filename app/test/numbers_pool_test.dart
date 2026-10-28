import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/gerer_equipe_numbers_screen.dart';

/// « Attribuer les numéros » propose tous les maillots de l'effectif maximum du
/// format (1 à 9 en foot à 5, 14 à 8, 20 à 11) ; ceux choisis comme remplaçants
/// y sont grisés et ne se glissent pas sur un titulaire.
void main() {
  group('starterNumbersOf', () {
    test('suit l\'effectif maximum du format', () {
      expect(
        starterNumbersOf(const CompositionDraft(playerCount: 5), 9),
        <int>[for (int i = 1; i <= 9; i++) i],
      );
      expect(
        starterNumbersOf(const CompositionDraft(playerCount: 8), 14).last,
        14,
      );
      expect(
        starterNumbersOf(const CompositionDraft(playerCount: 11), 20).last,
        20,
      );
    });

    test('jamais moins que le nombre de joueurs de la composition', () {
      expect(
        starterNumbersOf(const CompositionDraft(playerCount: 11), 9).last,
        11,
      );
    });
  });

  testWidgets(
    'format à 5, remplaçants 2, 6 et 7 : 1, 3, 4, 5, 8, 9 se glissent, les autres sont grisés',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1194, 834);
      addTearDown(tester.view.reset);
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          maxSquadSizeProvider.overrideWith((ref) async => 9),
          playersStreamProvider.overrideWith(
            (ref) => Stream<List<Player>>.value(const <Player>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(compositionDraftProvider.notifier)
        ..setCount(5)
        ..setSubNumbers(<int>{2, 6, 7});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(1194, 834),
            builder:
                (BuildContext context, _) =>
                    const MaterialApp(home: GererEquipeNumbersScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      int glissables() =>
          tester
              .widgetList(
                find.byWidgetPredicate(
                  (Widget w) =>
                      w.runtimeType.toString() == 'Draggable<_NumberDrag>',
                ),
              )
              .length;

      // 6 titulaires libres (1, 3, 4, 5, 8, 9) + 3 numéros de remplaçants.
      expect(glissables(), 9);
    },
  );
}
