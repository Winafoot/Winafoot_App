import 'dart:convert';
import 'dart:io';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/billing/access_info.dart';
import 'package:wina/data/linked_team_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/creer_equipe_liee_screen.dart';
import 'package:wina/view/page/mes_equipes_screen.dart';

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync()) as Map<String, dynamic>;
}

/// Propriétaire dont l'abonnement est actif et qui a droit à [teamsAllowed] équipes au total.
AccessInfo _owner(int teamsAllowed) => AccessInfo(
  active: true,
  until: DateTime.now().add(const Duration(days: 30)),
  teamsAllowed: teamsAllowed,
);

Widget _host(
  Widget home, {
  List<LinkedTeam> linked = const <LinkedTeam>[],
  int teamsAllowed = 2,
  CreateLinkedTeamFn? onCreate,
  CoachProfile profile = const CoachProfile(teamName: 'FC Principal'),
  List<Player> players = const <Player>[],
}) => ProviderScope(
  overrides: <Override>[
    authUidProvider.overrideWith((ref) => Stream<String?>.value('u1')),
    accessInfoProvider.overrideWith((ref) => Stream<AccessInfo?>.value(_owner(teamsAllowed))),
    linkedTeamsProvider.overrideWith((ref) => Stream<List<LinkedTeam>>.value(linked)),
    coachProfileProvider.overrideWith((ref) => Stream<CoachProfile>.value(profile)),
    playersStreamProvider.overrideWith((ref) => Stream<List<Player>>.value(players)),
    createLinkedTeamProvider.overrideWithValue(onCreate ?? (Map<String, Object?> _) async {}),
  ],
  child: EasyLocalization(
    supportedLocales: const <Locale>[Locale('fr', 'FR')],
    startLocale: const Locale('fr', 'FR'),
    path: 'assets/translations',
    assetLoader: const _DiskAssetLoader(),
    saveLocale: false,
    child: ScreenUtilInit(
      designSize: const Size(1194, 834),
      builder: (BuildContext context, _) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        // La bannière de notification (NotifBanner) exige un ResponsiveWrapper, présent dans l'app réelle.
        builder: (BuildContext ctx, Widget? child) => ResponsiveWrapper.builder(
          child,
          minWidth: 450,
          breakpoints: const <ResponsiveBreakpoint>[
            ResponsiveBreakpoint.tag(800, name: PHONE),
            ResponsiveBreakpoint.tag(1100, name: TABLET),
            ResponsiveBreakpoint.tag(double.infinity, name: DESKTOP),
          ],
        ),
        home: home,
      ),
    ),
  ),
);

