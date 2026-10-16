import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

enum ProfilImagePosition {
  bottomRight,
  bottomLeft,
  bottomCenter,
}

/// {@category Config}
/// {@category KosmosSettings}
///
/// Permet de configurer le package de Settings de Kosmos Digital.
///
/// vous pouvez le configurer via [KosmosSettingsConfig.key].
///
class KosmosSettingsConfig extends PackageConfig {
  /// Clé canonique pour l'enregistrement dans AppModel.dependencies.packages
  static const String key = "kosmos-settings";

  /// Affiche la photo de profil dans les settings
  /// Par défaut, ```true```.
  final bool showProfilImage;

  final String profilActionTitleText;

  final String pathSettingsNode;

  final FutureOr<bool> Function(WidgetRef ref)? canDeleteAccount;

  /// functions that return bool : by default it's PopupAlert.dialogBox
  final FutureOr<bool> Function(BuildContext context)? areYouSureDeleteAccount;

  final String Function(WidgetRef ref)? profileNameBuilder;

  /// Permet de modifier la photo de profil dans les settings
  /// Par défaut, ```true```.
  final bool canModifyProfilImage;
  final bool Function(WidgetRef ref)? canModifyProfilImageCallback;

  /// Permet de choisir l'emplacement du bouton de mofication de la photo de profil
  /// Par défaut, ```bottomRight```.
  final ProfilImagePosition profilImagePosition;

  final Widget Function(BuildContext context, WidgetRef ref)?
      settingsHeaderBuilder;

  /// Affiche le nom complet dans les settings
  /// Par défaut, ```true```.
  final bool showFullName;

  /// Affiche l'email dans les settings
  /// Par défaut, ```true```.
  final bool showEmail;

  /// Affiche les informations de l'utilisateur dans les settings
  /// Par défaut, ```true```.
  final bool showProfilInfo;

  /// Liste des sections de paramètres
  final List<CelluleSection> Function(WidgetRef) settingsSection;

  /// Affiche ou non la ligne "Éditer par Kosmos Digital"
  /// Par défaut, ```true```.
  final bool showKosmosDigitalLine;

  /// Permet de configurer son propre [VoidCallback] pour le bouton
  /// de modification de la photo de profil.
  /// Par défaut : ```null```.
  final VoidCallback? onModifyProfilButtonPressed;

  /// Affiche le logo de l'application dans les settings
  /// Par défaut, ```false```.
  final bool showAppLogo;

  final Size logoSize;

  // Button builder

  // settings button builder
  // change email
  final Widget Function(BuildContext context, WidgetRef ref)?
      buttonChangeEmailBuilder;
  final Widget Function(BuildContext context, WidgetRef ref)?
      buttonVerifyEmailBuilder;
  // change password
  final Widget Function(BuildContext context, WidgetRef ref)?
      buttonChangePasswordBuilder;
  // change phone
  final Widget Function(BuildContext context, WidgetRef ref)?
      buttonChangePhoneBuilder;
  final Widget Function(BuildContext context, WidgetRef ref)?
      buttonVerifyOTPCodeBuilder;

  KosmosSettingsConfig({
    this.showProfilImage = true,
    this.canModifyProfilImageCallback,
    this.canModifyProfilImage = true,
    this.areYouSureDeleteAccount,
    this.pathSettingsNode = "app/profile/settings/",
    this.profilImagePosition = ProfilImagePosition.bottomRight,
    this.profilActionTitleText = "utils.what-do-you-want-to-do",
    this.showFullName = true,
    this.showEmail = true,
    this.showProfilInfo = true,
    this.settingsSection = _defaultSettingsSection,
    this.showKosmosDigitalLine = false,
    this.onModifyProfilButtonPressed,
    this.showAppLogo = false,
    this.logoSize = Size.zero,
    this.canDeleteAccount,
    this.profileNameBuilder,
    this.settingsHeaderBuilder,
    this.buttonChangeEmailBuilder,
    this.buttonVerifyEmailBuilder,
    this.buttonChangePasswordBuilder,
    this.buttonChangePhoneBuilder,
    this.buttonVerifyOTPCodeBuilder,
  }) : super(key);
}

/// Récupère la configuration [KosmosSettingsConfig] depuis AppModel.
KosmosSettingsConfig getKosmosSettingsConfig() {
  var config = getAppModel().dependencies.packages[KosmosSettingsConfig.key];
  config ??= getAppModel().dependencies.packages["Kosmos-Settings"]; // legacy
  assert(
    config == null || config is KosmosSettingsConfig,
    'Type mismatch for ${KosmosSettingsConfig.key}',
  );
  return (config as KosmosSettingsConfig?) ??
      KosmosSettingsConfig(settingsSection: (ref) => []);
}

List<CelluleSection> _defaultSettingsSection(WidgetRef ref) =>
    <CelluleSection>[];
