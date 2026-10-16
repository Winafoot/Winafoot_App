// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:dartz/dartz.dart' as dz;
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:kosmos_auth/controller/auth.dart';
import 'package:kosmos_auth/utils/error_handler.dart';
import 'package:ui_kosmos_v4/alert/theme/alert_theme.dart';
import 'package:ui_kosmos_v4/checkbox/checkbox.dart';

import 'package:skeleton/controller/tiers_auth_controller.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:skeleton/skeleton.dart';
import 'package:skeleton/view/widget/parent/auth_parent.dart';

class CreateAccountPage extends StatefulHookConsumerWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

  final PageController _pageController = PageController(initialPage: 0);
  final PasswordSecurityConfig? passwordSecurityConfig =
      GetIt.I.isRegistered<AppMetadataConfig>()
          ? GetIt.I<AppMetadataConfig>().passwordSecurityConfig
          : null;

  final TextEditingController pinTextEditingController =
      TextEditingController();
  Timer? timer;
  String? codeMessage;
  Duration? validationTimeCode;

  String? email, password, confirmPassword;
  String? code, _codeId;
  PhoneNumber? phoneNumber;
  int _currentStep = 0;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isEmailError = false, _isPasswordError = false;
  PasswordStrengthQuality? _passwordStrength;

  FocusNode? emailFocusNode,
      passwordFocusNode,
      confirmPasswordFocusNode,
      phoneNumberFocusNode;
  bool loading = false;

  @override
  void initState() {
    _passwordController.addListener(() {
      if (_isPasswordError) {
        setState(() {
          _passwordStrength =
              AuthValidator.passwordStrength(_passwordController.text);
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    _pageController.dispose();
    emailFocusNode?.dispose();
    passwordFocusNode?.dispose();
    confirmPasswordFocusNode?.dispose();
    phoneNumberFocusNode?.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    late final themeData = loadThemeData<AuthTemplateThemeData>(
      null,
      "authentication_theme",
      () => const AuthTemplateThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    return Scaffold(
      body: AuthParent(
        hideLogo: config?.authentificationConfig.registerFirst == true,
        appBarActionWidget: config?.authentificationConfig.registerFirst ==
                    true &&
                _currentStep == 0
            ? (context) {
                return Positioned(
                  right: 0,
                  bottom: 0,
                  top: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      sw(80),
                      Text(
                        "package.skeleton.auth.already-have-account".tr(),
                        style: themeData.appBarPreActionWidgetTitleStyle ??
                            DefaultAppStyle.simpleGrey(13, FontWeight.w400),
                      ),
                      InkWell(
                        highlightColor: Colors.transparent,
                        onTap:
                            config?.authentificationConfig.alreadyHaveAccount !=
                                    null
                                ? () => config!.authentificationConfig
                                    .alreadyHaveAccount!(context)
                                : () {
                                    AutoRouter.of(
                                      context,
                                    ).pushNamed("/auth/login");
                                  },
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: formatWidth(28),
                            top: formatHeight(5),
                            left: formatWidth(5),
                            bottom: formatHeight(5),
                          ),
                          child: Text(
                            "package.skeleton.auth.signin".tr(),
                            style: themeData.appBarActionWidgetTitleStyle ??
                                DefaultAppStyle.darkBlue(
                                  13,
                                  FontWeight.w600,
                                ).copyWith(
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            : null,
        backgroundPage: _currentStep == 0
            ? themeData.signupPageBckground?.call(context, ref)
            : themeData.pinSignupVerficationLoginPageBackground
                ?.call(context, ref),
        logoSize: themeData.logoSize,
        onBack: config?.authentificationConfig.onBackCreateAccountPage != null
            ? (ctx) => config!.authentificationConfig.onBackCreateAccountPage!(
                  context,
                )
            : (context) {
                if (_pageController.hasClients && _pageController.page! != 0) {
                  _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease);
                } else {
                  if (config?.authentificationConfig.registerFirst == true) {
                    context.pop();
                  } else {
                    AutoRouter.of(context).navigateBack();
                  }
                }
              },
        child: getResponsiveValue(
          context,
          defaultValue: _buildWeb(context, themeData),
          phone: _buildPhone(context, themeData),
        ),
      ),
    );
  }

  Widget _buildPhone(BuildContext context, AuthTemplateThemeData themeData) {
    return ExpandablePageView(
      clipBehavior: Clip.none,
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentStep = index;
        });
      },
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _formView(context, themeData),
        _confirmCodeView(context, themeData)
      ],
    );
  }

  Widget _buildWeb(BuildContext context, AuthTemplateThemeData themeData) {
    return Container(
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
                  onTap: config?.authentificationConfig
                              .onBackCreateAccountPage !=
                          null
                      ? () => config!
                              .authentificationConfig.onBackCreateAccountPage!(
                            context,
                          )
                      : () {
                          if (_pageController.hasClients &&
                              _pageController.page! != 0) {
                            _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease);
                          } else {
                            if (config?.authentificationConfig.registerFirst ==
                                true) {
                              context.pop();
                            } else {
                              AutoRouter.of(context).navigateBack();
                            }
                          }
                        },
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(27.5))),
            sh(20),
          ],
          _buildPhone(context, themeData),
        ],
      ),
    );
  }

  /// Vérifie les valeurs du formulaires, affiche une modal bottom sheet
  /// pour accepter les conditions d'utilisation
  /// et politique de confidentialité et passe à la page suivante une fois
  /// que l'utilisateur a accepté.
  /// Sinon, affiche un Toast d'erreur.
  Future<void> _verifyFormAndAcceptCgu(
      BuildContext context, AuthTemplateThemeData themeData) async {
    timer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();

    /// Vérifie que le formulaire est valide
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        loading = false;
      });
      return;
    }

    /// Check que l'email est disponible
    final isEmailAvailable = await KosmosAuth.emailDoesExist(
      email!,
      region: config?.cloudRegion ?? "us-central1",
    );
    bool canContinue = isEmailAvailable.fold<bool>((l) {
      if (mounted) {
        PopupAlert.toast(context, FToast().init(context),
            subtitle: l, title: "utils.error".tr());
      }

      return false;
    }, (r) {
      if (r) {
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: "package.kosmos-auth.email-already-in-use".tr(),
              title: "utils.error".tr());
        }

        return false;
      }

      return true;
    });
    if (!canContinue) {
      /// Clean les champs de mot de passe
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        loading = false;
      });
      return;
    }

    if (config?.authentificationConfig.canLoginWithPhone ?? false) {
      /// Check que le numéro de téléphone est disponible
      final isPhoneAvailable = await KosmosAuth.phoneDoesExist(
        phoneNumber!.phoneNumber!,
        region: config?.cloudRegion ?? "us-central1",
      );
      canContinue = isPhoneAvailable.fold<bool>((l) {
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: l, title: "utils.error".tr());
        }

        return false;
      }, (r) {
        if (r) {
          if (mounted) {
            PopupAlert.toast(context, FToast().init(context),
                subtitle: "package.kosmos-auth.phone-already-in-use".tr(),
                title: "utils.error".tr());
          }

          return false;
        }

        return true;
      });
      if (!canContinue) {
        /// Clean les champs de mot de passe
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          loading = false;
        });
        return;
      }
    }

    /// Clean les champs de mot de passe
    // _passwordController.clear();
    // _confirmPasswordController.clear();

    /// Affiche la modal bottom sheet pour accepter les conditions d'utilisation
    final bool? isAccepted = await _showCguBottomSheet(context, themeData);

    if (!(isAccepted ?? false)) {
      if (mounted) {
        PopupAlert.toast(context, FToast().init(context),
            subtitle: "package.kosmos-auth.must-accept-cgu".tr(),
            title: "utils.error".tr());
      }
      setState(() {
        loading = false;
      });
      return;
    }

    /// Si la connexion par téléphone est activée,
    /// On vérifie l'authenticité et la validité du numéro de téléphone
    /// via le systeme OTP.
    /// Envoi le code par sms et passe à la page suivante
    if (config?.authentificationConfig.canLoginWithPhone ?? false) {
      await KosmosAuth.verifPhoneNumberAndGetCredential(
        phone: phoneNumber!.phoneNumber!,
        connexionDone: (user) async {
          dz.Either<String, UserCredential?> rep =
              await KosmosAuth.linkEmailAuthProviderWithCurrentUser(
                  user: user, email: email!, password: password!);
          await afterPhoneVerif(rep);
        },
        verificationError: (_) {
          printExcept(_);
          if (mounted) {
            PopupAlert.toast(context, FToast().init(context),
                subtitle: FirebaseErrorHandler.getErrorMessage(_),
                title: "utils.error".tr());
            setState(() {
              loading = false;
            });
          }
        },
        verificationFailed: (_) {
          printError(_);
          if (mounted) {
            PopupAlert.toast(context, FToast().init(context),
                subtitle: FirebaseErrorHandler.getErrorMessage(_),
                title: "utils.error".tr());
            setState(() {
              loading = false;
            });
          }
        },
        codeSent: (String code, int? id) async {
          _codeId = code;
          timer?.cancel();
          validationTimeCode = const Duration(seconds: 120);
          timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (validationTimeCode != null && mounted) {
              setState(() {
                validationTimeCode =
                    validationTimeCode! - const Duration(seconds: 1);
              });
              if (validationTimeCode!.inSeconds == 0) {
                timer.cancel();
              }
            }
          });

          _pageController.jumpToPage(1);
          setState(() {
            loading = false;
          });
        },
        redirectAfterTimeOut: (_) {},
        setLoading: () {},
      );
    } else {
      final rep = await KosmosAuth.signUpWithEmail(email!, password!);
      final canContinue = rep.fold<bool>((l) {
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: l, title: "utils.error".tr());
        }

        return false;
      }, (r) {
        return true;
      });

      if (!canContinue) {
        setState(() {
          loading = false;
        });
        return;
      }

      await UserController.createNewUserDocument(
          FirebaseAuth.instance.currentUser!.uid,
          email!,
          phoneNumber?.phoneNumber,
          phoneNumber,
          "users",
          config?.authentificationConfig.getUserType != null
              ? (await config!.authentificationConfig.getUserType!(context))
              : config?.authentificationConfig.userType);
      await _sendEmailValidation(context);

      if (config != null && config!.mainRouteInfo != null) {
        if (mounted) {
          setState(() {
            loading = false;
          });
          AutoRouter.of(context)
              .pushAndPopUntil(config!.mainRouteInfo!, predicate: (_) => false);
        }
      } else {
        if (mounted) {
          setState(() {
            loading = false;
          });
          AutoRouter.of(context).popUntilRoot();
          AutoRouter.of(context).replaceNamed("/");
        }
      }
    }
  }

  /// Vérifie la validité du code et passe à la page suivante
  /// si le code est valide.
  Future<void> _verifyPhoneNumberAndLogin(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      if (code == null) {
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: "package.kosmos-auth.code-is-required".tr(),
              title: "utils.error".tr());
        }
        return;
      }

      if ((validationTimeCode ?? Duration.zero) <= Duration.zero) {
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: "package.kosmos-auth.code-is-expired".tr(),
              title: "utils.error".tr());
        }
        return;
      }

      final rep = await KosmosAuth.signUpWithPhone(
          codeId: _codeId!, code: code!, email: email!, password: password!);
      await afterPhoneVerif(rep);
    } catch (e) {
      PopupAlert.toast(context, FToast().init(context),
          subtitle: e.toString(), title: "utils.error".tr());

      printExcept(e);
    }
  }

  Future<void> afterPhoneVerif(dz.Either<String, UserCredential?> rep) async {
    final canContinue = rep.fold<bool>((l) {
      if (mounted) {
        PopupAlert.toast(context, FToast().init(context),
            subtitle: l, title: "utils.error".tr());
      }
      return false;
    }, (r) {
      LocalAuthController.rememberCredentials(email!, password!);
      return true;
    });

    if (!canContinue) return;
    if (!canContinue) return;

    await UserController.createNewUserDocument(
        FirebaseAuth.instance.currentUser!.uid,
        email!,
        phoneNumber?.phoneNumber,
        phoneNumber,
        "users",
        config?.authentificationConfig.getUserType != null
            ? (await config!.authentificationConfig.getUserType!(context))
            : config?.authentificationConfig.userType);

    await _sendEmailValidation(context);
    ref.read(userProvider).init(context);
    AnalyticsAuthController.signUp();

    if (config?.authentificationConfig.loginSuccess != null && mounted) {
      config!.authentificationConfig.loginSuccess!(context);
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

  /////////////
  //// UI /////
  /////////////

  Widget _formView(BuildContext context, AuthTemplateThemeData themeData) {
    late final buttonThemeData = loadThemeData<KosmosButtonThemeData>(
      null,
      "button_primary",
      () => const KosmosButtonThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          config?.authentificationConfig.registerPageTitleBuilder
                  ?.call(context, ref) ??
              Padding(
                padding: themeData.titlePadding ??
                    EdgeInsets.symmetric(horizontal: formatWidth(29)),
                child: Center(
                  child: Text(
                    "package.skeleton.auth.create-account-title".tr(),
                    textAlign: TextAlign.center,
                    style: themeData.titleStyle ?? DefaultAppStyle.darkBlue(23),
                  ),
                ),
              ),
          SizedBox(height: themeData.titleAndFormSpacing ?? formatHeight(44)),
          Padding(
            padding: themeData.formPadding ??
                EdgeInsets.symmetric(horizontal: formatWidth(29)),
            child: FormClassicField(
              isRequired:
                  config?.authentificationConfig.showRequiredAsterixAuth ??
                      true,
              fieldName: "package.field.auth.email.title".tr(),
              hintText: "package.field.auth.email.hint".tr(),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              focusNode: emailFocusNode,
              nextNode: passwordFocusNode,
              validator: (value) {
                final rep =
                    AuthValidator.validEmail(value?.toLowerCase().trim());
                if (rep != null) {
                  setState(() => _isEmailError = true);
                } else {
                  setState(() => _isEmailError = false);
                }
                return rep;
              },
              isError: _isEmailError,
              showErrorTitle: false,
              onChanged: (val) => email = val.toLowerCase().trim(),
            ),
          ),
          sh(14),
          Padding(
            padding: themeData.formPadding ??
                EdgeInsets.symmetric(horizontal: formatWidth(29)),
            child: FormClassicField(
              isRequired:
                  config?.authentificationConfig.showRequiredAsterixAuth ??
                      true,
              fieldName: "package.field.auth.password.title".tr(),
              hintText: "package.field.auth.password.hint".tr(),
              controller: _passwordController,
              focusNode: passwordFocusNode,
              nextNode: confirmPasswordFocusNode,
              textInputAction: TextInputAction.next,
              isSecretField: true,
              validator: (value) {
                final rep =
                    AuthValidator.validPassword(value, passwordSecurityConfig);
                if (rep != null) {
                  _passwordStrength = AuthValidator.passwordStrength(value);
                  setState(() => _isPasswordError = true);
                } else {
                  setState(() => _isPasswordError = false);
                }
                return rep;
              },
              onChanged: (val) => password = val,
            ),
          ),
          if (_isPasswordError && _passwordStrength != null) ...[
            sh(8),
            Container(
              padding: EdgeInsets.only(
                  top: formatHeight(11),
                  bottom: formatHeight(17),
                  left: formatWidth(21),
                  right: formatWidth(21)),
              margin: themeData.formPadding ??
                  EdgeInsets.symmetric(horizontal: formatWidth(29)),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(r(7)),
                  boxShadow: [
                    BoxShadow(
                      color: DefaultColor.error.withValues(alpha: .21),
                      offset: const Offset(0, 3),
                      blurRadius: 30,
                      spreadRadius: -5,
                    ),
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (passwordSecurityConfig?.atLeast6Char ?? true)
                    _buildItemValid(
                        context,
                        themeData,
                        "package.kosmos-auth.password-security-length".tr(),
                        _passwordStrength!.isValidLength),
                  if (passwordSecurityConfig?.atLeast1Uppercase ?? true)
                    _buildItemValid(
                        context,
                        themeData,
                        "package.kosmos-auth.password-security-min".tr(),
                        _passwordStrength!.hasLowercase),
                  if (passwordSecurityConfig?.atLeast1Lowercase ?? true)
                    _buildItemValid(
                        context,
                        themeData,
                        "package.kosmos-auth.password-security-maj".tr(),
                        _passwordStrength!.hasUppercase),
                  if (passwordSecurityConfig?.atLeast1Number ?? true)
                    _buildItemValid(
                        context,
                        themeData,
                        "package.kosmos-auth.password-security-number".tr(),
                        _passwordStrength!.hasDigits),
                  if (passwordSecurityConfig?.atLeast1SpecialChar ?? true)
                    _buildItemValid(
                        context,
                        themeData,
                        "package.kosmos-auth.password-security-special".tr(),
                        _passwordStrength!.hasSpecialCharacters),
                ],
              ),
            )
          ],
          sh(14),
          Padding(
            padding: themeData.formPadding ??
                EdgeInsets.symmetric(horizontal: formatWidth(29)),
            child: FormClassicField(
              isRequired:
                  config?.authentificationConfig.showRequiredAsterixAuth ??
                      true,
              fieldName: "package.field.auth.repeat-password.title".tr(),
              hintText: "package.field.auth.repeat-password.hint".tr(),
              focusNode: confirmPasswordFocusNode,
              nextNode: phoneNumberFocusNode,
              controller: _confirmPasswordController,
              textInputAction: TextInputAction.next,
              isSecretField: true,
              validator: (val) =>
                  AuthValidator.validSamePassword(password, val),
              onChanged: (val) => confirmPassword = val,
            ),
          ),
          if (config?.authentificationConfig.canLoginWithPhone ?? false) ...[
            sh(14),
            Padding(
              padding: themeData.formPadding ??
                  EdgeInsets.symmetric(horizontal: formatWidth(29)),
              child: FormPhoneNumberField(
                isRequired:
                    config?.authentificationConfig.showRequiredAsterixAuth ??
                        true,
                phoneKey: config?.authentificationConfig.phoneKey ?? "FR",
                locale: context.locale.languageCode,
                focusNode: phoneNumberFocusNode,
                fieldName: "package.field.auth.phone.title".tr(),
                hintText: "package.field.auth.phone.hint".tr(),
                onChanged: (val) => phoneNumber = val,
                autoValidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
          ],
          sh(30),
          Padding(
            padding: themeData.formPadding ??
                EdgeInsets.symmetric(horizontal: formatWidth(29)),
            child:
                config?.authentificationConfig.createAccountButtonCustom?.call(
                      context,
                      ref,
                      () async {
                        setState(() {
                          loading = true;
                        });
                        await _verifyFormAndAcceptCgu(context, themeData);
                        //TPOD
                      },
                    ) ??
                    Button(
                      text: config?.authentificationConfig
                                  .createAccountButtonTitleBuilder ==
                              null
                          ? "utils.continue".tr()
                          : null,
                      isLoading: loading,
                      height: buttonThemeData.height,
                      enabled: !loading,
                      showLoader: true,
                      onTap: () async {
                        setState(() {
                          loading = true;
                        });
                        await _verifyFormAndAcceptCgu(context, themeData);
                        //TPOD
                      },
                      child: config?.authentificationConfig
                          .createAccountButtonTitleBuilder
                          ?.call(context, ref),
                    ),
          ),
          if (config?.authentificationConfig.authTiers.isNotEmpty ?? false) ...[
            sh(35),
            Padding(
              padding: themeData.formPadding ??
                  EdgeInsets.symmetric(horizontal: formatWidth(29)),
              child: Center(
                child: Text(
                  "package.skeleton.auth.or-signup-with".tr(),
                  style: themeData.subtitleStyle ??
                      DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            sh(28),
            Padding(
              padding: themeData.formPadding ??
                  EdgeInsets.symmetric(horizontal: formatWidth(29)),
              child: LayoutBuilder(
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
                              maxWidth: themeData.authTiersExtended
                                  ? (c.maxWidth / length) -
                                      (formatWidth(18) * (length - 1))
                                  : formatWidth(102),
                            ),
                            child: AuthTiersButton(
                              onTap: () async {
                                final rep = await {
                                  AuthTiers.apple: () async =>
                                      await TiersAuthController.signInWithTiers(
                                          context, ref, AuthTiers.apple),
                                  AuthTiers.google: () async =>
                                      await TiersAuthController.signInWithTiers(
                                          context, ref, AuthTiers.google),
                                  AuthTiers.facebook: () async =>
                                      await TiersAuthController.signInWithTiers(
                                          context, ref, AuthTiers.facebook),
                                }[e]!
                                    .call();

                                if (!rep) return;

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
                                      (formatWidth(18) * (length - 1))
                                  : formatWidth(102),
                              height:
                                  themeData.authTiersHeight ?? formatHeight(54),
                              padding: themeData.authTiersPadding ?? ph(10),
                              child: SvgPicture.asset(
                                svgPath,
                                color: ref.watch(isDarkModeProvider).isDarkMode
                                    ? Colors.white
                                    : null,
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _confirmCodeView(
      BuildContext context, AuthTemplateThemeData themeData) {
    late final buttonThemeData = loadThemeData<KosmosButtonThemeData>(
      null,
      "button_primary",
      () => const KosmosButtonThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Padding(
      padding: themeData.formPadding ??
          EdgeInsets.symmetric(horizontal: formatWidth(29)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          config?.authentificationConfig
                  .registerPhoneConfirmationPageTitleBuilder
                  ?.call(context, ref) ??
              Padding(
                padding: themeData.titlePadding ??
                    EdgeInsets.symmetric(horizontal: formatWidth(29)),
                child: Center(
                  child: Text(
                    "package.skeleton.auth.verify-phone-code-title".tr(),
                    textAlign: TextAlign.center,
                    style: themeData.titleStyle ?? DefaultAppStyle.darkBlue(23),
                  ),
                ),
              ),
          SizedBox(
              height: themeData.titleAndSubtitleSpacing ?? formatHeight(15)),
          if (validationTimeCode != null)
            Align(
              alignment: themeData.subtitleAlignment ?? Alignment.center,
              child: Text(
                "package.skeleton.auth.code-expire-in".tr(
                  namedArgs: {
                    "time":
                        "${(validationTimeCode!.inMinutes).toString().padLeft(2, "0")}:${(validationTimeCode!.inSeconds - ((validationTimeCode!.inMinutes * 60))).toString().padLeft(2, "0")}"
                  },
                ),
                style: themeData.subtitleStyle ??
                    DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
              height: themeData.subtitleAndFormSpacing ?? formatHeight(60)),
          FormPinCodeField(
            pinTheme: themeData.pinTheme,
            themeName: themeData.pinCodeFieldThemeName,
            fieldName: "package.field.auth.code.title".tr(),
            onChanged: (val) => code = val,
            validator: (val) {
              if (val?.length != 6) {
                return "package.kosmos-auth.code-invalid".tr();
              }
              return null;
            },
          ),
          sh(17),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "${"package.skeleton.auth.no-code".tr()} ",
                    style: themeData.linkDescriptionStyle ??
                        DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                  ),
                  TextSpan(
                    text: "package.skeleton.auth.resend-code".tr(),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await KosmosAuth.verifPhoneNumberAndGetCredential(
                          phone: phoneNumber!.phoneNumber!,
                          connexionDone: (user) async {
                            dz.Either<String, UserCredential?> rep =
                                await KosmosAuth
                                    .linkEmailAuthProviderWithCurrentUser(
                                        user: user,
                                        email: email!,
                                        password: password!);
                            await afterPhoneVerif(rep);
                          },
                          codeSent: (String code, int? id) {
                            PopupAlert.toast(context, FToast().init(context),
                                subtitle: "package.kosmos-auth.code-sent".tr(),
                                title: "utils.success".tr(),
                                type: AlertType.success);
                            _codeId = code;
                            timer?.cancel();
                            validationTimeCode = const Duration(seconds: 120);
                            timer = Timer.periodic(const Duration(seconds: 1),
                                (timer) {
                              if (validationTimeCode != null && mounted) {
                                setState(() {
                                  validationTimeCode = validationTimeCode! -
                                      const Duration(seconds: 1);
                                });
                                if (validationTimeCode!.inSeconds == 0) {
                                  timer.cancel();
                                }
                              }
                            });
                          },
                          verificationError: (_) {
                            printExcept(_);
                            if (mounted) {
                              PopupAlert.toast(context, FToast().init(context),
                                  subtitle:
                                      FirebaseErrorHandler.getErrorMessage(_),
                                  title: "utils.error".tr());
                            }
                          },
                          verificationFailed: (_) {
                            printError(_);
                            if (mounted) {
                              PopupAlert.toast(context, FToast().init(context),
                                  subtitle:
                                      FirebaseErrorHandler.getErrorMessage(_),
                                  title: "utils.error".tr());
                            }
                          },
                          redirectAfterTimeOut: () {},
                          setLoading: () {},
                        );
                      },
                    style: themeData.linkStyle ??
                        DefaultAppStyle.darkBlue(13, FontWeight.w500)
                            .copyWith(decoration: TextDecoration.underline),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          sh(30),
          config?.authentificationConfig.validateOTPCreateAccountButtonCustom
                  ?.call(
                context,
                ref,
                () async => _verifyPhoneNumberAndLogin(context),
              ) ??
              Button(
                text: config?.authentificationConfig
                            .validateOTPCreateAccountButtonTitleBuilder ==
                        null
                    ? "utils.validate-and-continue".tr()
                    : null,
                height: buttonThemeData.height,
                onTap: () async => _verifyPhoneNumberAndLogin(context),
                child: config?.authentificationConfig
                    .validateOTPCreateAccountButtonTitleBuilder
                    ?.call(context, ref),
              ),
          SizedBox(
              height: MediaQuery.of(context).padding.top + formatHeight(12)),
        ],
      ),
    );
  }

  Widget _buildItemValid(BuildContext context, AuthTemplateThemeData themeData,
      String tr, bool valid) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(valid ? Icons.check_rounded : Icons.close_rounded,
            color: valid ? DefaultColor.success : DefaultColor.error,
            size: formatHeight(20)),
        sw(5.6),
        Expanded(
            child: Text(tr,
                style: themeData.subtitleStyle ??
                    DefaultAppStyle.simpleGrey(13, FontWeight.w500))),
      ],
    );
  }

  Future<bool?> _showCguBottomSheet(
    BuildContext context,
    AuthTemplateThemeData themeData,
  ) async {
    final ScrollController scrollController = ScrollController();
    final future = AppMetadataController.getMetadataConfig();
    bool cgvuAccepted = false;

    late final buttonThemeData = loadThemeData<KosmosButtonThemeData>(
      null,
      "button_primary",
      () => const KosmosButtonThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeData.popupBackgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      shape: themeData.modalBottomSheetShapeBorder ??
          RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r(55)))),
      builder: (ctx) {
        return SizedBox(
          height: formatHeight(600),
          child: StatefulBuilder(builder: (_, newState) {
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
                          color:
                              themeData.dividerColor ?? DefaultColor.lightGrey,
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
                  Flexible(
                    child: FutureBuilder<AppMetadataConfig?>(
                      future: future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final cgvu = snapshot.data?.cgvu;
                        return Scrollbar(
                          controller: scrollController,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              children: [
                                HtmlWidget(
                                  cgvu ?? "",
                                  textStyle: themeData.htmlTextStyle,
                                ),
                                if (config?.cgvuAllScrolable ?? false) ...[
                                  Selector(
                                    type: CheckboxType.square,
                                    sideText:
                                        "utils.accept-cgvu-and-confidentiality"
                                            .tr(),
                                    onChanged: (val) {
                                      newState(
                                          () => cgvuAccepted = !cgvuAccepted);
                                    },
                                    isChecked: cgvuAccepted,
                                  ),
                                  sh(33),
                                  Center(
                                    child: config?.authentificationConfig
                                            .cgvuButtonCustom
                                            ?.call(
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
                                          width: formatWidth(config
                                                  ?.authentificationConfig
                                                  .cgvuButtonWidth ??
                                              170),
                                          enabled: cgvuAccepted,
                                          onTap: () {
                                            Navigator.pop(context, true);
                                          },
                                          child: config?.authentificationConfig
                                              .cgvuButtonTitleBuilder
                                              ?.call(context, ref),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  sh(16),
                  if (!(config?.cgvuAllScrolable ?? false)) ...[
                    Selector(
                      type: CheckboxType.square,
                      sideText: "utils.accept-cgvu-and-confidentiality".tr(),
                      onChanged: (val) {
                        newState(() => cgvuAccepted = !cgvuAccepted);
                      },
                      isChecked: cgvuAccepted,
                    ),
                    sh(33),
                    Center(
                      child:
                          config?.authentificationConfig.cgvuButtonCustom?.call(
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
                                width: formatWidth(config
                                        ?.authentificationConfig
                                        .cgvuButtonWidth ??
                                    170),
                                enabled: cgvuAccepted,
                                onTap: () {
                                  Navigator.pop(context, true);
                                },
                                child: config?.authentificationConfig
                                    .cgvuButtonTitleBuilder
                                    ?.call(context, ref),
                              ),
                    ),
                  ],
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom +
                          formatHeight(12)),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Future<void> _sendEmailValidation(BuildContext context) async {
    late final buttonThemeData = loadThemeData<KosmosButtonThemeData>(
      null,
      "button_primary",
      () => const KosmosButtonThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    if (!(config?.authentificationConfig.sendVerificationEmail ?? false)) {
      return;
    }

    final themeData = loadThemeData(
      null,
      "dialog_alert",
      () => const AlertTheme(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    KosmosAuth.sendEmailVerification(
      FirebaseAuth.instance.currentUser!.uid,
      region: config?.cloudRegion ?? "us-central1",
    );
    await PopupAlert.dialogBox(
      context,
      title: "package.skeleton.auth.create-account-verify-email".tr(),
      subtitle: "package.skeleton.auth.create-account-verify-email-subtitle".tr(
        args: [
          FirebaseAuth.instance.currentUser!.email ?? "",
        ],
      ),
      actionsBuilder: [
        (_) => Center(
              child:
                  config?.authentificationConfig.verifyEmailButtonCustom?.call(
                        _,
                        ref,
                        () => Navigator.of(_).pop(),
                      ) ??
                      Button(
                        text: config?.authentificationConfig
                                    .verifyEmailButtonBuilder ==
                                null
                            ? "utils.close".tr()
                            : null,
                        buttonType: ButtonType.primary,
                        width: themeData?.buttonWidth ?? formatWidth(140),
                        height: buttonThemeData.height,
                        onTap: () => Navigator.of(_).pop(),
                        child: config
                            ?.authentificationConfig.verifyEmailButtonBuilder
                            ?.call(context, ref),
                      ),
            ),
      ],
    );
  }
}
