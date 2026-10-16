import 'package:core_kosmos/core_kosmos.dart';
import 'package:core_kosmos/src/widget/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_strategy/url_strategy.dart';

/// {@category Core}
/// {@category Launcher}
///
/// Permet de lancer l'application en utilisant les configurations, thèmes ainsi que le router fourni en arguments.
///
abstract class Application {
  static Future<void> _launchFirebaseService({
    required FirebaseConfig config,
    Future<void> Function()? excuteAfterFirebaseInitialized,
  }) async {
    if (!config.enabled) return;

    if (kIsWeb) {
      await Firebase.initializeApp(options: config.options);
      await FirebaseAuth.instance.setPersistence(Persistence.INDEXED_DB);
      await excuteAfterFirebaseInitialized?.call();
    } else if (config.options != null) {
      await Firebase.initializeApp(options: config.options);
      await excuteAfterFirebaseInitialized?.call();
    } else {
      await Firebase.initializeApp();
      await excuteAfterFirebaseInitialized?.call();
    }

    if (!kReleaseMode &&
        config.clearUserSessionOnDebugMode &&
        FirebaseAuth.instance.currentUser != null) {
      printDebug("Debug Mode: clear user session");
      await FirebaseAuth.instance.signOut();
    }

    User? firebaseUser = FirebaseAuth.instance.currentUser;
    firebaseUser ??= await FirebaseAuth.instance.authStateChanges().first;
  }

  static Future<void> _launchPaymentConfig() async {
    final config = await AppMetadataController.getMetadata();
    if (config != null && config.stripeConfig != null) {
      Stripe.merchantIdentifier = config.stripeConfig!.merchantIdentifier;
      if (FirebaseAuth.instance.currentUser != null &&
          config.stripeConfig!.isProdMode &&
          config.stripeConfig!.publishableProdKey != null &&
          config.stripeConfig!.testEmail
              .contains(FirebaseAuth.instance.currentUser!.email!)) {
        Stripe.publishableKey = config.stripeConfig!.publishableKey;
      } else if (config.stripeConfig!.isProdMode &&
          config.stripeConfig!.publishableProdKey != null) {
        Stripe.publishableKey = config.stripeConfig!.publishableProdKey!;
      } else {
        Stripe.publishableKey = config.stripeConfig!.publishableKey;
      }
      Stripe.urlScheme = config.stripeConfig!.urlScheme;
      await Stripe.instance.applySettings();
    }
  }

  static FutureOr<void> launch(
    AppModel config,
    RootStackRouter router, {
    AppTheme Function(BuildContext, AppModel)? initTheme,
    FutureOr<void> Function()? onInit,
    FutureOr<void> Function(BuildContext, WidgetRef)? onInitWithContext,
  }) async {
    /// Be sure all widget and flutter system are initialized
    WidgetsFlutterBinding.ensureInitialized();

    /// Ensure Translations is correctly initialized
    await EasyLocalization.ensureInitialized();

    /// register application config
    GetIt.instance.registerSingleton<AppModel<Object?>>(config);

    if (kIsWeb) setPathUrlStrategy();

    /// Launch Firebase service
    await _launchFirebaseService(
      config: config.firebase,
      excuteAfterFirebaseInitialized: config.excuteAfterFirebaseInitialized,
    );

    /// Get and store metadata
    final metadataLoaded = await AppMetadataController.stockMetadataForApp();
    if (!metadataLoaded) {
      debugPrint('Failed to load metadata configuration');
    } else {
      debugPrint('Metadata configuration loaded successfully');
    }

    /// Launch dependencies of passed callback
    if (onInit != null) await onInit();

    if (!kIsWeb) {
      await _launchPaymentConfig();
    }

    AnalyticsController.openApp();

    return runApp(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: config.localization.supportedLocales,
          fallbackLocale: config.localization.defaultLocale,
          path: config.localization.translationPath,
          child: ScreenUtilInit(
            designSize: config.responsive.size,
            builder: (context, child) {
              if (!GetIt.instance.isRegistered<AppTheme>()) {
                GetIt.instance.registerSingleton(initTheme != null
                    ? initTheme(context, config)
                    : AppTheme());
              }
              return ResponsiveWrapper.builder(
                BouncingScrollWrapper(child: child!),
                minWidth: config.responsive.minWidth,
                maxWidth: config.responsive.maxWidth,
                breakpoints: config.responsive.breakpoints,
              );
            },
            child: MainPage(
                appRouter: router,
                config: config,
                onInitWithContext: onInitWithContext),
          ),
        ),
      ),
    );
  }
}
