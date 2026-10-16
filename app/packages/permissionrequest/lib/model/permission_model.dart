import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permissionrequest/permissons_package.dart';

class PermissionDataModel {
  /// Image, au format svg, de la permission
  final String? svgPath;

  final String? imagePath;

  /// Permet d'afficher un [Widget] à la place du svg,
  /// uniquement si [svgPath] est null.
  final Widget? child;

  /// Titre de la permission
  final StringCallback? title;
  final Widget Function(BuildContext)? titleWidget;

  /// Description de la permission
  final StringCallback? description;
  final Widget Function(BuildContext)? descriptionWidget;

  /// Bouton d'action, s'affiche uniquement si [buttonText]
  /// est null.
  final Widget Function(BuildContext, WidgetRef, PageController?, bool)?
      actionButton;

  /// Texte du bouton d'action
  final StringCallback? buttonText;

  /// Évenement lors du clic sur le bouton d'action
  final FutureOr<void> Function(BuildContext, WidgetRef, PageController?, bool)?
      onActionButtonPressed;

  const PermissionDataModel({
    this.svgPath,
    this.imagePath,
    this.child,
    this.title,
    this.description,
    this.actionButton,
    this.buttonText,
    this.onActionButtonPressed,
    this.descriptionWidget,
    this.titleWidget,
  });
}

final PermissionDataModel kDefaultNotifPushPermission = PermissionDataModel(
  svgPath: "assets/svg/permission_notif_push.svg",
  title: () => "package.permission.notif-push.title".tr(),
  description: () => "package.permission.notif-push.desc".tr(),
  buttonText: () => "package.permission.notif-push.button".tr(),
  onActionButtonPressed: (context, ref, controller, isLast) async {
    if (FirebaseAuth.instance.currentUser != null) {
      final isAuthorized =
          await NotifPermissionController.setPushNotificationPermission(
              context, ref, true, FirebaseAuth.instance.currentUser!.uid,
              false);
      await PermissionController.setPushNotifications(isAuthorized);
    }
    await PermissionController.setPermissionAsComplete();
    if (context.mounted) AutoRouter.of(context).replaceNamed("/");
  },
);

final PermissionDataModel kDefaultLocationPermission = PermissionDataModel(
  svgPath: "assets/svg/permission_location.svg",
  title: () => "package.permission.location.title".tr(),
  description: () => "package.permission.location.desc".tr(),
  buttonText: () => "package.permission.location.button".tr(),
  onActionButtonPressed: (context, ref, _controller, isLast) async {
    final r = await GeolocController.requestGeoloc(context);
    if (!r) return;
    if (!isLast) {
      _controller!.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
      return;
    }
    await PermissionController.setPermissionAsComplete();
    AutoRouter.of(context).replaceNamed("/");
  },
);

final PermissionDataModel kDefaultBackgroundLocationPermission =
    PermissionDataModel(
  svgPath: "assets/svg/permission_location_background.svg",
  title: () => "package.permission.background-location.title".tr(),
  description: () => "package.permission.background-location.desc".tr(),
  buttonText: () => "package.permission.background-location.button".tr(),
  onActionButtonPressed: (context, ref, _controller, isLast) async {
    final r = await GeolocController.requestGeoloc(context);
    if (!r) return;

    if (!isLast) {
      _controller!.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
      return;
    }
    await PermissionController.setPermissionAsComplete();
    AutoRouter.of(context).replaceNamed("/");
  },
);
