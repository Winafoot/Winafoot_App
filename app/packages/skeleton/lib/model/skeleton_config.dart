import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';

enum LogoFormat { png, svg }

enum LoginType { email, id }

enum AuthTiers { apple, google, facebook }

class Link {
  final String Function(WidgetRef) title;
  final String url;
  final Function(BuildContext context, WidgetRef ref)? onTap;

  Link({required this.title, required this.url, this.onTap});
}

/// {@category Config}
/// {@category Skeleton}
///
///
class SkeletonAppConfig extends PackageConfig {
  /// Clé canonique pour l'enregistrement dans AppModel.dependencies.packages
  static const String key = "skeleton_app_config";
  final SkeletonAuthentificationConfig authentificationConfig;

  final PageRouteInfo? mainRouteInfo;

  final LogoFormat logoFormat;
  final String cloudRegion;
  final bool cgvuAllScrolable;

  final String logoPath;

  final List<Link>? bottomBarItem;
  final Widget Function(BuildContext, WidgetRef)? resetPasswordTitleBuilder;

  SkeletonAppConfig({
    required this.mainRouteInfo,
    this.authentificationConfig = const SkeletonAuthentificationConfig(),
    this.logoFormat = LogoFormat.svg,
    required this.logoPath,
    this.bottomBarItem,
    this.cloudRegion = "us-central1",
    this.cgvuAllScrolable = false,
    this.resetPasswordTitleBuilder,
  }) : super(key);
}

/// Récupère la configuration [SkeletonAppConfig] depuis AppModel.
SkeletonAppConfig getSkeletonAppConfig() {
  final config = getAppModel().dependencies.packages[SkeletonAppConfig.key];
  assert(
    config == null || config is SkeletonAppConfig,
    'Type mismatch for ${SkeletonAppConfig.key}',
  );
  return (config as SkeletonAppConfig?) ??
      SkeletonAppConfig(mainRouteInfo: null, logoPath: "");
}

/// {@category Config}
/// {@category Authentification}
///
///
class SkeletonAuthentificationConfig {
  /// add possibility to specify route for create account 'profil-completion'
  final Map<String, dynamic> profilCompletionRoutesPerUser;
  final Future<bool> Function(BuildContext context)? signInWithFacebook;
  final Widget Function(BuildContext, WidgetRef)? loginPageTitleBuilder;

  ///
  final Widget Function(BuildContext, WidgetRef)? webLoginPageTitleBuilder;
  final Widget Function(BuildContext, WidgetRef)? phonePageTitleBuilder;

  final Widget Function(BuildContext, WidgetRef)? loginButtonBuilder;
  //
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      loginButtonCustom;

  final Widget Function(BuildContext, WidgetRef)? phoneLoginButtonBuilder;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      phoneLoginButtonCustom;

  final Widget Function(BuildContext, WidgetRef)?
      otpValidationButtonTitleBuilder;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      otpValidationButtonCustom;
  final Widget Function(BuildContext, WidgetRef)? resetPasswordButtonBuilder;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      resetPasswordButtonCustom;

  final Widget Function(BuildContext, WidgetRef)? verifyEmailButtonBuilder;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      verifyEmailButtonCustom;

  final Widget Function(BuildContext, WidgetRef)? cgvuButtonTitleBuilder;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      cgvuButtonCustom;
  final Widget Function(BuildContext, WidgetRef)?
      createAccountButtonTitleBuilder;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      createAccountButtonCustom;
  final Widget Function(BuildContext, WidgetRef)?
      validateOTPCreateAccountButtonTitleBuilder;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      validateOTPCreateAccountButtonCustom;

  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      changeEmailButtonCustom;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      changePasswordButtonCustom;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      changePhoneButtonCustom;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      validateChangePhoneOtpButtonCustom;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      setPhoneButtonCustom;
  final Widget Function(BuildContext, WidgetRef, VoidCallback)?
      validateSetPhoneOtpButtonCustom;

  final Widget Function(BuildContext, WidgetRef)?
      signinPhoneConfirmationPageTitleBuilder;
  final Widget Function(BuildContext, WidgetRef)?
      registerPhoneConfirmationPageTitleBuilder;
  final Widget Function(BuildContext, WidgetRef)? registerPageTitleBuilder;

  final String? Function(BuildContext, UserModel)? showCompleteProfil;

  final dynamic Function(BuildContext context)? onBackLoginPage;
  final Function(BuildContext)? onBackCreateAccountPage;

  final bool registerFirst;

  /// Si l'email doit être vérifié pour accéder à l'application, par défaut ```false```.
  final bool emailMustBeVerified;

  /// Si nous devons envoyer un mail de vérification à la création de la page, par défaut ```true```.
  final bool sendVerificationEmail;

  /// Si l'email doit être vérifié pour accéder à l'application, par défaut ```true```.
  final bool sendEmailVerificationIfNotVerified;

