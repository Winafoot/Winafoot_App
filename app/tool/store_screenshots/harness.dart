import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';

/// Outils communs aux captures d'écran des fiches de stores : équipe fictive, hôte de l'app (traductions,
/// police, échelle) et enregistrement d'un PNG à la taille exacte de l'appareil visé.
///
/// Lancer : `flutter test tool/store_screenshots/capture_test.dart` — les images sortent dans
/// `build/store_screenshots/raw`.

/// Un appareil visé : taille logique en paysage et densité (la taille en pixels = logique x densité).
class Device {
  const Device(this.name, this.width, this.height, this.pixelRatio);

  final String name;
  final double width;
  final double height;
  final double pixelRatio;

  Size get logical => Size(width, height);
}

const Device kTablet = Device('tablet', 1194, 834, 2);
const Device kPhone = Device('phone', 844, 390, 3);

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// Charge la police Poppins de l'app : sans elle, `flutter test` écrit tout avec une police de carrés.
Future<void> loadFonts() async {
  final FontLoader loader = FontLoader('Poppins');
  for (final String f in <String>[
    'Light',
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
  ]) {
    final Uint8List bytes = File('assets/fonts/Poppins-$f.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();

  // Icônes : sans ces polices, `flutter test` les dessine en carrés.
  Future<void> icons(String family, String path) async {
    final File f = File(path);
    if (!f.existsSync()) return;
    final FontLoader l = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(f.readAsBytesSync())));
    await l.load();
  }

  final String flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  await icons(
    'MaterialIcons',
    '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  final String local =
      Platform.environment['LOCALAPPDATA'] ?? Platform.environment['HOME'] ?? '';
  await icons(
    'packages/iconsax_flutter/FlutterIconsax',
    '$local/Pub/Cache/hosted/pub.dev/iconsax_flutter-1.0.1/fonts/FlutterIconsax.ttf',
  );
}

// ── Équipe fictive ──────────────────────────────────────────────────────────

const List<(String, String, PlayerPosition, StrongFoot)> _roster =
    <(String, String, PlayerPosition, StrongFoot)>[
      ('Hugo', 'Martin', PlayerPosition.gardien, StrongFoot.droit),
      ('Lucas', 'Bernard', PlayerPosition.defenseur, StrongFoot.droit),
      ('Nathan', 'Dubois', PlayerPosition.defenseur, StrongFoot.gauche),
      ('Tom', 'Moreau', PlayerPosition.defenseur, StrongFoot.droit),
      ('Enzo', 'Laurent', PlayerPosition.defenseur, StrongFoot.droit),
      ('Léo', 'Simon', PlayerPosition.milieu, StrongFoot.droit),
      ('Noah', 'Michel', PlayerPosition.milieu, StrongFoot.gauche),
      ('Adam', 'Lefebvre', PlayerPosition.milieu, StrongFoot.droit),
      ('Louis', 'Garcia', PlayerPosition.attaquant, StrongFoot.droit),
      ('Jules', 'Roux', PlayerPosition.attaquant, StrongFoot.gauche),
      ('Ethan', 'Fournier', PlayerPosition.attaquant, StrongFoot.droit),
      ('Rayan', 'Girard', PlayerPosition.gardien, StrongFoot.droit),
      ('Maël', 'Bonnet', PlayerPosition.milieu, StrongFoot.droit),
      ('Sacha', 'Faure', PlayerPosition.defenseur, StrongFoot.gauche),
    ];

/// Joueurs de démonstration : 11 titulaires (indices 0 à 10) puis 3 remplaçants.
final List<Player> demoPlayers = <Player>[
  for (int i = 0; i < _roster.length; i++)
    Player(
      id: 'p$i',
      firstName: _roster[i].$1,
      lastName: _roster[i].$2,
      position: _roster[i].$3,
      strongFoot: _roster[i].$4,
    ),
];

const CoachProfile demoCoach = CoachProfile(
  coachName: 'Guillaume',
  teamName: 'FC Les Aigles',
  category: TeamCategory.u13,
  division: TeamDivision.d1,
);

/// Composition 4-3-3 avec les 11 premiers joueurs, numéros de maillot et 3 remplaçants.
MatchComposition demoComposition() {
  final Formation f = standardFormations(11).firstWhere(
    (Formation x) => x.label == '4-3-3',
    orElse: () => standardFormations(11).first,
  );
  final List<String?> assignments = <String?>[
    for (int i = 0; i < f.slots.length; i++) i < 11 ? 'p$i' : null,
  ];
  // Un gardien en premier : on range les titulaires par poste pour que chacun tombe sur son emplacement.
  final List<String> byRole = <String>[];
  for (final FormationSlot s in f.slots) {
    final Player? p = demoPlayers
        .take(11)
        .where((Player x) => x.position == s.role && !byRole.contains(x.id))
        .cast<Player?>()
        .firstWhere((_) => true, orElse: () => null);
    byRole.add(p?.id ?? 'p0');
  }
  for (int i = 0; i < assignments.length; i++) {
    assignments[i] = i < byRole.length ? byRole[i] : null;
  }
  return MatchComposition(
    formationLabel: f.label,
    playerCount: 11,
    slots: f.slots,
    assignments: assignments,
    numbers: <String, int>{
      for (int i = 0; i < _roster.length; i++) 'p$i': i + 1,
    },
    substituteIds: const <String>['p11', 'p12', 'p13'],
    captainId: 'p5',
  );
}

// ── Hôte et capture ─────────────────────────────────────────────────────────

Widget host({
  required Widget home,
  required List<Override> overrides,
  required GlobalKey boundary,
}) {
  return RepaintBoundary(
    key: boundary,
    child: ProviderScope(
      overrides: overrides,
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
                debugShowCheckedModeBanner: false,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeData(fontFamily: 'Poppins'),
                builder:
                    (BuildContext ctx, Widget? child) =>
                        ResponsiveWrapper.builder(
                          child,
                          minWidth: 450,
                          breakpoints: const <ResponsiveBreakpoint>[
                            ResponsiveBreakpoint.tag(800, name: PHONE),
                            ResponsiveBreakpoint.tag(1100, name: TABLET),
                            ResponsiveBreakpoint.tag(
                              double.infinity,
                              name: DESKTOP,
                            ),
                          ],
                        ),
                home: home,
              ),
        ),
      ),
    ),
  );
}

