// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kosmos_auth/controller/auth.dart';
import 'package:skeleton/skeleton.dart';

class ChangePasswordPage extends StatefulHookConsumerWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final PasswordSecurityConfig? passwordSecurityConfig =
      GetIt.I.isRegistered<AppMetadataConfig>()
          ? GetIt.I<AppMetadataConfig>().passwordSecurityConfig
          : null;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _oldPasswordFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  String? oldPassword, password, confirmPassword;

  bool _isPasswordError = false;
  PasswordStrengthQuality? _passwordStrength;

  final settingsConfig = (getAppModel().dependencies.packages["kosmos-settings"]
          as KosmosSettingsConfig?) ??
      KosmosSettingsConfig();

  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

  @override
  void dispose() {
    _oldPasswordFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _passwordController.dispose();
    _oldPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_isPasswordError) {
        setState(() {
          _passwordStrength =
              AuthValidator.passwordStrength(_passwordController.text);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final KosmosSettingsThemeData themeData = loadThemeData(
      null,
      "kosmos-settings",
      () => kDefaultSettingsTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    late final authThemeData = loadThemeData<AuthTemplateThemeData>(
        null, "authentication_theme", () => const AuthTemplateThemeData(),
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    final buttonThemeData = themeData.settingsButtonThemeName == null
        ? null
        : loadThemeData<KosmosButtonThemeData>(
            null,
            themeData.settingsButtonThemeName!,
            () => const KosmosButtonThemeData(),
            isDark: ref.watch(isDarkModeProvider).isDarkMode,
          );

    return getResponsiveValue<Widget>(context,
        defaultValue: _buildWeb(context),
        phone: _buildPhone(context, themeData, buttonThemeData, authThemeData));
  }

  Widget _buildPhone(
      BuildContext context,
      KosmosSettingsThemeData themeData,
      KosmosButtonThemeData? buttonThemeData,
      AuthTemplateThemeData authThemeData) {
    return Container(
      color: themeData.pageBackgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          if (themeData.changePasswordBackgroundPage != null)
            Positioned.fill(
              child: themeData.changePasswordBackgroundPage!(context, ref),
            ),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              primary: true,
              child: Form(
                key: _formKey,
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
                                    "package.settings.node.change-password.title"
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
                                horizontal: formatWidth(27.5),
                                vertical: formatHeight(8)),
                          ),
                        ),
                      ],
                    ),
                    sh(themeData.subNodeTitleSpacing ?? 54),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: formatWidth(29)),
                      child: FormClassicField(
                        fieldName:
                            "package.field.auth.actual-password.title".tr(),
                        hintText:
                            "package.field.auth.actual-password.hint".tr(),
                        controller: _oldPasswordController,
                        focusNode: _oldPasswordFocusNode,
                        nextNode: _passwordFocusNode,
                        textInputAction: TextInputAction.next,
                        isSecretField: true,
                        validator: (value) =>
                            FieldValidator.fieldNotEmpty(value),
                        onChanged: (val) => oldPassword = val,
                      ),
                    ),
                    sh(14),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: formatWidth(29)),
                      child: FormClassicField(
                        fieldName: "package.field.auth.new-password.title".tr(),
                        hintText: "package.field.auth.new-password.hint".tr(),
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        nextNode: _confirmPasswordFocusNode,
                        textInputAction: TextInputAction.next,
                        isSecretField: true,
                        validator: (value) {
                          final rep = AuthValidator.validPassword(
                              value, passwordSecurityConfig);
                          if (rep != null) {
                            _passwordStrength =
                                AuthValidator.passwordStrength(value);
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
                        margin:
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
                            if ((passwordSecurityConfig?.atLeast6Char ??
                                    true) ||
                                passwordSecurityConfig?.passwordMinimalLength !=
                                    null)
                              _buildItemValid(
                                  context,
                                  "package.kosmos-auth.password-security-length"
                                      .tr(args: [
                                    passwordSecurityConfig
                                            ?.passwordMinimalLength
                                            .toInt()
                                            .toString() ??
                                        "6"
                                  ]),
                                  _passwordStrength!.isValidLength),
                            if (passwordSecurityConfig?.atLeast1Uppercase ??
                                true)
                              _buildItemValid(
                                  context,
                                  "package.kosmos-auth.password-security-min"
                                      .tr(),
                                  _passwordStrength!.hasLowercase),
                            if (passwordSecurityConfig?.atLeast1Lowercase ??
                                true)
                              _buildItemValid(
                                  context,
                                  "package.kosmos-auth.password-security-maj"
                                      .tr(),
                                  _passwordStrength!.hasUppercase),
                            if (passwordSecurityConfig?.atLeast1Number ?? true)
                              _buildItemValid(
                                  context,
                                  "package.kosmos-auth.password-security-number"
                                      .tr(),
                                  _passwordStrength!.hasDigits),
                            if (passwordSecurityConfig?.atLeast1SpecialChar ??
                                true)
                              _buildItemValid(
                                  context,
                                  "package.kosmos-auth.password-security-special"
                                      .tr(),
                                  _passwordStrength!.hasSpecialCharacters),
                          ],
                        ),
                      )
                    ],
                    sh(14),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: formatWidth(29)),
                      child: FormClassicField(
                        fieldName:
                            "package.field.auth.new-repeat-password.title".tr(),
                        hintText:
                            "package.field.auth.new-repeat-password.hint".tr(),
                        focusNode: _confirmPasswordFocusNode,
                        controller: _confirmPasswordController,
                        textInputAction: TextInputAction.done,
                        isSecretField: true,
                        validator: (val) =>
                            AuthValidator.validSamePassword(password, val),
                        onChanged: (val) => confirmPassword = val,
                      ),
                    ),
                    sh(37),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: formatWidth(29)),
                      child: config?.authentificationConfig
                              .changePasswordButtonCustom
                              ?.call(
                            context,
                            ref,
                            () async => _changePassword(context),
                          ) ??
                          Button(
                            theme: buttonThemeData,
                            text: settingsConfig.buttonChangePasswordBuilder ==
                                    null
                                ? "utils.modify".tr()
                                : null,
                            height: buttonThemeData?.height ?? formatHeight(54),
                            onTap: () async => _changePassword(context),
                            child: settingsConfig.buttonChangePasswordBuilder
                                ?.call(context, ref),
                          ),
                    )
                  ],
                ),
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

  Widget _buildItemValid(BuildContext context, String tr, bool valid) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(valid ? Icons.check_rounded : Icons.close_rounded,
            color: valid ? DefaultColor.success : DefaultColor.error,
            size: formatHeight(20)),
        sw(5.6),
        Expanded(
            child: Text(tr,
                style: DefaultAppStyle.simpleGrey(13, FontWeight.w500))),
      ],
    );
  }

  _changePassword(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (password == oldPassword) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: "package.kosmos-auth.cant-be-same-password".tr());
      return;
    }

    final r = await KosmosAuth.updatePassword(
        FirebaseAuth.instance.currentUser!.email!, oldPassword!, password!);
    if (r != null) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(), subtitle: r);
      return;
    }

    PopupAlert.toast(context, FToast().init(context),
        title: "utils.success".tr(),
        subtitle: "package.kosmos-auth.success-change-password".tr(),
        type: AlertType.success,
        duration: const Duration(seconds: 2));
    await Future.delayed(const Duration(seconds: 2));

    AutoRouter.of(context).canPop()
        ? AutoRouter.of(context).pop()
        : AutoRouter.of(context).navigateBack();
  }
}
