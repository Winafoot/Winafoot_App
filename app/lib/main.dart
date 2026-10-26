import 'dart:developer' as developer;

import 'package:wina/config/notifications.config.dart';
import 'package:wina/config/permission_config.dart';
import 'package:wina/config/settings.config.dart';
import 'package:wina/config/skeleton_config.dart';
import 'package:skeleton/skeleton.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wina/models/userAppData/user_app_data.dart';
import 'package:permissionrequest/permissons_package.dart';

import 'config/maintenance_gate.dart';
import 'config/orientation_controller.dart';
import 'services/email_sync.dart';
import 'config/theme.dart';
import 'routes/app_router.gr.dart';

/// Jeton App Check de debug fixe, passé par `--dart-define=APPCHECK_DEBUG_TOKEN=<uuid>` (jamais committé) :
/// il évite d'enregistrer un nouveau jeton à chaque réinstallation de l'émulateur. Vide : jeton généré.
const String _kAppCheckDebugToken = String.fromEnvironment('APPCHECK_DEBUG_TOKEN');

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarBrightness: Brightness.light, // set Status bar icon color in iOS
    ),
  );

  final appRouter = AppRouter(
    isNotConnectedGuard: IsNotConnectedGuard(),
    isConnectedGuard: IsConnectedGuard(),
    permissionSeenGuard: PermissionSeenGuard(),
  );
  _startAnalyticsScreenTracking(appRouter);
  // Paysage par défaut ; portrait sur téléphone pour le parcours d'entrée.
  OrientationController.attach(appRouter);

  return await Application.launch(
    initModel(),
    appRouter,
    initTheme: initTheme,
    onInit: () async {
      await LocalAuthController.purgeStoredCredentials();
      await AppMetadataController.stockMetadataForApp();
      await MaintenanceGate.start(appRouter);
      EmailSync.start();
    },
  );
}

/// Suivi d'écran Firebase Analytics.
///
/// Le socle Kosmos câble lui-même les `navigatorObservers` de
/// `MaterialApp.router` (core_kosmos `src/widget/main_page.dart`) et
/// `Application.launch` n'expose aucun point d'injection : impossible de
/// brancher un `FirebaseAnalyticsObserver`. On écoute donc directement le
/// routeur, qui notifie à chaque changement de route, et on remonte le nom de
/// la route la plus profonde (`topRoute`) via [AnalyticsController].
void _startAnalyticsScreenTracking(AppRouter router) {
  String? lastScreen;
  router.addListener(() {
    final String screen = router.topRoute.name;
    if (screen == lastScreen) return;
    lastScreen = screen;
    AnalyticsController.openScreen(screen);
  });
}

AppModel initModel() {
  return AppModel(
    appTitle: "Wina",
    // App 100% tablette : le design de référence fait 1194x834, ce qui aligne
    // sp()/sh()/formatWidth() sur les valeurs px du design Figma.
    responsive: const ResponsiveConfig(
      size: Size(1194, 834),
      // Téléphone en portrait (parcours d'entrée) : design 390x844. minWidth 450 par défaut
      // forcerait un téléphone de 390 dp à s'afficher plus large que son écran.
      portraitSize: Size(390, 844),
      minWidth: 320,
    ),
    userConfig: UserConfig(
      fromJson: (Map<String, dynamic>? json, userType) {
        return UserAppData.fromJson(json ?? {});
      },
    ),
    excuteAfterFirebaseInitialized: () async {
      // App Check : Play Integrity / App Attest en release, fournisseur de debug sinon (émulateur,
      // `flutter run`, profile), dont le jeton s'enregistre dans la console Firebase (voir README).
      // Firestore, Storage et les callables exigent un jeton valide. Un échec d'activation est
      // journalisé et n'empêche pas le démarrage : les requêtes partent alors sans jeton.
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid:
              kReleaseMode
                  ? const AndroidPlayIntegrityProvider()
                  : AndroidDebugProvider(
                    debugToken: _kAppCheckDebugToken.isEmpty ? null : _kAppCheckDebugToken,
                  ),
          providerApple:
              kReleaseMode
                  ? const AppleAppAttestProvider()
                  : AppleDebugProvider(
                    debugToken: _kAppCheckDebugToken.isEmpty ? null : _kAppCheckDebugToken,
                  ),
        );
      } catch (e, st) {
        developer.log(
          'Activation impossible',
          name: 'AppCheck',
          error: e,
          stackTrace: st,
        );
      }
    },
    firebase: const FirebaseConfig(
      enabled: true,
      clearUserSessionOnDebugMode: false,
    ),
    dependencies: DependenciesConfig(
      packages: {
        EventConfiguration.key: initNotificationPush(),
        PermissionConfig.key: initPermissionConfig(),
        KosmosSettingsConfig.key: initKosmosSettingsConfig(),
        SkeletonAppConfig.key: initSkeletonAppConfig(),
      },
    ),
  );
}
