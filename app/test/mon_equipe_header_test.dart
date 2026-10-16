import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/mon_equipe_screen.dart';

/// Vrais libellés fr-FR (lus sur disque, en synchrone pour rester sous
/// l'horloge simulée du test) : sans eux `.tr()` rend la clé brute, plus longue
/// que le texte réel, et fausse la mesure de l'entête.
class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// Entête de « Mon équipe » : les libellés de catégorie / division s'allongent
/// (« Départemental 5 »), les puces ne sont pas flexibles — seul le nom
/// d'équipe l'est. Le pire cas (libellés les plus longs + nom d'équipe très
/// long + puce coach) ne doit pas déborder sur la tablette de référence.
Widget _host(CoachProfile coach) => ProviderScope(
  overrides: <Override>[
    // Sans session : les flux Firestore dérivés de l'uid rendent des listes
    // vides, aucun accès à Firebase.
    authUidProvider.overrideWith((ref) => Stream<String?>.value(null)),
    coachProfileProvider.overrideWith(
      (ref) => Stream<CoachProfile>.value(coach),
    ),
    playersStreamProvider.overrideWith(
      (ref) => Stream<List<Player>>.value(const <Player>[]),
    ),
    maxSquadSizeProvider.overrideWith((ref) async => 30),
  ],
  child: EasyLocalization(
    supportedLocales: const <Locale>[Locale('fr', 'FR')],
    startLocale: const Locale('fr', 'FR'),
    path: 'assets/translations',
    assetLoader: const _DiskAssetLoader(),
    saveLocale: false,
    child: ScreenUtilInit(
      designSize: const Size(1194, 834),
      builder:
          (BuildContext context, _) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const MonEquipeScreen(),
          ),
    ),
  ),
);

void main() {
  testWidgets(
    "l'entête ne déborde pas avec la catégorie et la division les plus "
    'longues et un nom d\'équipe très long',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1194, 834);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Libellés les plus longs, relevés dans les enums plutôt que codés en
      // dur : ajouter une valeur plus longue durcit le test tout seul.
      final TeamCategory longestCategory = TeamCategory.values.reduce(
        (TeamCategory a, TeamCategory b) =>
            b.label.length > a.label.length ? b : a,
      );
      final TeamDivision longestDivision = TeamDivision.values.reduce(
        (TeamDivision a, TeamDivision b) =>
            b.label.length > a.label.length ? b : a,
      );

      await tester.pumpWidget(
        _host(
          CoachProfile(
            coachName: 'Jean-Baptiste Dupont-Lefèvre',
            teamName:
                'Association Sportive et Culturelle de Saint-Étienne-du-Rouvray '
                'Football Club Vétérans',
            category: longestCategory,
            division: longestDivision,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Les puces sont bien rendues (sinon le test ne prouverait rien) ...
      expect(find.text(longestCategory.label), findsOneWidget);
      expect(find.text(longestDivision.label), findsOneWidget);
      // ... et rien ne déborde (un RenderFlex overflow est remonté ici).
      expect(tester.takeException(), isNull);
    },
  );
}
