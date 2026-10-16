// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kosmos_auth/controller/auth.dart';
import 'package:skeleton/skeleton.dart';
import 'package:ui_kosmos_v4/alert/theme/alert_theme.dart';

class ChangeEmailPage extends StatefulHookConsumerWidget {
  const ChangeEmailPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ChangeEmailPageState();
}

class _ChangeEmailPageState extends ConsumerState<ChangeEmailPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  KosmosButtonThemeData? buttonThemeData;
  final settingsConfig = (getAppModel().dependencies.packages["kosmos-settings"]
          as KosmosSettingsConfig?) ??
      KosmosSettingsConfig();

  String? email;
  String? password;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: ref.read(userProvider).user?.email);
    email = _controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return getResponsiveValue<Widget>(context,
        defaultValue: _buildWeb(context), phone: _buildPhone(context));
  }

  Widget _buildPhone(BuildContext context) {
    final KosmosSettingsThemeData themeData = loadThemeData(
      null,
      "kosmos-settings",
      () => kDefaultSettingsTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    final buttonThemeData = themeData.settingsButtonThemeName == null
        ? null
        : loadThemeData<KosmosButtonThemeData>(
            null,
            themeData.settingsButtonThemeName!,
            () => const KosmosButtonThemeData(),
            isDark: ref.watch(isDarkModeProvider).isDarkMode,
          );

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: themeData.pageBackgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          if (themeData.changeEmailBackgroundPage != null)
            Positioned.fill(
              child: themeData.changeEmailBackgroundPage!(context, ref),
            ),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              primary: true,
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
                        onTap: () => AutoRouter.of(context).canPop()
                            ? AutoRouter.of(context).pop()
                            : AutoRouter.of(context).navigateBack(),
                        color: themeData.actionIconColor,
                        padding: EdgeInsets.symmetric(
                            horizontal: formatWidth(27.5),
                            vertical: formatHeight(8)),
                      ),
                      sw(12),
                      Expanded(
                          child: Center(
                              child: Text(
                                  "package.settings.node.change-email.title"
                                      .tr(),
                                  style: themeData.subNodeTitleStyle ??
                                    themeData.sectionTitleStyle,
                                  textAlign: TextAlign.center))),
                      sw(12),
                      Opacity(
                        opacity: 0,
                        child: ButtonBack(
                          onTap: () {},
                          padding: EdgeInsets.symmetric(
                              horizontal: formatWidth(27.5)),
                        ),
                      ),
                    ],
                  ),
                  sh(themeData.subNodeTitleSpacing ?? 54),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: formatWidth(27.5)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FormClassicField(
                            themeName: themeData.formFieldThemeName,
                            fieldName:
                                "package.field.auth.email-or-id.title".tr(),
                            hintText:
                                "package.field.auth.email-or-id.hint".tr(),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            controller: _controller,
                            focusNode: _emailFocusNode,
                            nextNode: _passwordFocusNode,
                            validator: (value) =>
                                AuthValidator.validEmail(value),
                            onChanged: (val) => email = val,
                          ),
                          sh(14),
                          FormClassicField(
                            themeName: themeData.formFieldThemeName,
                            fieldName: "package.field.auth.password.title".tr(),
                            hintText: "package.field.auth.password.hint".tr(),
                            focusNode: _passwordFocusNode,
                            isSecretField: true,
                            validator: (value) {
                              final rep = FieldValidator.fieldNotEmpty(value);
                              return rep;
                            },
                            onChanged: (val) => password = val,
                          ),
                          sh(37),
                          config?.authentificationConfig.changeEmailButtonCustom
                                  ?.call(
                                context,
                                ref,
                                () async => _changeEmail(context),
                              ) ??
                              Button(
                                theme: buttonThemeData,
                                text: settingsConfig.buttonChangeEmailBuilder ==
                                        null
                                    ? "utils.modify".tr()
                                    : null,
                                height:
                                    buttonThemeData?.height ?? formatHeight(54),
                                onTap: () async => _changeEmail(context),
                                child: settingsConfig.buttonChangeEmailBuilder
                                    ?.call(context, ref),
                              ),
                        ],
                      ),
                    ),
                  ),
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

  _changeEmail(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (email == FirebaseAuth.instance.currentUser!.email) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: "package.kosmos-auth.cant-be-same-email".tr());
      return;
    }

    if (email == null ||
        email!.isEmpty ||
        email == ref.read(userProvider).user?.email) {
      AutoRouter.of(context).canPop()
          ? AutoRouter.of(context).pop()
          : AutoRouter.of(context).navigateBack();
      return;
    }

    final alreadyExist = await KosmosAuth.emailDoesExist(
      email!,
      region: config?.cloudRegion ?? "us-central1",
    );
    final canContinue = alreadyExist.fold<bool>((l) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(), subtitle: l);
      return false;
    }, (r) => !r);

    if (!canContinue) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: "package.kosmos-auth.email-already-in-use".tr());
      return;
    }

    final r = await KosmosAuth.updateEmail(
        FirebaseAuth.instance.currentUser!.email!, email!, password!);
    if (r != null) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(), subtitle: r);
      return;
    }
    final themeData = loadThemeData(
      null,
      "dialog_alert",
      () => const AlertTheme(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    await PopupAlert.dialogBox(
      context,
      title: "package.skeleton.auth.verify-email".tr(),
      subtitle: "package.skeleton.auth.verify-email-subtitle".tr(),
      actionsBuilder: [
        (_) => Center(
              child:
                  config?.authentificationConfig.verifyEmailButtonCustom?.call(
                        _,
                        ref,
                        () => Navigator.of(_).pop(),
                      ) ??
                      Button(
                        theme: buttonThemeData,
                        text: settingsConfig.buttonVerifyEmailBuilder == null
                            ? "utils.close".tr()
                            : null,
                        buttonType: ButtonType.primary,
                        width: themeData?.buttonWidth ?? formatWidth(140),
                        height: buttonThemeData?.height ?? formatHeight(54),
                        onTap: () => Navigator.of(_).pop(),
                        child: settingsConfig.buttonVerifyEmailBuilder
                            ?.call(context, ref),
                      ),
            ),
      ],
    );
    AutoRouter.of(context).canPop()
        ? AutoRouter.of(context).pop()
        : AutoRouter.of(context).navigateBack();
  }
}
