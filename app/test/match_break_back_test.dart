import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/match_break_screen.dart';

/// Le retour système Android (bouton ou geste de bord) doit faire sur l'écran
/// de coupure ce que fait la flèche d'entête. À la mi-temps, il ANNULE la
/// mi-temps : le match reste en 1re mi-temps (seul « Démarrer 2e mi-temps »,
/// confirmé, lance la 2e). En pause, il reprend le match.
void main() {
  Future<ProviderContainer> pumpBreak(
    WidgetTester tester, {
    required bool isHalfTime,
  }) async {
    // Surface de la tablette de recette ; les débordements du harnais (les
    // helpers d'échelle du socle ignorent la surface simulée) sont sans
    // rapport avec ce qui est vérifié ici.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2560, 1600);
    addTearDown(tester.view.reset);
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    final LiveMatchNotifier notifier =
        LiveMatchNotifier()
          ..start(const GameMatch(enabledStatKeys: <String>['tirsCadres']));
    // Comme le direct : « Mi-temps » ouvre la coupure, « Pause » met en pause.
    isHalfTime ? notifier.beginHalfTime() : notifier.togglePause();

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        liveMatchProvider.overrideWith((Ref ref) => notifier),
        playersStreamProvider.overrideWith(
          (Ref ref) => Stream<List<Player>>.value(const <Player>[]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(1194, 834),
          builder:
              (BuildContext context, Widget? _) => MaterialApp(
                home: Builder(
                  builder:
                      (BuildContext ctx) => Scaffold(
                        body: TextButton(
                          onPressed:
                              () => Navigator.of(ctx).push(
                                MaterialPageRoute<void>(
                                  builder:
                                      (_) => MatchBreakScreen(
                                        isHalfTime: isHalfTime,
                                      ),
                                ),
                              ),
                          child: const Text('ouvrir'),
                        ),
                      ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.byType(MatchBreakScreen), findsOneWidget);
    return container;
  }

  testWidgets('retour système à la mi-temps : le match reste en 1re mi-temps', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpBreak(
      tester,
      isHalfTime: true,
    );
    expect(container.read(liveMatchProvider)!.half, 1);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final LiveMatch live = container.read(liveMatchProvider)!;
    expect(live.half, 1);
    expect(live.isLive, isTrue);
    expect(live.halfTimeStatKeys, isNull);
    expect(find.byType(MatchBreakScreen), findsNothing);
  });

  testWidgets('retour système en pause : le match reprend', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpBreak(
      tester,
      isHalfTime: false,
    );
    expect(container.read(liveMatchProvider)!.isPaused, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final LiveMatch live = container.read(liveMatchProvider)!;
    expect(live.isLive, isTrue);
    expect(live.half, 1);
    expect(find.byType(MatchBreakScreen), findsNothing);
  });
}
