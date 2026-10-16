import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kosmos_auth/controller/auth.dart';
import 'package:kosmos_auth/utils/error_handler.dart';
import 'package:skeleton/controller/tiers_auth_controller.dart';
import 'package:skeleton/skeleton.dart';
import 'package:skeleton/view/widget/parent/auth_parent.dart';

class PhoneLoginPage extends StatefulHookConsumerWidget {
  const PhoneLoginPage({super.key});

  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage> {
  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

  final PageController _pageController = PageController();
  PhoneNumber? _phoneNumber;
  String? validCode;
  Duration? validationTimeCode;
  Timer? timer;
  String? code;
  bool loading = false;
  int currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
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
        null, "button_primary", () => const KosmosButtonThemeData(),
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    return Scaffold(
      body: AuthParent(
        backgroundPage: currentPage == 0
            ? themeData.phoneLoginPageBackground?.call(context, ref)
            : themeData.pinLoginVerficationLoginPageBackground
                ?.call(context, ref),
        logoSize: themeData.logoSize,
        onBack: (context) {
          if (!_pageController.hasClients) {
            printInfo("Go back");
            AutoRouter.of(context).navigateBack();
            return;
          }
          if (_pageController.page == 1) {
            _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.linear);
          } else {
            AutoRouter.of(context).navigateBack();
          }
        },
        child: getResponsiveValue(
          context,
          defaultValue: _buildWeb(context, themeData, buttonThemeData),
          phone: _buildPhone(context, themeData, buttonThemeData),
        ),
      ),
    );
  }

  Widget _buildPhone(BuildContext context, AuthTemplateThemeData themeData,
      KosmosButtonThemeData buttonThemeData) {
    return Padding(
      padding: themeData.formPadding ??
          EdgeInsets.symmetric(horizontal: formatWidth(29)),
      child: ExpandablePageView(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            currentPage = page;
          });
        },
        clipBehavior: Clip.none,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _phoneNumberPage(context, themeData, buttonThemeData),
          _phoneValidationPage(context, themeData, buttonThemeData)
        ],
      ),
    );
  }

  Widget _buildWeb(BuildContext context, AuthTemplateThemeData themeData,
      KosmosButtonThemeData buttonThemeData) {
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
                  onTap: () {
                    if (!_pageController.hasClients) {
                      printInfo("Go back");
                      AutoRouter.of(context).navigateBack();
                      return;
                    }
                    if (_pageController.page == 1) {
                      _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear);
                    } else {
                      AutoRouter.of(context).navigateBack();
                    }
                  },
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(27.5))),
            sh(20),
          ],
          _buildPhone(context, themeData, buttonThemeData),
        ],
      ),
    );
  }

  Widget _phoneNumberPage(BuildContext context, AuthTemplateThemeData themeData,
      KosmosButtonThemeData buttonThemeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        config?.authentificationConfig.phonePageTitleBuilder
                ?.call(context, ref) ??
            Padding(
              padding: themeData.titlePadding ?? EdgeInsets.zero,
              child: Center(
                child: Text(
                  "package.skeleton.auth.login-phone-title".tr(),
                  textAlign: TextAlign.center,
                  style: themeData.titleStyle ?? DefaultAppStyle.darkBlue(23),
                ),
              ),
            ),
        SizedBox(height: themeData.titleAndFormSpacing ?? formatHeight(44)),
        FormPhoneNumberField(
          phoneKey: config?.authentificationConfig.phoneKey ?? 'FR',
          locale: context.locale.languageCode,
          fieldName: "package.field.auth.phone.title".tr(),
          hintText: "package.field.auth.phone.hint".tr(),
          fieldAction:
              (config?.authentificationConfig.canLoginWithPhone ?? false)
                  ? "package.skeleton.auth.login-with-email".tr()
                  : null,
          fieldActionOnTap: () {
            if ((config?.authentificationConfig.canLoginWithPhone ?? false)) {
              AutoRouter.of(context).navigateNamed(
                  // config?.authentificationConfig.loginDefaultRoute ??
                  "/auth/login");
            }
          },
          onChanged: (val) => _phoneNumber = val,
          autoValidateMode: AutovalidateMode.onUserInteraction,
        ),
        sh(42),
        config?.authentificationConfig.phoneLoginButtonCustom?.call(
              context,
              ref,
              () async => await _loginWithPhone(context),
            ) ??
            Button(
              enabled: !loading,
              isLoading: loading,
              text:
                  config?.authentificationConfig.phoneLoginButtonBuilder == null
                      ? "utils.continue".tr()
                      : null,
              height: buttonThemeData.height,
              onTap: () async => await _loginWithPhone(context),
              child: config?.authentificationConfig.phoneLoginButtonBuilder
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
          sh(28),
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
                          height: themeData.authTiersHeight ?? formatHeight(54),
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
                      ..onTap = () => AutoRouter.of(context).navigateNamed(
                          config?.authentificationConfig.createAccountRoute ??
                              "/auth/create-account"),
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
                    style: themeData.subtitleStyle ??
                        DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                  ),
                  TextSpan(
                    text: "package.skeleton.auth.not-connected-redirect".tr(),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => AutoRouter.of(context).pushAndPopUntil(
                            config!.authentificationConfig.notLoggedRoute ??
                                config!.mainRouteInfo ??
                                const PageRouteInfo("DefaultRoute", path: "/"),
                            predicate: (_) => false,
                          ),
                    style: themeData.subtitleStyle ??
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
    );
  }

  Widget _phoneValidationPage(BuildContext context,
      AuthTemplateThemeData themeData, KosmosButtonThemeData buttonThemeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        config?.authentificationConfig.signinPhoneConfirmationPageTitleBuilder
                ?.call(context, ref) ??
            Padding(
              padding: themeData.titlePadding ?? EdgeInsets.zero,
              child: Center(
                child: Text(
                  "package.skeleton.auth.verify-phone-title".tr(),
                  textAlign: TextAlign.center,
                  style: themeData.titleStyle ?? DefaultAppStyle.darkBlue(23),
                ),
              ),
            ),
        SizedBox(height: themeData.titleAndSubtitleSpacing ?? formatHeight(14)),
        if (validationTimeCode != null)
          Align(
            alignment: themeData.subtitleAlignment ?? Alignment.center,
            child: Text(
              "package.skeleton.auth.code-expire-in".tr(namedArgs: {
                "time":
                    "${(validationTimeCode!.inMinutes).toString().padLeft(2, "0")}:${(validationTimeCode!.inSeconds - ((validationTimeCode!.inMinutes * 60))).toString().padLeft(2, "0")}"
              }),
              style: themeData.subtitleStyle ??
                  DefaultAppStyle.simpleGrey(13, FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        SizedBox(
            height: themeData.subtitleAndFormSpacing ??
                themeData.titleAndFormSpacing ??
                formatHeight(44)),
        FormPinCodeField(
          pinTheme: themeData.pinTheme,
          themeName: themeData.pinCodeFieldThemeName,
          fieldName: "package.field.auth.code.title".tr(),
          onChanged: (val) => code = val,
          validator: (val) {
            if (val?.length != 6) return "package.validator.code-invalid".tr();
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
                    ..onTap = () async => await _resendSmsCode(),
                  style: themeData.linkStyle ??
                      DefaultAppStyle.darkBlue(13, FontWeight.w500)
                          .copyWith(decoration: TextDecoration.underline),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        sh(40),
        config?.authentificationConfig.otpValidationButtonCustom?.call(
              context,
              ref,
              () async => _tryLogin(context),
            ) ??
            Button(
              text: config?.authentificationConfig
                          .otpValidationButtonTitleBuilder ==
                      null
                  ? "utils.connexion".tr()
                  : null,
              height: buttonThemeData.height,
              onTap: () async => _tryLogin(context),
              child: config
                  ?.authentificationConfig.otpValidationButtonTitleBuilder
                  ?.call(context, ref),
            ),
        SizedBox(
            height: MediaQuery.of(context).padding.bottom + formatHeight(3)),
      ],
    );
  }

  Future<void> _loginWithPhone(BuildContext context) async {
    setState(() {
      loading = true;
    });
    if (_phoneNumber?.phoneNumber == null ||
        _phoneNumber!.phoneNumber!.isEmpty) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: "package.kosmos-auth.error-phone-not-exist".tr());

      setState(() {
        loading = false;
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final phoneDoesExist = await KosmosAuth.phoneDoesExist(
      _phoneNumber!.phoneNumber!,
      region: config?.cloudRegion ?? "us-central1",
    );
    bool canContinue = phoneDoesExist.fold((l) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(), subtitle: l);

      return false;
    }, (r) {
      if (!r) {
        PopupAlert.toast(context, FToast().init(context),
            title: "utils.error".tr(),
            subtitle: "package.kosmos-auth.error-phone-not-exist".tr());
        return false;
      }
      return true;
    });

    if (!canContinue) {
      setState(() {
        loading = false;
      });
      return;
    }

    final phone = _phoneNumber!.phoneNumber!;
    await KosmosAuth.verifPhoneNumberAndGetCredential(
      phone: phone,
      codeAutoRetrievalTimeout: (String code) {},
      connexionDone: (_) {
        afterCodeSended();
        setState(() {
          loading = false;
        });
      },
      codeSent: (String code, int? __) {
        validCode = code;
        validationTimeCode = const Duration(seconds: 120);
        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (validationTimeCode != null) {
            if (mounted)
              setState(() => validationTimeCode =
                  validationTimeCode! - const Duration(seconds: 1));
            if (validationTimeCode!.inSeconds == 0) timer.cancel();
          }
        });
        setState(() {
          loading = false;
        });
        _pageController.jumpToPage(1);
      },
      redirectAfterTimeOut: () {},
      setLoading: () {},
      verificationError: (_) {
        setState(() {
          loading = false;
        });
        printExcept(_);
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: FirebaseErrorHandler.getErrorMessage(_),
              title: "utils.error".tr());
        }
      },
      verificationFailed: (_) {
        setState(() {
          loading = false;
        });
        printError(_);
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: FirebaseErrorHandler.getErrorMessage(_),
              title: "utils.error".tr());
        }
      },
    );
  }

  Future<void> _resendSmsCode() async {
    await KosmosAuth.verifPhoneNumberAndGetCredential(
      phone: _phoneNumber!.phoneNumber!,
      connexionDone: (_) {
        afterCodeSended();
      },
      codeSent: (String code, int? __) {
        PopupAlert.toast(context, FToast().init(context),
            subtitle: "package.kosmos-auth.code-sent".tr(),
            title: "utils.success".tr(),
            type: AlertType.success);
        validCode = code;
        validationTimeCode = const Duration(seconds: 120);
        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (validationTimeCode != null) {
            if (mounted)
              setState(() => validationTimeCode =
                  validationTimeCode! - const Duration(seconds: 1));
            if (validationTimeCode!.inSeconds == 0) timer.cancel();
          }
        });
      },
      redirectAfterTimeOut: () {},
      setLoading: () {},
      verificationError: (_) {
        printExcept(_);
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: FirebaseErrorHandler.getErrorMessage(_),
              title: "utils.error".tr());
        }
      },
      verificationFailed: (_) {
        printError(_);
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: FirebaseErrorHandler.getErrorMessage(_),
              title: "utils.error".tr());
        }
      },
    );
  }

  Future<void> _tryLogin(BuildContext context) async {
    if (code == null || validCode == null) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: "package.kosmos-auth.code-invalid".tr());
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

    final rep =
        await KosmosAuth.signInWithPhone(codeId: validCode!, code: code!);
    final canContinue = rep.fold<bool>((l) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(), subtitle: l);
      return false;
    }, (r) {
      return true;
    });
    if (!canContinue) return;

    afterCodeSended();
  }

  Future<void> afterCodeSended() async {
    if (mounted &&
        (await config?.authentificationConfig.loginSuccess?.call(context) ??
            false)) return;

    if (!FirebaseAuth.instance.currentUser!.emailVerified &&
        (config?.authentificationConfig.emailMustBeVerified ?? false)) {
      if (mounted) {
        PopupAlert.toast(context, FToast().init(context),
            title: "utils.error".tr(),
            subtitle: "package.kosmos-auth.email-must-be-verified".tr());
      }
      await FirebaseAuth.instance.signOut();
      _pageController.jumpToPage(0);
      return;
    }

    if (mounted) {
      ref.read(userProvider).init(context);
    }

    AnalyticsAuthController.login("phone");

    if (config?.authentificationConfig.loginSuccess != null && mounted) {
      config!.authentificationConfig.loginSuccess!(context);
    }

    if (config != null && config!.mainRouteInfo != null) {
      if (mounted)
        AutoRouter.of(context)
            .pushAndPopUntil(config!.mainRouteInfo!, predicate: (_) => false);
    } else {
      if (mounted) {
        AutoRouter.of(context).popUntilRoot();
        AutoRouter.of(context).replaceNamed("/");
      }
    }
  }
}
