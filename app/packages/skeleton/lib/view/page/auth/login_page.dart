// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:kosmos_auth/controller/auth.dart';
import 'package:skeleton/controller/tiers_auth_controller.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:skeleton/skeleton.dart';
import 'package:skeleton/view/widget/parent/auth_parent.dart';
import 'package:ui_kosmos_v4/alert/theme/alert_theme.dart';
import 'package:ui_kosmos_v4/checkbox/checkbox.dart';
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulHookConsumerWidget {
  final void Function(BuildContext)? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isPopupUsed = false;

  final FocusNode _emailOrIdFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  late ThemeData? lightTheme;
  late ThemeData? darkTheme;

  final TextEditingController _passwordController = TextEditingController();

  String? emailOrId;
  String? password;
  bool _isEmailError = false;
  bool _isPassError = false;
  bool _cguAccepted = false;

  @override
  void initState() {
    if (config?.authentificationConfig.enableLocalAuth ?? false) {
      execAfterBuild(_tryLogginByLocalAuth);
    }
    init();
    super.initState();
  }

  void init() {
    if (GetIt.instance.isRegistered<AppTheme>()) {
      lightTheme = GetIt.instance<AppTheme>().themeData;
      darkTheme = GetIt.instance<AppTheme>().themeDataDark;
    }
  }

  @override
  void dispose() {
    _emailOrIdFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final themeData = loadThemeData<AuthTemplateThemeData>(
      null,
      "authentication_theme",
      () => const AuthTemplateThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    late final buttonThemeData = loadThemeData<KosmosButtonThemeData>(
      null,
      "button_primary",
      () => const KosmosButtonThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    if (RouteData.of(context).queryParams.rawMap["logout"].toString() ==
            "true" &&
        !_isPopupUsed) {
      final isDelete = (RouteData.of(context)
              .queryParams
              .rawMap["deleteAccount"]
              .toString() ==
          "true");
      _isPopupUsed = true;
      execAfterBuild(() => PopupAlert.toast(context, FToast().init(context),
          title: "utils.success".tr(),
          subtitle:
              "package.skeleton.profile.${isDelete ? "delete" : "logout"}-success"
                  .tr(),
          type: AlertType.success));
    }

    return Scaffold(
      backgroundColor: ref.watch(isDarkModeProvider).isDarkMode
          ? darkTheme?.scaffoldBackgroundColor
          : lightTheme?.scaffoldBackgroundColor,
      body: AuthParent(
        showBackButton: config?.authentificationConfig.showBackButton ?? true,
        backgroundPage: themeData.emailLoginPageBackground?.call(context, ref),
        onBack: config?.authentificationConfig.onBackLoginPage,
        logoSize: themeData.logoSize,
        child: Form(
          key: _formKey,
          child: getResponsiveValue(context,
              defaultValue:
                  _buildWeb(context, config, themeData, buttonThemeData),
              phone: _buildPhone(context, themeData, buttonThemeData)),
        ),
      ),
    );
  }

  Widget _buildPhone(BuildContext context, AuthTemplateThemeData themeData,
      KosmosButtonThemeData buttonThemeData,
      [EdgeInsetsGeometry? padding]) {
    return Padding(
      padding: padding ??
          themeData.formPadding ??
          EdgeInsets.symmetric(horizontal: formatWidth(29)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          config?.authentificationConfig.loginPageTitleBuilder
                  ?.call(context, ref) ??
              Padding(
                padding: themeData.titlePadding ?? EdgeInsets.zero,
                child: Center(
                  child: Text(
                    "package.skeleton.auth.login-title".tr(),
                    textAlign: TextAlign.center,
                    style: themeData.titleStyle ?? DefaultAppStyle.darkBlue(23),
                  ),
                ),
              ),
          SizedBox(height: themeData.titleAndFormSpacing ?? formatHeight(44)),
          FormClassicField(
            fieldName: (config?.authentificationConfig.identifierEmailDomain !=
                        null
                    ? "package.field.auth.email-or-identifier.title"
                    : "package.field.auth.email-or-id.title")
                .tr(),
            hintText: (config?.authentificationConfig.identifierEmailDomain !=
                        null
                    ? "package.field.auth.email-or-identifier.hint"
                    : "package.field.auth.email-or-id.hint")
                .tr(),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            focusNode: _emailOrIdFocusNode,
            nextNode: _passwordFocusNode,
            isError: _isEmailError,
            isRequired: false,
            fieldAction:
                (config?.authentificationConfig.canLoginWithPhone ?? false)
                    ? "package.skeleton.auth.login-with-phone".tr()
                    : null,
            fieldActionOnTap: () {
              if ((config?.authentificationConfig.canLoginWithPhone ?? false)) {
                AutoRouter.of(context).navigateNamed(
                    config?.authentificationConfig.loginWithPhoneRoute ??
                        "/auth/login-with-phone");
              }
            },
            validator: (value) {
              // Avec un domaine d'identifiant, une saisie sans « @ » est un
              // identifiant : il suffit qu'elle ne soit pas vide.
              final bool isIdentifier =
                  config?.authentificationConfig.identifierEmailDomain !=
                          null &&
                      !(value ?? '').contains('@');
              final rep = isIdentifier ||
                      config?.authentificationConfig.loginType == LoginType.id
                  ? FieldValidator.fieldNotEmpty(value)
                  : AuthValidator.validEmail(value);
              if (rep != null) {
                setState(() => _isEmailError = true);
              } else {
                setState(() => _isEmailError = false);
              }
              return rep;
            },
            onChanged: (val) => emailOrId = val,
          ),
          sh(14),
          FormClassicField(
            fieldName: "package.field.auth.password.title".tr(),
            hintText: "package.field.auth.password.hint".tr(),
            focusNode: _passwordFocusNode,
            controller: _passwordController,
            isError: _isPassError,
            isRequired: false,
            isSecretField: true,
            validator: (value) {
              final rep = FieldValidator.fieldNotEmpty(value);
              if (rep != null) {
                setState(() => _isPassError = true);
              } else {
                setState(() => _isPassError = false);
              }
              return rep;
            },
            onChanged: (val) => password = val,
          ),
          if (config?.authentificationConfig.canResetPassword ?? false) ...[
            sh(15),
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${"package.skeleton.auth.forgot-password".tr()} ",
                      style: themeData.linkDescriptionStyle ??
                          DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                    ),
                    TextSpan(
                      text: "package.skeleton.auth.reset-password".tr(),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => getResponsiveValue(
                              context,
                              defaultValue: () async => await _resetPassword(
                                  context, themeData, buttonThemeData),
                              phone: () async => await _resetPassword(
                                  context, themeData, buttonThemeData),
                            ).call(),
                      style: themeData.linkStyle ??
                          DefaultAppStyle.darkBlue(13, FontWeight.w500)
                              .copyWith(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          sh(42),
          config?.authentificationConfig.loginButtonCustom?.call(
                context,
                ref,
                () async => await _login(context, themeData, buttonThemeData),
              ) ??
              Button(
                text: config?.authentificationConfig.loginButtonBuilder == null
                    ? "utils.connexion".tr()
                    : null,
                height: buttonThemeData.height,
                onTap: () async =>
                    await _login(context, themeData, buttonThemeData),
                child: config?.authentificationConfig.loginButtonBuilder
                    ?.call(context, ref),
              ),
          if (config?.authentificationConfig.authTiers.isNotEmpty ?? false) ...[
            sh(35),
            Center(
              child: Text(
                "package.skeleton.auth.or-connect-with".tr(),
                style: themeData.subtitleStyle ??
                    DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            sh(20),
            Selector(
              type: CheckboxType.square,
              sideText: "utils.accept-cgvu-and-confidentiality".tr(),
              onChanged: (_) => setState(() => _cguAccepted = !_cguAccepted),
              isChecked: _cguAccepted,
            ),
            sh(20),
            LayoutBuilder(
              builder: (_, c) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: config!.authentificationConfig.authTiers.map((e) {
                    final isLast =
                        config!.authentificationConfig.authTiers.last == e;
                    final svgPath = {
                      AuthTiers.apple: "assets/svg/apple.svg",
                      AuthTiers.google: "assets/svg/google.svg",
                      AuthTiers.facebook: "assets/svg/meta.svg",
                    }[e]!;

                    final length =
                        config!.authentificationConfig.authTiers.length;

                    return Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: themeData.authTiersExtended
                                  ? (c.maxWidth / length) -
                                      (formatWidth(18) * (length - 1))
                                  : formatWidth(102)),
                          child: AuthTiersButton(
                            onTap: () async {
                              final rep = await {
                                AuthTiers.apple: () async =>
                                    await TiersAuthController.signInWithTiers(
                                        context, ref, AuthTiers.apple,
                                        cguAccepted: _cguAccepted),
                                AuthTiers.google: () async =>
                                    await TiersAuthController.signInWithTiers(
                                        context, ref, AuthTiers.google,
                                        cguAccepted: _cguAccepted),
                                AuthTiers.facebook: () async =>
                                    await TiersAuthController.signInWithTiers(
                                        context, ref, AuthTiers.facebook,
                                        cguAccepted: _cguAccepted),
                              }[e]!
                                  .call();

                              if (!rep) return;

                              if (!FirebaseAuth
                                      .instance.currentUser!.emailVerified &&
                                  (config?.authentificationConfig
                                          .emailMustBeVerified ??
                                      false)) {
                                PopupAlert.toast(
                                    context, FToast().init(context),
                                    title: "utils.error".tr(),
                                    subtitle:
                                        "package.kosmos-auth.email-must-be-verified"
                                            .tr());
                                await FirebaseAuth.instance.signOut();
                                _passwordController.clear();
                                return;
                              }

                              if (config != null &&
                                  config!.mainRouteInfo != null) {
                                if (mounted) {
                                  AutoRouter.of(context).pushAndPopUntil(
                                      config!.mainRouteInfo!,
                                      predicate: (_) => false);
                                }
                              } else {
                                if (mounted) {
                                  AutoRouter.of(context).popUntilRoot();
                                  AutoRouter.of(context).replaceNamed("/");
                                }
                              }
                            },
                            width: themeData.authTiersExtended
                                ? (c.maxWidth / length) -
                                    (formatWidth(10) * (length - 1))
                                : formatWidth(102),
                            height:
                                themeData.authTiersHeight ?? formatHeight(54),
                            padding: themeData.authTiersPadding ?? ph(10),
                            child: SvgPicture.asset(
                              svgPath,
                              // height: formatHeight(21.5),
                              color: ref.watch(isDarkModeProvider).isDarkMode
                                  ? Colors.white
                                  : null,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        if (!isLast) sw(18),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ],
          if (config?.authentificationConfig.canCreateAccount ?? false) ...[
            sh(35),
            Center(
                child: Container(
                    width: formatWidth(37),
                    height: .5,
                    color: themeData.dividerColor ?? DefaultColor.lightGrey)),
            sh(26),
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${"package.skeleton.auth.no-account".tr()} ",
                      style: themeData.linkDescriptionStyle ??
                          DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                    ),
                    TextSpan(
                      text: "package.skeleton.auth.create-account".tr(),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () =>
                            config?.authentificationConfig.registerFirst ==
                                        true &&
                                    AutoRouter.of(context)
                                        .stack
                                        .map((e) => e.name)
                                        .toList()
                                        .contains("CreateAccountRoute")
                                ? AutoRouter.of(context).pop()
                                : AutoRouter.of(context).navigateNamed(
                                    config?.authentificationConfig
                                            .createAccountRoute ??
                                        "/auth/create-account",
                                  ),
                      style: themeData.linkStyle ??
                          DefaultAppStyle.darkBlue(13, FontWeight.w500)
                              .copyWith(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (config?.authentificationConfig.canAccessLogout ?? false) ...[
            sh(35),
            Center(
                child: Container(
                    width: formatWidth(37),
                    height: .5,
                    color: themeData.dividerColor ?? DefaultColor.lightGrey)),
            sh(26),
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${"package.skeleton.auth.not-connected".tr()} ",
                      style: themeData.linkDescriptionStyle ??
                          DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                    ),
                    TextSpan(
                      text: "package.skeleton.auth.not-connected-redirect".tr(),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => AutoRouter.of(context).pushAndPopUntil(
                              config!.authentificationConfig.notLoggedRoute ??
                                  config!.mainRouteInfo ??
                                  const PageRouteInfo("DefaultRoute",
                                      path: "/"),
                              predicate: (_) => false,
                            ),
                      style: themeData.linkStyle ??
                          DefaultAppStyle.darkBlue(13, FontWeight.w500)
                              .copyWith(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + formatHeight(3)),
        ],
      ),
    );
  }

  /// Build Web UI
  Widget _buildWeb(BuildContext context, SkeletonAppConfig? config,
      AuthTemplateThemeData themeData, KosmosButtonThemeData buttonThemeData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        config?.authentificationConfig.webLoginPageTitleBuilder
                ?.call(context, ref) ??
            SizedBox(),
        Container(
          constraints: themeData.webformConstraints ??
              BoxConstraints(maxWidth: formatWidth(536)),
          width: MediaQuery.of(context).size.width * .7,
          decoration: themeData.webBoxDecoration ??
              BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(r(23)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .15),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
          padding: themeData.webBoxPadding ?? pwh(54, 83),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!kIsWeb) ...[
                if (config?.authentificationConfig.showBackButton ?? true)
                  ButtonBack(
                      onTap: () => config
                          ?.authentificationConfig.onBackLoginPage
                          ?.call(context),
                      padding:
                          EdgeInsets.symmetric(horizontal: formatWidth(27.5))),
                sh(20),
              ],
              _buildPhone(context, themeData, buttonThemeData),
            ],
          ),
        ),
      ],
    );
  }

  /// Affiche un Botom Modal Sheet pour réinitialiser le mot de passe.
  /// L'utilisateur doit entrer son email, puis un email lui sera envoyé
  /// avec un lien pour réinitialiser son mot de passe.
  Future<void> _resetPassword(
      BuildContext context,
      AuthTemplateThemeData themeData,
      KosmosButtonThemeData buttonThemeData) async {
    if (kIsWeb) {
      await AutoRouter.of(context).pushNamed("/auth/reset-password");
      return;
    }

    String? resetEmail;
    final GlobalKey<FormState> resetPasswordFormKey = GlobalKey<FormState>();

    final _ = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: themeData.modalBottomSheetShapeBorder ??
          RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r(55)))),
      backgroundColor: themeData.popupBackgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        return Padding(
          padding: themeData.formPadding ??
              EdgeInsets.symmetric(horizontal: formatWidth(29)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sh(16),
              Center(
                child: Container(
                  width: formatWidth(43),
                  height: 4,
                  decoration: BoxDecoration(
                      color: themeData.dividerColor ?? DefaultColor.lightGrey,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              sh(19.5),
              Center(
                child: config?.resetPasswordTitleBuilder?.call(context, ref) ??
                    Text(
                      "package.skeleton.auth.reset-password-modal.title".tr(),
                      style: themeData.popupTitleStyle ??
                          DefaultAppStyle.darkBlue(17),
                      textAlign: TextAlign.center,
                    ),
              ),
              sh(10),
              Center(
                child: Text(
                  "package.skeleton.auth.reset-password-modal.subtitle".tr(),
                  style: themeData.subtitleStyle ??
                      DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              sh(33),
              Form(
                key: resetPasswordFormKey,
                child: FormClassicField(
                  isRequired: false,
                  fieldName: "package.field.auth.email.title".tr(),
                  hintText: "package.field.auth.email.hint".tr(),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: AuthValidator.validEmail,
                  onChanged: (val) => resetEmail = val,
                ),
              ),
              sh(40),
              config?.authentificationConfig.resetPasswordButtonCustom?.call(
                    context,
                    ref,
                    () async {
                      if (!(resetPasswordFormKey.currentState?.validate() ??
                          false)) {
                        return;
                      }
                      resetEmail = resetEmail?.trim();
                      final emailExist = await KosmosAuth.emailDoesExist(
                        resetEmail!,
                        region: config?.cloudRegion ?? "us-central1",
                      );
                      await emailExist.fold((l) {
                        PopupAlert.toast(context, FToast().init(context),
                            title: "utils.error".tr(),
                            subtitle: l.toString(),
                            type: AlertType.error);
                        return;
                      }, (r) async {
                        if (!r) {
                          PopupAlert.toast(context, FToast().init(context),
                              title: "utils.error".tr(),
                              subtitle:
                                  "package.kosmos-auth.user-not-found".tr(),
                              type: AlertType.error);
                          return;
                        }
                        final res = await KosmosAuth.resetPassword(resetEmail!,
                            region: config?.cloudRegion ?? "us-central1");
                        res.fold((l) {
                          PopupAlert.toast(context, FToast().init(context),
                              title: "utils.error".tr(),
                              subtitle: l.toString(),
                              type: AlertType.error);
                          Navigator.of(ctx).pop();
                        }, (r) {
                          final themeData = loadThemeData(
                              null, "dialog_alert", () => const AlertTheme(),
                              isDark: ref.watch(isDarkModeProvider).isDarkMode);
                          PopupAlert.dialogBox(context,
                              title: "package.skeleton.auth.verify-email".tr(),
                              subtitle:
                                  "package.skeleton.auth.verify-email-subtitle"
                                      .tr(),
                              actionsBuilder: [
                                (_) => Center(
                                      child: Button(
                                        text: "utils.close".tr(),
                                        buttonType: ButtonType.primary,
                                        width: themeData?.buttonWidth ??
                                            formatWidth(140),
                                        height: buttonThemeData.height,
                                        onTap: () => Navigator.of(_).pop(),
                                      ),
                                    ),
                              ]);
                          Navigator.of(ctx).pop(true);
                        });
                      });
                    },
                  ) ??
                  Button(
                    text: config?.authentificationConfig
                                .resetPasswordButtonBuilder ==
                            null
                        ? "utils.reinit".tr()
                        : null,
                    buttonType: ButtonType.primary,
                    height: buttonThemeData.height,
                    onTap: () async {
                      if (!(resetPasswordFormKey.currentState?.validate() ??
                          false)) {
                        return;
                      }
                      resetEmail = resetEmail?.trim();
                      final emailExist = await KosmosAuth.emailDoesExist(
                        resetEmail!,
                        region: config?.cloudRegion ?? "us-central1",
                      );
                      await emailExist.fold((l) {
                        PopupAlert.toast(context, FToast().init(context),
                            title: "utils.error".tr(),
                            subtitle: l.toString(),
                            type: AlertType.error);
                        return;
                      }, (r) async {
                        if (!r) {
                          PopupAlert.toast(context, FToast().init(context),
                              title: "utils.error".tr(),
                              subtitle:
                                  "package.kosmos-auth.user-not-found".tr(),
                              type: AlertType.error);
                          return;
                        }
                        final res = await KosmosAuth.resetPassword(resetEmail!,
                            region: config?.cloudRegion ?? "us-central1");
                        res.fold((l) {
                          PopupAlert.toast(context, FToast().init(context),
                              title: "utils.error".tr(),
                              subtitle: l.toString(),
                              type: AlertType.error);
                          Navigator.of(ctx).pop();
                        }, (r) {
                          final themeData = loadThemeData(
                              null, "dialog_alert", () => const AlertTheme(),
                              isDark: ref.watch(isDarkModeProvider).isDarkMode);
                          PopupAlert.dialogBox(context,
                              title: "package.skeleton.auth.verify-email".tr(),
                              subtitle:
                                  "package.skeleton.auth.verify-email-subtitle"
                                      .tr(),
                              actionsBuilder: [
                                (_) => Center(
                                      child: Button(
                                        text: "utils.close".tr(),
                                        buttonType: ButtonType.primary,
                                        width: themeData?.buttonWidth ??
                                            formatWidth(140),
                                        height: buttonThemeData.height,
                                        onTap: () => Navigator.of(_).pop(),
                                      ),
                                    ),
                              ]);
                          Navigator.of(ctx).pop(true);
                        });
                      });
                    },
                    child: config
                        ?.authentificationConfig.resetPasswordButtonBuilder
                        ?.call(context, ref),
                  ),
              SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom + formatHeight(12)),
            ],
          ),
        );
      },
    );
  }

  /// Back-End ///
  Future<void> _login(BuildContext context, AuthTemplateThemeData themeData,
      KosmosButtonThemeData buttonThemeData,
      [String? savedEmail, String? savedPass]) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (savedEmail == null || savedPass == null) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }

    final authType =
        config?.authentificationConfig.loginType ?? LoginType.email;
    String email = savedEmail ?? emailOrId!;
    String pass = savedPass ?? password!;

    /// Identifiant (sans « @ ») -> adresse technique du domaine configuré
    final String? identifierDomain =
        config?.authentificationConfig.identifierEmailDomain;
    if (identifierDomain != null) {
      email = LoginIdentifier.toEmail(email, identifierDomain);
    }

    /// fetch email from FirebaseFirestore if login with id
    if (authType == LoginType.id && savedEmail == null) {
      final res = await KosmosAuth.getEmailFromIdentifier(emailOrId!);
      final canContinue = res.fold<bool>((l) {
        PopupAlert.toast(context, FToast().init(context),
            title: "utils.error".tr(),
            subtitle: l.toString(),
            type: AlertType.error);
        return false;
      }, (r) {
        email = r!;
        return true;
      });
      if (!canContinue) return;
    }

    /// Login with email
    final res = await KosmosAuth.signInWithEmail(email, pass);
    final canContinue = res.fold<bool>((l) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: l.toString(),
          type: AlertType.error);
      return false;
    }, (r) {
      /// Login success
      printInfo("Success login with email: $email");
      LocalAuthController.rememberCredentials(email, pass);
      return true;
    });

    if (!canContinue) return;

    if (mounted &&
        (await config?.authentificationConfig.loginSuccess?.call(context) ??
            false)) {
      return;
    }

    if (!FirebaseAuth.instance.currentUser!.emailVerified &&
        (config?.authentificationConfig.emailMustBeVerified ?? false)) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: "package.kosmos-auth.email-must-be-verified".tr());
      await FirebaseAuth.instance.signOut();
      _passwordController.clear();
      return;
    }

    final userCguData = await UserController.isCguAccepted();
    if (!userCguData) {
      if (!await _showCguDialog(context, themeData, buttonThemeData)) {
        PopupAlert.toast(context, FToast().init(context),
            title: "utils.error".tr(),
            subtitle: "package.skeleton.new-cgu-must-be-accepted".tr());
        _passwordController.clear();
        return;
      }
    }

    final userPushNotif =
        (await LocalConfigController.getData<bool?>("authorized_push_notif") ==
                true) &&
            await UserController.isAuthorizedPushNotif();
    if (userPushNotif) {
      // Fire-and-forget : la configuration push ne doit jamais bloquer le
      // login. Les appels Firebase Messaging peuvent rester suspendus si
      // l'APNS token iOS n'est pas encore disponible.
      // On passe `fromSettings: false` car on n'est pas dans l'écran Settings.
      unawaited(NotifPermissionController.setPushNotificationPermission(
          context, ref, true, FirebaseAuth.instance.currentUser!.uid, false));
    } else {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("metadata")
          .doc("metadata")
          .update(
        {
          "fcmToken": null,
          "enablePushNotification": false,
        },
      );
    }

    await ref.read(userProvider).init(context);

    AnalyticsAuthController.login();

    if (widget.onLoginSuccess != null) {
      return widget.onLoginSuccess!(context);
    }

    if (config != null && config!.mainRouteInfo != null) {
      if (mounted) {
        AutoRouter.of(context)
            .pushAndPopUntil(config!.mainRouteInfo!, predicate: (_) => false);
      }
    } else {
      if (mounted) {
        AutoRouter.of(context).popUntilRoot();
        AutoRouter.of(context).replaceNamed("/");
      }
    }
  }

  Future<bool> _showCguDialog(
      BuildContext context,
      AuthTemplateThemeData themeData,
      KosmosButtonThemeData buttonThemeData) async {
    final ScrollController scrollController = ScrollController();
    final future = AppMetadataController.getMetadataConfig();

    final rep = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: themeData.modalBottomSheetShapeBorder ??
          RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r(55)))),
      builder: (ctx) {
        bool cgvuAccepted = false;
        return StatefulBuilder(builder: (_, newState) {
          return Padding(
            padding: themeData.formPadding ??
                EdgeInsets.symmetric(horizontal: formatWidth(29)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sh(16),
                Center(
                  child: Container(
                    width: formatWidth(43),
                    height: 4,
                    decoration: BoxDecoration(
                        color: themeData.dividerColor ?? DefaultColor.lightGrey,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                sh(19.5),
                Center(
                  child: Text(
                    "utils.cgvu-and-confidentiality".tr(),
                    style: themeData.popupTitleStyle ??
                        DefaultAppStyle.darkBlue(17),
                    textAlign: TextAlign.center,
                  ),
                ),
                sh(19),
                SizedBox(
                  height: formatHeight(430),
                  child: FutureBuilder<AppMetadataConfig?>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final cgvu = snapshot.data?.cgvu;
                      return Scrollbar(
                        controller: scrollController,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          child: HtmlWidget(
                            cgvu ?? "",
                            textStyle: themeData.htmlTextStyle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                sh(16),
                Selector(
                  type: CheckboxType.square,
                  sideText: "utils.accept-cgvu-and-confidentiality".tr(),
                  onChanged: (val) => newState(() => cgvuAccepted = !val),
                  isChecked: cgvuAccepted,
                ),
                sh(33),
                Center(
                  child: config?.authentificationConfig.cgvuButtonCustom?.call(
                        context,
                        ref,
                        () {
                          Navigator.pop(context, true);
                        },
                      ) ??
                      Button(
                        text: config?.authentificationConfig
                                    .cgvuButtonTitleBuilder ==
                                null
                            ? "utils.continue".tr()
                            : null,
                        height: buttonThemeData.height,
                        width: formatWidth(170),
                        enabled: cgvuAccepted,
                        onTap: () {
                          Navigator.pop(context, true);
                        },
                        child: config
                            ?.authentificationConfig.cgvuButtonTitleBuilder
                            ?.call(context, ref),
                      ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        formatHeight(12)),
              ],
            ),
          );
        });
      },
    );
    if (!(rep ?? false)) {
      await FirebaseAuth.instance.signOut();
      return false;
    }
    await UserController.acceptCgu();
    return true;
  }

  Future<void> _tryLogginByLocalAuth(AuthTemplateThemeData themeData,
      KosmosButtonThemeData buttonThemeData) async {
    final t = await LocalConfigController.getData<bool>("biometrics");
    if (!(t ?? false)) return;

    final data = await LocalAuthController.getLoginData();

    if (data == null) return;

    final LocalAuthentication auth = LocalAuthentication();

    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    if (!canAuthenticate) return;

    try {
      final bool didAuthenticate =
          await auth.authenticate(localizedReason: 'login');
      if (didAuthenticate) {
        ref.read(localAuthVerifiedProvider.notifier).state = true;
        await _login(
            context, themeData, buttonThemeData, data.value1, data.value2);
      }
    } catch (e) {
      printExcept(e);
      return;
    }
  }
}
