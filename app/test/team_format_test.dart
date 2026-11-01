import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/coup_denvoi_step3_screen.dart';
import 'package:wina/view/page/gerer_equipe_numbers_screen.dart';
import 'package:wina/view/page/test_equipe_screen.dart';

/// Format du club (`users/{uid}.teamFormat`, posé par le back-office) : il fixe
/// le plafond d'effectif (5 → 9, 8 → 14, 11 → 20) et dispense le coach de
/// choisir le nombre de joueurs. Sans lui, comportement historique inchangé.
void main() {
  group('lecture de teamFormat', () {
    PlayerCount? parse(Object? raw) =>
        CoachProfile.fromJson(<String, dynamic>{'teamFormat': raw}).teamFormat;

    test('5, 8 et 11 sont reconnus', () {
      expect(parse(5), PlayerCount.five);
      expect(parse(8), PlayerCount.eight);
      expect(parse(11), PlayerCount.eleven);
    });

    test('absent ou invalide → null, jamais une valeur devinée', () {
      expect(
        CoachProfile.fromJson(const <String, dynamic>{}).teamFormat,
        isNull,
      );
      for (final Object? bad in <Object?>[null, 0, 7, 9, 20, -5, '5', true]) {
        expect(parse(bad), isNull, reason: '$bad');
      }
    });

    test('le plafond dérive du format : 5 → 9, 8 → 14, 11 → 20', () {
      expect(PlayerCount.five.maxSquadSize, 9);
      expect(PlayerCount.eight.maxSquadSize, 14);
      expect(PlayerCount.eleven.maxSquadSize, 20);
    });
  });

  group('plafond d\'effectif', () {
    // Deux comptes dans la même session : le plafond doit suivre celui qui est
    // connecté (l'ancien cache statique servait le plafond du premier au
    // second). Le profil de chaque uid est simulé ; sans format, la lecture de
    // app_config échoue faute de Firebase et retombe sur le repli, 20.
    final Map<String?, CoachProfile> profiles = <String?, CoachProfile>{
      'club5': const CoachProfile(teamFormat: PlayerCount.five),
      'club8': const CoachProfile(teamFormat: PlayerCount.eight),
      'ancien': const CoachProfile(),
      null: const CoachProfile(),
    };

    ProviderContainer containerFor(
      Stream<String?> uids, {
      Stream<CoachProfile> Function(String? uid)? profileOf,
    }) {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          authUidProvider.overrideWith((ref) => uids),
          coachProfileProvider.overrideWith((ref) {
            final String? uid = ref.watch(authUidProvider).valueOrNull;
            return profileOf?.call(uid) ??
                Stream<CoachProfile>.value(profiles[uid]!);
          }),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<int> cap(ProviderContainer c) async {
      await c.read(coachProfileProvider.future);
      return c.read(maxSquadSizeProvider.future);
    }

    test('format connu → plafond dérivé', () async {
      final ProviderContainer c = containerFor(Stream.value('club5'));
      await c.read(authUidProvider.future);
      expect(await cap(c), 9);
    });

    test('sans format → repli 20, jamais 9', () async {
      final ProviderContainer c = containerFor(Stream.value('ancien'));
      await c.read(authUidProvider.future);
      expect(await cap(c), kMaxSquadSize);
    });

    test('le plafond du premier compte ne fuit pas vers le second', () async {
      final StreamController<String?> uids = StreamController<String?>();
      addTearDown(uids.close);
      final ProviderContainer c = containerFor(uids.stream);
      c.listen(maxSquadSizeProvider, (_, _) {});

      uids.add('club5');
      await pumpEventQueue();
      expect(await cap(c), 9);

      // Déconnexion puis connexion d'un compte sans format.
      uids.add(null);
      await pumpEventQueue();
      uids.add('ancien');
      await pumpEventQueue();
      expect(await cap(c), kMaxSquadSize);

      // Un autre club, d'un autre format.
      uids.add('club8');
      await pumpEventQueue();
      expect(await cap(c), 14);
    });

    test('changement de compte direct : pas de format hérité pendant le '
        'chargement du profil', () async {
      final StreamController<String?> uids = StreamController<String?>();
      final StreamController<CoachProfile> slow =
          StreamController<CoachProfile>();
      addTearDown(uids.close);
      addTearDown(slow.close);
      final ProviderContainer c = containerFor(
        uids.stream,
        profileOf:
            (String? uid) =>
                uid == 'ancien'
                    ? slow.stream
                    : Stream<CoachProfile>.value(profiles[uid]!),
      );
      c.listen(teamFormatProvider, (_, _) {});

      uids.add('club5');
      await pumpEventQueue();
      expect(c.read(teamFormatProvider), PlayerCount.five);

      // Le profil du second compte n'est pas encore arrivé.
      uids.add('ancien');
      await pumpEventQueue();
      expect(c.read(teamFormatProvider), isNull);
    });
  });

  group('« Gérer mon équipe » : le format du club remplace le choix', () {
    // Plus d'écran de choix ni de popup préalable : le bouton « Ajouter les
    // remplaçants » de l'écran des numéros ouvre le choix de leurs numéros.
    const String popupTitle =
        'app.gerer-equipe-numbers.selectionner-numeros-remplacants';
    const String countTitle = 'app.gerer-equipe-count.titre';
    const String hubButton = 'app.coup-denvoi-step3.gerer-equipe';

    late ProviderContainer container;

    Future<void> pumpHub(WidgetTester tester, PlayerCount? format) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1194, 834);
      addTearDown(tester.view.reset);
      // Les helpers de mise à l'échelle du socle ne suivent pas la surface
      // simulée : artefact de harnais, sans rapport avec ce qui est vérifié.
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      container = ProviderContainer(
        overrides: <Override>[
          authUidProvider.overrideWith((ref) => Stream<String?>.value(null)),
          coachProfileProvider.overrideWith(
            (ref) =>
                Stream<CoachProfile>.value(CoachProfile(teamFormat: format)),
          ),
          playersStreamProvider.overrideWith(
            (ref) => Stream<List<Player>>.value(const <Player>[]),
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
                (BuildContext context, _) =>
                    const MaterialApp(home: CoupDEnvoiStep3Screen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("format 5 : directement l'écran des numéros, sans popup", (
      WidgetTester tester,
    ) async {
      await pumpHub(tester, PlayerCount.five);
      await tester.tap(find.text(hubButton));
      await tester.pumpAndSettle();

      expect(find.text(countTitle), findsNothing);
      expect(find.text(popupTitle), findsNothing);
      expect(find.byType(GererEquipeNumbersScreen), findsOneWidget);
      expect(container.read(compositionDraftProvider).playerCount, 5);

      // Les remplaçants s'ajoutent depuis l'écran lui-même.
      await tester.tap(
        find.text('app.gerer-equipe-numbers.ajouter-remplacants'),
      );
      await tester.pumpAndSettle();
      expect(find.text(popupTitle), findsOneWidget);
    });

    testWidgets('format 8 : imposé au brouillon', (WidgetTester tester) async {
      await pumpHub(tester, PlayerCount.eight);
      await tester.tap(find.text(hubButton));
      await tester.pumpAndSettle();

      expect(find.byType(GererEquipeNumbersScreen), findsOneWidget);
      expect(container.read(compositionDraftProvider).playerCount, 8);
    });

    testWidgets("sans format : plus d'écran de choix, foot à 11 par défaut", (
      WidgetTester tester,
    ) async {
      await pumpHub(tester, null);
      await tester.tap(find.text(hubButton));
      await tester.pumpAndSettle();

      expect(find.text(countTitle), findsNothing);
      expect(find.byType(GererEquipeNumbersScreen), findsOneWidget);
      expect(container.read(compositionDraftProvider).playerCount, 11);
    });
  });

  group('onglet « Test équipe »', () {
    // Le nombre de joueurs est imposé par le club : plus de filtre « Type
    // d'équipe », et les schémas affichés sont ceux de son format.
    const String filterLabel = 'app.test-equipe.type-equipe';

    Future<void> pumpTab(WidgetTester tester, PlayerCount? format) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(2560, 1600);
      addTearDown(tester.view.reset);
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            authUidProvider.overrideWith((ref) => Stream<String?>.value(null)),
            coachProfileProvider.overrideWith(
              (ref) =>
                  Stream<CoachProfile>.value(CoachProfile(teamFormat: format)),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(1194, 834),
            builder:
                (BuildContext context, _) =>
                    const MaterialApp(home: Scaffold(body: TestEquipeScreen())),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('format connu : pas de filtre, schémas du format', (
      WidgetTester tester,
    ) async {
      await pumpTab(tester, PlayerCount.five);
      expect(find.text(filterLabel), findsNothing);
      // 2-2 n'existe qu'à 5 ; 4-4-2 n'existe qu'à 11.
      expect(find.text('2-2'), findsWidgets);
      expect(find.text('4-4-2'), findsNothing);
    });

    testWidgets('sans format : le filtre reste, à 11 par défaut', (
      WidgetTester tester,
    ) async {
      await pumpTab(tester, null);
      expect(find.text(filterLabel), findsOneWidget);
      expect(find.text('4-4-2'), findsWidgets);
    });
  });

  group('enregistrement du profil', () {
    // Un `set()` sans merge sur users/{uid} réécrit tout le document : le champ
    // teamFormat disparaîtrait, et les règles Firestore refusent qu'un coach le
    // modifie ou le supprime. Il ne peut qu'être ajouté une fois (coach inscrit
    // depuis l'app), jamais écrasé. Ni Firestore ni ses fakes ne sont
    // disponibles ici : on garde donc l'invariant au niveau du source.
    test('saveTeamInfo fusionne et n\'écrit teamFormat que s\'il est fourni', () {
      final String src =
          File('lib/data/coach_profile_repository.dart').readAsStringSync();
      final RegExpMatch? save = RegExp(
        r'static Future<void> saveTeamInfo\([\s\S]*?\r?\n  \}\r?\n',
      ).firstMatch(src);
      expect(save, isNotNull);
      expect(save![0], contains('SetOptions(merge: true)'));
      expect(save[0], contains("if (teamFormat != null) 'teamFormat'"));
    });

    test('teamFormat n\'est écrit que par les dépôts prévus', () {
      // Une écriture poserait la clé dans un littéral de Map (`'teamFormat':`),
      // une lecture l'indexe (`['teamFormat']`). Autorisés : le profil du coach
      // (ajout unique) et les équipes liées, créées côté serveur (autre compte).
      const Set<String> allowed = <String>{
        'lib/data/coach_profile_repository.dart',
        'lib/data/linked_team_repository.dart',
        'lib/view/page/creer_equipe_liee_screen.dart',
      };
      final RegExp writes = RegExp('''['"]teamFormat['"]\\s*:''');
      final List<String> offenders = <String>[
        for (final Directory root in <Directory>[
          Directory('lib'),
          Directory('packages'),
        ])
          for (final FileSystemEntity f in root.listSync(recursive: true))
            if (f is File &&
                f.path.endsWith('.dart') &&
                !allowed.contains(f.path.replaceAll('\\', '/')) &&
                writes.hasMatch(f.readAsStringSync()))
              f.path,
      ];
      expect(offenders, isEmpty);
    });
  });
}
