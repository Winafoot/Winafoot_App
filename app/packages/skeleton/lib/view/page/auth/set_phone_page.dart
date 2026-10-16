// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kosmos_auth/controller/auth.dart';
import 'package:kosmos_auth/utils/error_handler.dart';
import 'package:skeleton/skeleton.dart';
import 'package:skeleton/controller/user_controller.dart';

class SetPhonePage extends StatefulHookConsumerWidget {
  const SetPhonePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SetPhonePageState();
}

class _SetPhonePageState extends ConsumerState<SetPhonePage> {
  final PageController _pageController = PageController();

  PhoneNumber? phoneNumber;
  PhoneNumber? initialPhoneNumber;

  final TextEditingController pinTextEditingController =
      TextEditingController();
  Timer? timer;
  String? codeMessage;
  Duration? validationTimeCode;
  String? _codeId, code;
  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

  @override
  void initState() {
    super.initState();
    initialPhoneNumber = ref.read(userProvider).user?.phoneNumber ??
        PhoneNumber(
            phoneNumber: ref.read(userProvider).user?.phone,
            isoCode: config?.authentificationConfig.phoneKey ?? "FR");
    phoneNumber = initialPhoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return getResponsiveValue<Widget>(context,
        defaultValue: _buildWeb(context), phone: _buildPhone(context));
  }

  Widget _buildPhone(BuildContext context) {
    final KosmosSettingsThemeData themeData = loadThemeData(
        null, "kosmos-settings", () => kDefaultSettingsTheme,
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    final _themeData = loadThemeData<AuthTemplateThemeData>(
        null, "authentication_theme", () => const AuthTemplateThemeData(),
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    return Scaffold(
      body: Stack(
        children: [
          if (_themeData.setPhonePageBackground != null)
            Positioned.fill(
                child: _themeData.setPhonePageBackground!(context, ref)),
          Positioned.fill(
            child: SingleChildScrollView(
              primary: true,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).padding.top +
                          formatHeight(12)),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ButtonBack(
                        onTap: () async {
                          await UserController.logoutUser(context, ref);
                        },
                        color: themeData.actionIconColor,
                        padding: EdgeInsets.symmetric(
                            horizontal: formatWidth(27.5),
                            vertical: formatHeight(8)),
                      ),
                      sw(12),
                      Expanded(
                          child: Center(
                              child: Text(
                                  "package.settings.node.phone-number.title"
                                      .tr(),
                                  style: themeData.sectionTitleStyle,
                                  textAlign: TextAlign.center))),
                      sw(12),
                      Opacity(
                        opacity: 0,
                        child: ButtonBack(
                          onTap: () {},
                          padding: EdgeInsets.symmetric(
                              horizontal: formatWidth(27.5),
                              vertical: formatHeight(8)),
                        ),
                      ),
                    ],
                  ),
                  sh(54),
                  ExpandablePageView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    children: [
                      _phoneNumberUi(context),
                      _validationCode(context, _themeData)
                    ],
                  ),
                  sh(20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Column();
  }

  Widget _phoneNumberUi(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: formatWidth(29)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormPhoneNumberField(
            locale: context.locale.languageCode,
            phoneKey: config?.authentificationConfig.phoneKey ?? 'FR',
            isRequired:
                config?.authentificationConfig.showRequiredAsterixAuth ?? true,
            fieldName: "package.field.auth.phone.title".tr(),
            hintText: "package.field.auth.phone.hint".tr(),
            initialValue: initialPhoneNumber,
            onChanged: (val) => setState(() {
              phoneNumber = val;
            }),
            autoValidateMode: AutovalidateMode.onUserInteraction,
          ),
          sh(37),
          config?.authentificationConfig.setPhoneButtonCustom?.call(
                context,
                ref,
                () async => await _verifyPhoneNumber(context),
              ) ??
              Button(
                text: "utils.validate".tr(),
                height: formatHeight(54),
                onTap: () async => await _verifyPhoneNumber(context),
              ),
        ],
      ),
    );
  }

