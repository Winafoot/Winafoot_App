import 'dart:developer' as developer;

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../routes/app_router.gr.dart';
import 'app_update.dart';

/// État de la passerelle : application ouverte, en maintenance, ou bloquée
/// tant qu'elle n'est pas mise à jour.
enum GateState { open, maintenance, updateRequired }

/// Écoute en temps réel `app_config/metadata` et bascule toute l'application :
///
/// - sur [MaintenanceRoute] quand `maintenance` passe à `true` ;
/// - sinon sur [UpdateRequiredRoute] quand le build installé est inférieur à
///   `minBuild` de sa plateforme (voir [AppUpdate]) ;
/// - de nouveau sur la route initiale quand plus rien ne bloque.
///
/// La bascule vaut aussi pour une app déjà ouverte. Le flag `maintenance` est
/// posé par la cloud function `onBudgetAlert` (coupe-circuit budget) avant le
/// détachement de la facturation : Firestore reste lisible en plan Spark, donc
/// l'écran s'affiche même app « coupée ».
class MaintenanceGate {
  MaintenanceGate._();

  static GateState _state = GateState.open;
  static String? _storeUrl;

  /// `true` tant qu'un écran bloquant (maintenance, mise à jour) est affiché :
  /// aucune autre navigation ne doit alors le recouvrir.
  static bool get blocksNavigation => _state != GateState.open;

  /// État exigé par `metadata` pour un build [currentBuild] sur la plateforme
  /// [platformKey] (`android` ou `ios`). La maintenance prime sur la mise à
  /// jour.
  static GateState resolve(
    Map<String, dynamic>? metadata, {
    required int? currentBuild,
    required String? platformKey,
  }) {
    if ((metadata?["maintenance"] ?? false) == true) {
      return GateState.maintenance;
    }
    final bool updateRequired = AppUpdate.isUpdateRequired(
      currentBuild: currentBuild,
      minBuild: AppUpdate.minBuildFor(metadata, platformKey),
    );
    return updateRequired ? GateState.updateRequired : GateState.open;
  }

  static Future<void> start(StackRouter router) async {
    final int? currentBuild = await AppUpdate.currentBuildNumber();
    final String? platformKey = AppUpdate.platformKey();

    FirebaseFirestore.instance
        .collection("app_config")
        .doc("metadata")
        .snapshots()
        .listen(
          (doc) {
            final Map<String, dynamic>? metadata = doc.data();
            final GateState next = resolve(
              metadata,
              currentBuild: currentBuild,
              platformKey: platformKey,
            );
            final String? storeUrl = AppUpdate.storeUrlFor(
              metadata,
              platformKey,
            );
            if (next == _state &&
                (next != GateState.updateRequired || storeUrl == _storeUrl)) {
              return;
            }
            _state = next;
            _storeUrl = storeUrl;
            _navigate(router, switch (next) {
              GateState.maintenance => [const MaintenanceRoute()],
              GateState.updateRequired => [
                UpdateRequiredRoute(storeUrl: storeUrl),
              ],
              GateState.open => [const LoggedUserAppCoreRoute()],
            });
          },
          onError: (Object e, StackTrace st) {
            developer.log(
              "Lecture de app_config/metadata impossible",
              name: "MaintenanceGate",
              error: e,
              stackTrace: st,
            );
          },
        );
  }

  /// Au premier événement, le routeur peut ne pas encore être monté
  /// (le listener démarre dans `onInit`, avant `runApp`).
  static void _navigate(StackRouter router, List<PageRouteInfo> stack) {
    if (router.navigatorKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => router.replaceAll(stack),
      );
    } else {
      router.replaceAll(stack);
    }
  }
}