/// Affiche [home] sur [device], laisse les images se décoder, puis écrit le PNG `build/store_screenshots/raw2/<nom>`.
Future<void> shoot(
  WidgetTester tester, {
  required Device device,
  required String name,
  required Widget home,
  required List<Override> overrides,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  // La synchro adjoint (Firebase, absent en test) lève une erreur asynchrone sans importance pour une capture :
  // on l'isole dans une zone dédiée plutôt que de la laisser faire échouer le test.
  final Completer<void> done = Completer<void>();
  runZonedGuarded(
    () async {
      try {
        await _shoot(
          tester,
          device: device,
          name: name,
          home: home,
          overrides: overrides,
          afterPump: afterPump,
        );
        done.complete();
      } catch (e, st) {
        done.completeError(e, st);
      }
    },
    (Object e, StackTrace st) {
      if (e is! FirebaseException) debugPrint('capture: $e');
    },
  );
  await done.future;
}

Future<void> _shoot(
  WidgetTester tester, {
  required Device device,
  required String name,
  required Widget home,
  required List<Override> overrides,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  tester.view.physicalSize = Size(
    device.width * device.pixelRatio,
    device.height * device.pixelRatio,
  );
  tester.view.devicePixelRatio = device.pixelRatio;
  addTearDown(tester.view.reset);

  final GlobalKey boundary = GlobalKey();
  await tester.pumpWidget(
    host(home: home, overrides: overrides, boundary: boundary),
  );
  // Décodage réel des images (terrain, maillots) : hors de l'horloge simulée.
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  // La synchro adjoint tente d'ouvrir Firebase, absent en test : sans importance pour une capture.
  while (tester.takeException() != null) {}
  if (afterPump != null) await afterPump(tester);

  final RenderRepaintBoundary render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final Uint8List? png = await tester.runAsync(() async {
    final ui.Image image = await render.toImage(pixelRatio: device.pixelRatio);
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final File out = File('build/store_screenshots/raw2/${device.name}_$name.png')
    ..createSync(recursive: true);
  out.writeAsBytesSync(png!);
}