  Widget _validationCode(
      BuildContext context, AuthTemplateThemeData themeData) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: formatWidth(29)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    style: themeData.subtitleStyle ??
                        DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                  ),
                  TextSpan(
                    text: "package.skeleton.auth.resend-code".tr(),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await KosmosAuth.verifPhoneNumberAndUpdate(
                          phone: phoneNumber!.phoneNumber!,
                          connexionDone: (user) {
                            _afterPhoneVerif();
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
                          verificationFailed: (e) {
                            PopupAlert.toast(context, FToast().init(context),
                                subtitle:
                                    FirebaseErrorHandler.getErrorMessage(e),
                                title: "utils.error".tr());
                          },
                          verificationError: (e) {
                            PopupAlert.toast(context, FToast().init(context),
                                subtitle:
                                    FirebaseErrorHandler.getErrorMessage(e),
                                title: "utils.error".tr());
                          },
                          redirectAfterTimeOut: () {},
                          setLoading: () {},
                        );
                      },
                    style: themeData.subtitleStyle ??
                        DefaultAppStyle.darkBlue(13, FontWeight.w500)
                            .copyWith(decoration: TextDecoration.underline),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          sh(37),
          config?.authentificationConfig.validateSetPhoneOtpButtonCustom?.call(
                context,
                ref,
                () async => await _validateCodeWithPhone(context),
              ) ??
              Button(
                text: "utils.validate-and-continue".tr(),
                height: formatHeight(54),
                onTap: () async => await _validateCodeWithPhone(context),
              ),
          sh(17),
          if (validationTimeCode != null)
            Center(
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
        ],
      ),
    );
  }

  _verifyPhoneNumber(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (phoneNumber == null) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: "package.kosmos-auth.enter-valid-phone".tr());
      return;
    }
    if (phoneNumber?.phoneNumber == ref.read(userProvider).user?.phone) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: "package.kosmos-auth.cant-be-same-phone".tr());
      return;
    }
    final isPhoneAvailable = await KosmosAuth.phoneDoesExist(
      phoneNumber!.phoneNumber!,
      region: config?.cloudRegion ?? "us-central1",
    );
    final canContinue = isPhoneAvailable.fold<bool>((l) {
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
      return;
    }

    await KosmosAuth.verifyPhoneNumberAndLinkToCurrentAccount(
      phone: phoneNumber!.phoneNumber!,
      connexionDone: (user) {
        _afterPhoneVerif();
      },
      codeSent: (String code, int? id) {
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
      },
      verificationError: (e) {
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: FirebaseErrorHandler.getErrorMessage(e),
              title: "utils.error".tr());
        }
      },
      verificationFailed: (e) {
        if (mounted) {
          PopupAlert.toast(context, FToast().init(context),
              subtitle: FirebaseErrorHandler.getErrorMessage(e),
              title: "utils.error".tr());
        }
      },
      redirectAfterTimeOut: (_) {},
      setLoading: () {},
    );
    _pageController.jumpToPage(1);
  }

  _validateCodeWithPhone(BuildContext context) async {
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

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _codeId!, smsCode: code!);
      final r = await KosmosAuth.updatePhoneNumber(credential);
      if (r != null) {
        PopupAlert.toast(context, FToast().init(context),
            subtitle: r, title: "utils.error".tr());
        _pageController.jumpToPage(0);
        return;
      }
      _afterPhoneVerif();
    } catch (e) {
      PopupAlert.toast(context, FToast().init(context),
          subtitle: "utils.error-default".tr(), title: "utils.error".tr());
      printExcept(e);
    }
  }

  Future<void> _afterPhoneVerif() async {
    PopupAlert.toast(context, FToast().init(context),
        subtitle: "package.kosmos-auth.phone-added-success".tr(),
        title: "utils.success".tr(),
        type: AlertType.success);

    await FirebaseFirestore.instance
        .collection("users")
        .doc(ref.read(userProvider).user!.id!)
        .update({
      "phone": phoneNumber!.phoneNumber!,
      "phoneNumber": {
        "phoneNumber": phoneNumber!.phoneNumber!,
        "isoCode": phoneNumber!.isoCode,
        "dialCode": phoneNumber!.dialCode,
      }
    });

    await Future.delayed(const Duration(seconds: 1));
    SkeletonAppConfig? skeletonConfig = GetIt.instance<AppModel>()
        .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");
    if (!mounted) return;

    if (skeletonConfig?.mainRouteInfo != null) {
      context.router.pushAndPopUntil(
        skeletonConfig!.mainRouteInfo!,
        predicate: (route) => false,
      );
    } else {
      context.router.replaceNamed("/");
    }
  }
}
