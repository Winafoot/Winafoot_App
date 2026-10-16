import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:kosmos_auth/controller/auth.dart';
import 'package:skeleton/skeleton.dart';
import 'package:skeleton/view/widget/parent/auth_parent.dart';

class ResetPasswordPage extends StatefulHookConsumerWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final PageController _pageController = PageController();

  String? resetEmail;

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
        logoSize: themeData.logoSize,
        child: getResponsiveValue(context,
            defaultValue: _buildWeb(context, themeData),
            phone: _buildPhone(context, themeData)),
      ),
    );
  }

  Widget _buildPhone(BuildContext context, AuthTemplateThemeData themeData,
      [EdgeInsetsGeometry? padding]) {
    return ExpandablePageView(
      controller: _pageController,
      children: [
        Padding(
          padding: padding ??
              themeData.formPadding ??
              EdgeInsets.symmetric(horizontal: formatWidth(27.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  "package.skeleton.auth.reset-password-modal.title".tr(),
                  style:
                      themeData.popupTitleStyle ?? DefaultAppStyle.darkBlue(17),
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
                key: _formKey,
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
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
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
                        }, (r) {
                          printDebug("pass");
                          _pageController.animateToPage(1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
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
                    height: formatHeight(54),
                    onTap: () async {
                      if (!(_formKey.currentState?.validate() ?? false)) return;
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
                        }, (r) {
                          printDebug("pass");
                          _pageController.animateToPage(1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
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
        ),
        Padding(
          padding: padding ??
              themeData.formPadding ??
              EdgeInsets.symmetric(horizontal: formatWidth(27.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  "package.skeleton.auth.verify-email".tr(),
                  style:
                      themeData.popupTitleStyle ?? DefaultAppStyle.darkBlue(17),
                  textAlign: TextAlign.center,
                ),
              ),
              sh(10),
              Center(
                child: Text(
                  "package.skeleton.auth.verify-email-subtitle".tr(),
                  style: themeData.subtitleStyle ??
                      DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              sh(41),
              config?.authentificationConfig.verifyEmailButtonCustom?.call(
                    context,
                    ref,
                    () => AutoRouter.of(context).replaceNamed("/auth/login"),
                  ) ??
                  Button(
                    height: formatHeight(54),
                    text: config?.authentificationConfig
                                .verifyEmailButtonBuilder ==
                            null
                        ? "utils.update".tr()
                        : null,
                    onTap: () =>
                        AutoRouter.of(context).replaceNamed("/auth/login"),
                    child: config
                        ?.authentificationConfig.verifyEmailButtonBuilder
                        ?.call(context, ref),
                  ),
            ],
          ),
        ),
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
      child: _buildPhone(context, themeData, EdgeInsets.zero),
    );
  }
}
