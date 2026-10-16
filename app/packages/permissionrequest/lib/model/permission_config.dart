import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:permissionrequest/model/permission_model.dart';

/// {@category Config}
/// {@category Permission}
///
/// Permet de configurer le package permission.
/// Afin de pouvoir utiliser cette configuration au
/// sein du package, il faut utiliser [PermissionConfig.key].
class PermissionConfig extends PackageConfig {
  /// Clé canonique pour l'enregistrement dans AppModel.dependencies.packages
  static const String key = "permission-kosmos";
  final bool showSkipButton;

  final bool showBackButton;

  final String? appLogoAsset;

  final List<PermissionDataModel> permissions;

  final void Function(PageController?, BuildContext)? onSkipButtonPressed;

  final void Function(PageController?, BuildContext)? onBackButtonPressed;
  final Widget Function(
    BuildContext,
  )? backgroundChild;

  PermissionConfig({
    required this.permissions,
    this.showSkipButton = true,
    this.showBackButton = true,
    this.onSkipButtonPressed,
    this.onBackButtonPressed,
    this.backgroundChild,
    this.appLogoAsset,
  }) : super(key);
}

/// Récupère la configuration [PermissionConfig] depuis AppModel.
PermissionConfig getPermissionConfig() {
  final config = getAppModel().dependencies.packages[PermissionConfig.key];
  assert(
    config == null || config is PermissionConfig,
    'Type mismatch for ${PermissionConfig.key}',
  );
  return (config as PermissionConfig?) ?? PermissionConfig(permissions: []);
}
