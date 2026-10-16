import 'dart:math' as math;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permissionrequest/permissons_package.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/check_profil_form.dart';

/// Drapeau local posé par [PermissionController.setPermissionAsComplete].
/// La clé est dupliquée ici parce que le package ne l'expose pas.
const String kPermissionLaunchedKey = "permission_already_launched";

PermissionConfig initPermissionConfig() {
  return PermissionConfig(
    permissions: <PermissionDataModel>[
      // Seule la notification push est demandée : l'app n'a aucune
      // fonctionnalité de géolocalisation.
      _kNotifPushPermission,
    ],
    // Une seule permission : le `ButtonBack` du package resterait à
    // `Opacity(0)` — invisible mais toujours tapable, juste sous le wordmark.
    showBackButton: false,
    // Calque terrain + wordmark de la maquette. Le logo passe par ici et non
    // par `appLogoAsset` : celui-ci va chercher un `Image.asset` alors que le
    // wordmark Wina n'existe qu'en SVG.
    backgroundChild:
        (BuildContext context) => Stack(
          children: <Widget>[
            const AppBackground(),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: formatHeight(40)),
                  child: SvgPicture.asset(
                    "assets/svg/logo_inline.svg",
                    width: sp(88),
                  ),
                ),
              ),
            ),
          ],
        ),
    // « Passer » : la notification n'est pas obligatoire, la refuser doit
    // laisser l'app pleinement utilisable. On ne laisse donc pas le package
    // appeler directement `setPermissionAsComplete()` (voir
    // [_completeAndGoHome]).
    onSkipButtonPressed: (_, BuildContext context) {
      _completeAndGoHome(AutoRouter.of(context));
    },
  );
}

/// Reprise de `kDefaultNotifPushPermission` (mêmes libellés) habillée d'après
/// la maquette, avec une sortie d'écran garantie : voir [_completeAndGoHome].
final PermissionDataModel _kNotifPushPermission = PermissionDataModel(
  // `child` prime sur `svgPath` (permission_widget.dart:236). La maquette
  // demande le losange sombre à cloche blanche, pas l'illustration générique
  // du package — composé ici, la cloche existant déjà en SVG.
  // `Builder` obligatoire : ce modèle est un `final` de premier niveau,
  // construit depuis `initModel()` AVANT que `ScreenUtilInit` ne soit monté.
  // Évalués tout de suite, `sp()`/`r()` lèveraient un LateInitializationError
  // au démarrage sur tout appareil au format téléphone.
  child: Builder(
    builder:
        (BuildContext context) => Align(
          alignment: Alignment.bottomCenter,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: sp(69),
              height: sp(69),
              decoration: BoxDecoration(
                color: AppColor.primaryLabels,
                borderRadius: BorderRadius.circular(r(16)),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: SvgPicture.asset(
                    "assets/svg/ic_notif.svg",
                    width: sp(21),
                  ),
                ),
              ),
            ),
          ),
        ),
  ),
  title: () => "package.permission.notif-push.title".tr(),
  // `descriptionWidget` n'est lu QUE si `description` est null
  // (permission_widget.dart:289) : la chaîne doit disparaître d'ici. Le
  // package ne borne pas la largeur du texte, d'où le paragraphe sur une
  // seule ligne au lieu des trois de la maquette.
  descriptionWidget:
      (BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: formatWidth(360)),
        child: Text(
          "package.permission.notif-push.desc".tr(),
          style: AppThemeStyle.regularStyle(13, AppColor.secondaryLabels),
          textAlign: TextAlign.center,
        ),
      ),
  // `actionButton` prime au contraire sur `buttonText`
  // (permission_widget.dart:201). C'est le seul moyen de rétrécir le CTA — le
  // package passe `width: double.infinity` en dur, ce qui masque le thème — et
  // d'y poser la pastille fléchée : `CpButton` apporte les deux.
  actionButton:
      (BuildContext context, WidgetRef ref, PageController? _, bool _) =>
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formatWidth(260)),
              child: CpButton(
                label: "package.permission.notif-push.button".tr(),
                onTap: () => _requestPushPermission(context, ref),
              ),
            ),
          ),
);

/// Demande la permission de notification puis quitte l'écran, succès ou échec.
Future<void> _requestPushPermission(BuildContext context, WidgetRef ref) async {
  final StackRouter router = AutoRouter.of(context);
  final User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final bool isAuthorized =
          await NotifPermissionController.setPushNotificationPermission(
            context,
            ref,
            true,
            user.uid,
            false,
          );
      await PermissionController.setPushNotifications(isAuthorized);
    } catch (_) {
      // Refus système ou échec réseau : on continue quand même, l'app reste
      // utilisable sans notification.
    }
  }
  await _completeAndGoHome(router);
}

/// Marque les permissions comme vues puis retourne à l'accueil, succès ou échec.
///
/// `PermissionController.setPermissionAsComplete()` fait un `update()` sur
/// `users/{uid}/metadata/metadata` AVANT de poser le drapeau local : si ce
/// document n'existe pas, `update()` lève et le drapeau n'est jamais écrit —
/// l'utilisateur resterait enfermé sur l'écran de permission. On rattrape donc
/// l'erreur et on pose le drapeau local nous-mêmes avant de naviguer.
///
/// Le [StackRouter] est capturé avant les `await` plutôt que le [BuildContext] :
/// la navigation doit avoir lieu même si l'écran a été démonté entre-temps.
Future<void> _completeAndGoHome(StackRouter router) async {
  try {
    await PermissionController.setPermissionAsComplete();
  } catch (_) {
    await LocalConfigController.setData(
      kPermissionLaunchedKey,
      boolValue: true,
    );
  }
  await router.replaceNamed("/");
}

/// Redirige vers l'écran de permission tant qu'il n'a pas été vu sur cet
/// appareil.
///
/// Écrit ici plutôt que d'utiliser le `PermissionGuard` du package : celui-ci
/// enchaîne un `get()` Firestore sans `catchError` ni timeout, et si la lecture
/// échoue (démarrage hors-ligne avec cache vide, App Check refusé) le resolver
/// n'est jamais complété — la navigation reste pendante pour toute la session,
/// sans reprise possible. Le drapeau local suffit : une permission de
/// notification est de toute façon une donnée par appareil.
class PermissionSeenGuard extends AutoRouteGuard {
  /// Laisse passer la navigation si l'écran de permission a déjà été vu,
  /// sinon l'affiche à la place.
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    bool seen;
    try {
      seen =
          await LocalConfigController.getData<bool>(kPermissionLaunchedKey) ??
          false;
    } catch (_) {
      seen = false;
    }
    if (seen) {
      resolver.next();
    } else {
      router.replaceNamed("permission");
    }
  }
}