void _tablet(WidgetTester tester) {
  tester.view.physicalSize = const Size(1194, 834);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _fill(WidgetTester tester, {String identifier = 'u15-lyon', String password = 'Wina!2345'}) async {
  await tester.enterText(find.byKey(const Key('team-identifier')), identifier);
  await tester.enterText(find.byKey(const Key('team-password')), password);
  await tester.enterText(find.byKey(const Key('team-name')), 'U15 Lyon');
  // Le formulaire dépasse la hauteur de la tablette : on fait défiler jusqu'au bouton.
  await tester.ensureVisible(find.text("Créer l'équipe"));
  await tester.pumpAndSettle();
  await tester.tap(find.text("Créer l'équipe"));
  await tester.pumpAndSettle();
}

void main() {
  group('CreerEquipeLieeScreen : validation locale', () {
    testWidgets('refuse un identifiant invalide sans appeler le serveur', (WidgetTester tester) async {
      _tablet(tester);
      final List<Map<String, Object?>> calls = <Map<String, Object?>>[];
      await tester.pumpWidget(
        _host(const CreerEquipeLieeScreen(), onCreate: (Map<String, Object?> a) async => calls.add(a)),
      );
      await tester.pumpAndSettle();

      await _fill(tester, identifier: 'AB');

      expect(find.text('Identifiant invalide.'), findsOneWidget);
      expect(calls, isEmpty);
    });

    testWidgets('refuse un mot de passe hors politique', (WidgetTester tester) async {
      _tablet(tester);
      final List<Map<String, Object?>> calls = <Map<String, Object?>>[];
      await tester.pumpWidget(
        _host(const CreerEquipeLieeScreen(), onCreate: (Map<String, Object?> a) async => calls.add(a)),
      );
      await tester.pumpAndSettle();

      await _fill(tester, password: 'faible');

      expect(calls, isEmpty);
    });

    testWidgets("envoie les données et ferme l'écran quand tout est valide", (WidgetTester tester) async {
      _tablet(tester);
      final List<Map<String, Object?>> calls = <Map<String, Object?>>[];
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const CreerEquipeLieeScreen())),
              child: const Text('OUVRIR'),
            ),
          ),
          onCreate: (Map<String, Object?> a) async => calls.add(a),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OUVRIR'));
      await tester.pumpAndSettle();

      // L'identifiant saisi en majuscules est envoyé en minuscules.
      await _fill(tester, identifier: 'U15-Lyon');

      expect(calls, hasLength(1));
      expect(calls.single['identifier'], 'u15-lyon');
      expect(calls.single['teamName'], 'U15 Lyon');
      expect(<int>[5, 8, 11], contains(calls.single['teamFormat']));
      expect(find.byType(CreerEquipeLieeScreen), findsNothing);
      // Laisse expirer la bannière de confirmation (minuteur de 3 s).
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets("formule à 3 équipes : l'écran reste ouvert et se vide pour créer la suivante", (
      WidgetTester tester,
    ) async {
      _tablet(tester);
      final List<Map<String, Object?>> calls = <Map<String, Object?>>[];
      await tester.pumpWidget(
        _host(
          const CreerEquipeLieeScreen(),
          teamsAllowed: 3,
          onCreate: (Map<String, Object?> a) async => calls.add(a),
        ),
      );
      await tester.pumpAndSettle();

      await _fill(tester);

      expect(calls, hasLength(1));
      expect(find.byType(CreerEquipeLieeScreen), findsOneWidget);
      expect(tester.widget<EditableText>(find.descendant(of: find.byKey(const Key('team-name')), matching: find.byType(EditableText))).controller.text, isEmpty);
      // La bannière « équipe créée » garde un minuteur : on le laisse s'écouler.
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('un identifiant déjà pris affiche le message du serveur', (WidgetTester tester) async {
      _tablet(tester);
      await tester.pumpWidget(
        _host(
          const CreerEquipeLieeScreen(),
          onCreate: (_) async => throw const LinkedTeamException(LinkedTeamError.identifierTaken),
        ),
      );
      await tester.pumpAndSettle();

      await _fill(tester);

      expect(find.text('Cet identifiant est déjà utilisé.'), findsOneWidget);
      expect(find.byType(CreerEquipeLieeScreen), findsOneWidget);
    });
  });

  group('MesEquipesScreen', () {
    testWidgets('liste les équipes liées avec leur identifiant', (WidgetTester tester) async {
      _tablet(tester);
      await tester.pumpWidget(
        _host(
          const MesEquipesScreen(),
          linked: const <LinkedTeam>[
            LinkedTeam(uid: 't2', teamName: 'U15 Lyon', identifier: 'u15-lyon', teamIndex: 2),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('U15 Lyon'), findsOneWidget);
      expect(find.text('u15-lyon'), findsOneWidget);
    });


    testWidgets("affiche l'Équipe 1 et les infos de chaque équipe en cartes", (WidgetTester tester) async {
      _tablet(tester);
      await tester.pumpWidget(
        _host(
          const MesEquipesScreen(),
          profile: const CoachProfile(
            teamName: 'PSG',
            category: TeamCategory.u13,
            division: TeamDivision.r3,
            teamFormat: PlayerCount.five,
          ),
          players: const <Player>[
            Player(firstName: 'A', lastName: 'B', strongFoot: StrongFoot.droit, position: PlayerPosition.gardien),
            Player(firstName: 'C', lastName: 'D', strongFoot: StrongFoot.gauche, position: PlayerPosition.milieu),
          ],
          linked: const <LinkedTeam>[
            LinkedTeam(
              uid: 't2',
              teamName: 'U15 Lyon',
              identifier: 'u15-lyon',
              teamIndex: 2,
              category: TeamCategory.u15,
              division: TeamDivision.r2,
              teamFormat: PlayerCount.eleven,
              playerCount: 11,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Équipe 1 : le compte connecté.
      expect(find.text('PSG'), findsOneWidget);
      expect(find.text('Équipe 1'), findsOneWidget);
      expect(find.text('U13'), findsOneWidget);
      expect(find.text('Régional 3'), findsOneWidget);
      expect(find.text('5v5'), findsOneWidget);
      expect(find.text('2 joueurs'), findsOneWidget);
      expect(find.text("Voir l'équipe"), findsOneWidget);
      // Équipe liée.
      expect(find.text('Équipe 2'), findsOneWidget);
      expect(find.text('U15'), findsOneWidget);
      expect(find.text('Régional 2'), findsOneWidget);
      expect(find.text('11v11'), findsOneWidget);
      expect(find.text('11 joueurs'), findsOneWidget);
    });

    testWidgets('une équipe sans catégorie ni effectif connu n''affiche aucune pastille', (WidgetTester tester) async {
      _tablet(tester);
      await tester.pumpWidget(
        _host(
          const MesEquipesScreen(),
          profile: const CoachProfile(),
          linked: const <LinkedTeam>[
            LinkedTeam(uid: 't2', teamName: 'U15 Lyon', identifier: 'u15-lyon', teamIndex: 2),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('U15 Lyon'), findsOneWidget);
      // Seule l'Équipe 1 (effectif chargé, vide) affiche un compte ; l'équipe liée n'a pas de compteur.
      expect(find.textContaining('joueur'), findsOneWidget);
      expect(find.text('0 joueurs'), findsOneWidget);
      expect(
        find.byWidgetPredicate((Widget w) => w is Text && RegExp(r'^\d+v\d+$').hasMatch(w.data ?? '')),
        findsNothing,
      );
    });

    testWidgets('un seul joueur : singulier', (WidgetTester tester) async {
      _tablet(tester);
      await tester.pumpWidget(
        _host(
          const MesEquipesScreen(),
          linked: const <LinkedTeam>[
            LinkedTeam(uid: 't2', teamName: 'U15 Lyon', identifier: 'u15-lyon', teamIndex: 2, playerCount: 1),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 joueur'), findsOneWidget);
    });

    testWidgets('sans équipe : message vide', (WidgetTester tester) async {
      _tablet(tester);
      await tester.pumpWidget(_host(const MesEquipesScreen()));
      await tester.pumpAndSettle();
      expect(find.text("Vous n'avez pas encore créé d'équipe supplémentaire."), findsOneWidget);
    });

    testWidgets("le bouton Ajouter n'apparaît que s'il reste des places", (WidgetTester tester) async {
      _tablet(tester);
      await tester.pumpWidget(_host(const MesEquipesScreen(), teamsAllowed: 2));
      await tester.pumpAndSettle();
      expect(find.text('Ajouter une équipe'), findsOneWidget);

      // On démonte d'abord l'arbre : les surcharges d'un ProviderScope déjà monté ne sont pas rejouées.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_host(const MesEquipesScreen(), teamsAllowed: 1));
      await tester.pumpAndSettle();
      expect(find.text('Ajouter une équipe'), findsNothing);
    });

    testWidgets('réinitialise le mot de passe via la boîte de dialogue', (WidgetTester tester) async {
      _tablet(tester);
      final List<List<String>> resets = <List<String>>[];
      await tester.pumpWidget(
        _host(
          MesEquipesScreen(
            onResetPassword: ({required String uid, required String password}) async {
              resets.add(<String>[uid, password]);
            },
          ),
          linked: const <LinkedTeam>[
            LinkedTeam(uid: 't2', teamName: 'U15 Lyon', identifier: 'u15-lyon', teamIndex: 2),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nouveau mot de passe'));
      await tester.pumpAndSettle();
      expect(find.text('Nouveau mot de passe pour U15 Lyon'), findsOneWidget);

      // Mot de passe hors politique : aucun appel.
      await tester.enterText(find.byKey(const Key('reset-password-field')), 'faible');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(resets, isEmpty);

      await tester.enterText(find.byKey(const Key('reset-password-field')), 'Wina!2345');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      // Laisse expirer la bannière de confirmation (minuteur de 3 s).
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(resets, <List<String>>[
        <String>['t2', 'Wina!2345'],
      ]);
    });
  });
}
