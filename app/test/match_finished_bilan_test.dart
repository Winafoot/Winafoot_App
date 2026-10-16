import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/services/stats_pdf_export.dart';
import 'package:wina/view/page/bilan_collectif_screen.dart';
import 'package:wina/view/page/match_finished_screen.dart';
import 'package:wina/view/widget/check_profil_form.dart';

/// « Match terminé » > « Voir les statistiques » : le match transmis au bilan
/// collectif doit porter le découpage par mi-temps, comme le même match relu
/// depuis l'historique. Sans `half` ni `firstHalfStats` il passe pour un match
/// ancien : les vues 1re et 2e mi-temps seraient indisponibles.
void main() {
  testWidgets('match joué avec mi-temps : le bilan garde les 3 périodes', (
    WidgetTester tester,
  ) async {
    // Surface de la tablette de recette ; les débordements du harnais (les
    // helpers d'échelle du socle ignorent la surface simulée) sont sans
    // rapport avec ce qui est vérifié ici.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1194, 834);
    addTearDown(tester.view.reset);
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    final LiveMatchNotifier notifier = LiveMatchNotifier();

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        liveMatchProvider.overrideWith((Ref ref) => notifier),
        playersStreamProvider.overrideWith(
          (Ref ref) => Stream<List<Player>>.value(const <Player>[]),
        ),
        coachProfileProvider.overrideWith(
          (Ref ref) => Stream<CoachProfile>.value(const CoachProfile()),
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
              (BuildContext context, Widget? _) =>
                  const MaterialApp(home: MatchFinishedScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // L'écran s'ouvre sans match : son événement d'analytics d'ouverture (qui
    // exige Firebase) ne part pas. Le match est ensuite joué par le vrai
    // notifier : 2 tirs en 1re mi-temps, « Mi-temps », reprise, 1 tir en 2e.
    notifier
      ..start(const GameMatch(enabledStatKeys: <String>['tirsCadres']))
      ..selectPlayer('p1');
    void tir() => notifier.bump(
      statKey: 'tirsCadres',
      statLabel: 'Tirs cadrés',
      playerName: 'X',
      delta: 1,
    );
    tir();
    tir();
    notifier
      ..beginHalfTime()
      ..startSecondHalf();
    tir();
    await tester.pumpAndSettle();
    // Pas d'EasyLocalization dans le harnais : `.tr()` rend la clé brute. Les
    // helpers d'échelle du socle ignorent la surface simulée et rejettent la
    // colonne d'actions hors écran : on déclenche le bouton sans le toucher.
    tester
        .widget<CpButton>(
          find.widgetWithText(CpButton, 'app.match-finished.voir-statistiques'),
        )
        .onTap();
    await tester.pumpAndSettle();

    final GameMatch shown =
        tester
            .widget<BilanCollectifScreen>(find.byType(BilanCollectifScreen))
            .match;
    final GameMatch persisted = GameMatch.fromDoc(
      'm1',
      MatchRepository.finishedPayload(notifier.state!),
    );

    // Même découpage que le match relu depuis l'historique.
    for (final MatchPeriod p in MatchPeriod.values) {
      expect(
        shown.statsFor(p).status,
        persisted.statsFor(p).status,
        reason: '$p',
      );
      expect(
        shown.statsFor(p).playerStats,
        persisted.statsFor(p).playerStats,
        reason: '$p',
      );
    }
    expect(
      shown.statsFor(MatchPeriod.firstHalf).playerStats['p1'],
      <String, int>{'tirsCadres': 2},
    );
    expect(
      shown.statsFor(MatchPeriod.secondHalf).playerStats['p1'],
      <String, int>{'tirsCadres': 1},
    );

    // L'export PDF d'une mi-temps se construit (Poppins, comme l'export réel :
    // le Helvetica par défaut ne dessine pas le « — ») sur une seule page.
    final int? pages = await tester.runAsync(() async {
      final doc = buildBilanCollectifDocument(
        match: shown,
        period: MatchPeriod.firstHalf,
        ownTeam: 'Vert le grand',
        opponent: 'Villemoisson',
        theme: await poppinsPdfTheme(),
      );
      await doc.save();
      return doc.document.pdfPageList.pages.length;
    });
    expect(pages, 1);
  });
}