  /// La route par défaut après la connexion, par défaut ```/login```.
  final String loginDefaultRoute;

  /// this is the user type, by default ```null```.
  /// if you need to have the user type when you create an account [to use the {onCreate.'users'}], you can use this.
  final String? userType;

  final FutureOr<String>? Function(BuildContext)? getUserType;

  /// Si l'utilisateur peut créer un compte, par défaut ```true```.
  final bool canCreateAccount;

  /// Si l'utilisateur peut voir le buttonBack page de profil, par défaut ```true```.
  final bool showBackButton;

  /// Si l'utilisateur peut accéder à une page sans être connecté, par défaut ```false```.
  final bool canAccessLogout;

  /// Si l'utilisateur peut se connecter avec son numéro de téléphone, par défaut ```true```.
  final bool canLoginWithPhone;

  /// Si l'utilisateur peut réinitialiser son mot de passe, par défaut ```true```.
  final bool canResetPassword;

  /// Le type de login, par défaut ```LoginType.email```.
  final LoginType loginType;

  /// Les tiers d'authentification, par défaut ```[]```. (Ex: Apple, Google, Facebook)
  final List<AuthTiers> authTiers;

  /// La fonction à exécuter après la connexion.
  final FutureOr<bool?> Function(BuildContext)? loginSuccess;

  /// La route à afficher si l'utilisateur n'est pas connecté.
  final PageRouteInfo? notLoggedRoute;

  /// Si nous devons afficher le logo sur la page de connexion, par défaut ```true```.
  final bool showLogoOnPage;

  final FutureOr<void> Function(BuildContext, WidgetRef)? logoutCallback;

  final bool enableLocalAuth;

  final String? loginWithPhoneRoute;
  final String? createAccountRoute;
  final String phoneKey;
  final double cgvuButtonWidth;

  /// Default action of alreadyHaveAccount is AutoRouter.of(context).pushNamed("/auth/login");
  final FutureOr<bool?> Function(BuildContext)? alreadyHaveAccount;

  /// Affiche l'astérisque "*" sur les champs requis des pages
  /// d'authentification, par défaut ```true```.
  /// La validation des champs reste gérée par les validators.
  final bool showRequiredAsterixAuth;

  /// Si ```false```, l'utilisateur n'est jamais redirigé vers la page
  /// de complétion de profil même si ```profilCompleted != true```,
  /// par défaut ```true```.
  final bool requireProfilCompletion;

  const SkeletonAuthentificationConfig(
      {this.emailMustBeVerified = false,
      this.webLoginPageTitleBuilder,
      this.showBackButton = true,
      this.onBackLoginPage,
      this.registerFirst = false,
      this.onBackCreateAccountPage,
      this.cgvuButtonWidth = 170,
      this.cgvuButtonCustom,
      this.getUserType,
      this.showCompleteProfil,
      this.signInWithFacebook,
      this.userType,
      this.sendEmailVerificationIfNotVerified = true,
      this.sendVerificationEmail = true,
      this.loginDefaultRoute = "/auth/login",
      this.canCreateAccount = true,
      this.canLoginWithPhone = true,
      this.canAccessLogout = false,
      this.canResetPassword = true,
      this.logoutCallback,
      this.loginType = LoginType.email,
      this.loginSuccess,
      this.phoneKey = "FR",
      this.authTiers = const <AuthTiers>[],
      this.notLoggedRoute,
      this.showLogoOnPage = true,
      this.enableLocalAuth = true,
      this.createAccountRoute,
      this.loginWithPhoneRoute,
      this.loginPageTitleBuilder,
      this.phonePageTitleBuilder,
      this.signinPhoneConfirmationPageTitleBuilder,
      this.registerPhoneConfirmationPageTitleBuilder,
      this.registerPageTitleBuilder,
      this.alreadyHaveAccount,
      this.showRequiredAsterixAuth = true,
      this.requireProfilCompletion = true,
      this.verifyEmailButtonBuilder,
      this.phoneLoginButtonBuilder,
      this.loginButtonBuilder,
      this.resetPasswordButtonBuilder,
      this.cgvuButtonTitleBuilder,
      this.otpValidationButtonTitleBuilder,
      this.createAccountButtonTitleBuilder,
      this.validateOTPCreateAccountButtonTitleBuilder,
      this.profilCompletionRoutesPerUser = const <String, dynamic>{
        "default": "profil-completion"
      },
      this.createAccountButtonCustom,
      this.validateOTPCreateAccountButtonCustom,
      this.loginButtonCustom,
      this.otpValidationButtonCustom,
      this.phoneLoginButtonCustom,
      this.resetPasswordButtonCustom,
      this.verifyEmailButtonCustom,
      this.changeEmailButtonCustom,
      this.changePasswordButtonCustom,
      this.changePhoneButtonCustom,
      this.validateChangePhoneOtpButtonCustom,
      this.setPhoneButtonCustom,
      this.validateSetPhoneOtpButtonCustom});
}
