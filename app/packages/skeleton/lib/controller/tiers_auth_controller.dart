// ignore_for_file: use_build_context_synchronously

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kosmos_auth/controller/auth.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:skeleton/skeleton.dart';
import 'package:ui_kosmos_v4/checkbox/checkbox.dart';

abstract class TiersAuthController {
  static Future<bool> signInWithTiers(
      BuildContext context, WidgetRef ref, AuthTiers authTiers) async {
    try {
      SkeletonAppConfig? config = GetIt.instance<AppModel>()
          .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none) &&
          connectivityResult.length == 1) {
        final fToast = FToast();
        fToast.init(context);
        PopupAlert.toast(context, fToast,
            title: "utils.error".tr(),
            subtitle: "package.kosmos-auth.error-internet".tr());
        return false;
      }

      if (authTiers == AuthTiers.facebook) {
        if (config?.authentificationConfig.signInWithFacebook != null) {
          return await config!
              .authentificationConfig.signInWithFacebook!(context);
        } else {
          return false;
        }
      } else if (authTiers == AuthTiers.google) {
        final isSignedIn = await GoogleSignIn().isSignedIn();
        if (isSignedIn) {
          await GoogleSignIn().disconnect();
        }
        final googleUser = await KosmosAuth.getGoogleCredential();

        if (googleUser == null) return false;

        final rep = await KosmosAuth.emailDoesExist(
          googleUser.email,
          region: config?.cloudRegion ?? "us-central1",
        );
        if (rep.isLeft()) {
          PopupAlert.toast(context, FToast().init(context),
              title: "utils.error".tr(),
              subtitle: "package.kosmos-auth.error-default".tr());
          return false;
        }

        return await rep.fold<Future<bool>>((l) async => false, (r) async {
          if (r) {
            final googleRep = await KosmosAuth.signInWithGoogle(googleUser);
            final googleOk = googleRep.fold((_) => false, (_) => true);
            if (googleOk) return true;

            final password = await _getPassword(context, ref);
            if (password == null) return false;

            final rep =
                await KosmosAuth.signInWithEmail(googleUser.email, password);
            return await rep.fold<Future<bool>>((l) async {
              PopupAlert.toast(context, FToast().init(context),
                  title: "utils.error".tr(), subtitle: l);
              return false;
            }, (r) async {
              return await KosmosAuth.linkCurrentUserWithGoogleCredential(
                  googleUser);
            });
          } else {
            bool? accepted = await _showCguBottomSheet(context, ref);
            if (accepted != true) {
              return false;
            }
            final rep = await KosmosAuth.signInWithGoogle(googleUser);

            return await rep.fold((l) async {
              PopupAlert.toast(context, FToast().init(context),
                  title: "utils.error".tr(),
                  subtitle: "package.kosmos-auth.error-default".tr());
              return false;
            }, (r) async {
              await UserController.createNewUserDocument(
                FirebaseAuth.instance.currentUser!.uid,
                googleUser.email,
                null,
                null,
                "users",
                config?.authentificationConfig.getUserType != null
                    ? (await config!
                        .authentificationConfig.getUserType!(context))
                    : config!.authentificationConfig.userType,
              );
              // KosmosAuth.sendEmailVerification(
              //     FirebaseAuth.instance.currentUser!.uid);
              // await PopupAlert.dialogBox(
              //   context,
              //   title: "package.skeleton.auth.verify-email".tr(),
              //   subtitle:
              //       "package.skeleton.auth.create-account-verify-email-subtitle"
              //           .tr(args: [googleUser.email]),
              //   actionsBuilder: [
              //     (_) => Center(
              //           child: Button(
              //             text: "utils.close".tr(),
              //             buttonType: ButtonType.primary,
              //             width: formatWidth(140),
              //             height: formatHeight(54),
              //             onTap: () => Navigator.of(_).pop(),
              //           ),
              //         ),
              //   ],
              // );
              return true;
            });
          }
        });
      } else if (authTiers == AuthTiers.apple) {
        final rawNonce = KosmosAuth.generateNonce();
        final nonce = KosmosAuth.sha256ofString(rawNonce);
        final appleUser = await KosmosAuth.getAppleCredential(rawNonce, nonce);
        if (appleUser == null) return false;

        // second attempt => apple signin always return .email null
        if (appleUser.email == null) {
          if (appleUser.userIdentifier == null) {
            PopupAlert.toast(context, FToast().init(context),
                title: "utils.error".tr(),
                subtitle: "package.kosmos-auth.must-have-valid-email".tr());
            return false;
          }
          final isExistAppleId = await UserController.isSocialCredentialExist(
              appleUser.userIdentifier!);

          if (isExistAppleId) {
            await KosmosAuth.signInWithApple(appleUser, rawNonce);
            return true;
          } else {
            String? email = await KosmosAuth.getAppleEmailFromDatabase(
                appleUser.userIdentifier!);
            if (email == null) {
              PopupAlert.toast(
                context,
                FToast().init(context),
                title: "utils.error".tr(),
                duration: const Duration(seconds: 5),
                subtitle: "package.kosmos-auth.reset-apple-signin".tr(),
              );
              return false;
            }
            bool? accepted = await _showCguBottomSheet(context, ref);
            if (accepted != true) {
              return false;
            }
            final rep2 = await KosmosAuth.signInWithApple(appleUser, rawNonce);
            return rep2.fold<Future<bool>>((l) async {
              PopupAlert.toast(context, FToast().init(context),
                  title: "utils.error".tr(),
                  subtitle: "package.kosmos-auth.error-default".tr());
              return false;
            }, (r) async {
              await UserController.createNewUserDocument(
                FirebaseAuth.instance.currentUser!.uid,
                email,
                null,
                null,
                "users",
                config?.authentificationConfig.getUserType != null
                    ? (await config!
                        .authentificationConfig.getUserType!(context))
                    : config?.authentificationConfig.userType,
                appleUser.userIdentifier,
                appleUser.givenName,
                appleUser.familyName,
              );

              return true;
            });
          }
        }

        final rep = await KosmosAuth.emailDoesExist(
          appleUser.email!,
          region: config?.cloudRegion ?? "us-central1",
        );
        if (rep.isLeft()) {
          PopupAlert.toast(context, FToast().init(context),
              title: "utils.error".tr(),
              subtitle: "package.kosmos-auth.error-default".tr());
          return false;
        }
        final result = rep.fold((l) => false, (r) => r);
        if (result) {
          final appleRep =
              await KosmosAuth.signInWithApple(appleUser, rawNonce);
          final appleOk = appleRep.fold((_) => false, (_) => true);
          if (appleOk) return true;

          final password = await _getPassword(context, ref);
          if (password == null) return false;

          final rep =
              await KosmosAuth.signInWithEmail(appleUser.email!, password);
          return await rep.fold<Future<bool>>((l) async {
            PopupAlert.toast(context, FToast().init(context),
                title: "utils.error".tr(), subtitle: l);
            return false;
          }, (r) async {
            return await KosmosAuth.linkCurrentUserWithAppleCredential(
                appleUser, rawNonce);
          });
        }
        bool? accepted = await _showCguBottomSheet(context, ref);
        if (accepted != true) {
          return false;
        }
        final rep2 = await KosmosAuth.signInWithApple(appleUser, rawNonce);
        return rep2.fold<Future<bool>>((l) async {
          PopupAlert.toast(context, FToast().init(context),
              title: "utils.error".tr(),
              subtitle: "package.kosmos-auth.error-default".tr());
          return false;
        }, (r) async {
          if (appleUser.email != null) {
            await KosmosAuth.storeEmailInDatabse(
                appleUser.userIdentifier!, appleUser.email!);
          }

          await UserController.createNewUserDocument(
            FirebaseAuth.instance.currentUser!.uid,
            appleUser.email,
            null,
            null,
            "users",
            config?.authentificationConfig.getUserType != null
                ? (await config!.authentificationConfig.getUserType!(context))
                : config?.authentificationConfig.userType,
            appleUser.userIdentifier,
            appleUser.givenName,
            appleUser.familyName,
          );
          // await KosmosAuth.sendEmailVerification(
          //     FirebaseAuth.instance.currentUser!.uid);
          // await PopupAlert.dialogBox(
          //   context,
          //   title: "package.skeleton.auth.create-account-verify-email"
          //       .tr(args: [appleUser.email.toString()]),
          //   subtitle:
          //       "package.skeleton.auth.create-account-verify-email-subtitle"
          //           .tr(args: [appleUser.email ?? ""]),
          //   actionsBuilder: [
          //     (_) => Center(
          //           child: Button(
          //             text: "utils.close".tr(),
          //             buttonType: ButtonType.primary,
          //             width: formatWidth(140),
          //             height: formatHeight(54),
          //             onTap: () => Navigator.of(_).pop(),
          //           ),
          //         ),
          //   ],
          // );
          return true;
        });
      }
    } catch (e) {
      printExcept(e);
    }
    return false;
  }

  //// Private ////
  static Future<String?> _getPassword(
      BuildContext context, WidgetRef ref) async {
    final GlobalKey<FormState> resetPasswordFormKey = GlobalKey<FormState>();
    final themeData = loadThemeData<AuthTemplateThemeData>(
        null, "authentication_theme", () => const AuthTemplateThemeData(),
        isDark: ref.read(isDarkModeProvider).isDarkMode);
    String? password;

    final rep = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: themeData.modalBottomSheetShapeBorder ??
          RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r(55)))),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                child: Text(
                  "package.skeleton.auth.tiers-signin.get-password-title".tr(),
                  style:
                      themeData.popupTitleStyle ?? DefaultAppStyle.darkBlue(17),
                  textAlign: TextAlign.center,
                ),
              ),
              sh(10),
              Center(
                child: Text(
                  "package.skeleton.auth.tiers-signin.get-password-subtitle"
                      .tr(),
                  style: themeData.subtitleStyle ??
                      DefaultAppStyle.simpleGrey(13, FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              sh(33),
              Form(
                key: resetPasswordFormKey,
                child: FormClassicField(
                  fieldName: "package.field.auth.password.title".tr(),
                  hintText: "package.field.auth.password.hint".tr(),
                  isSecretField: true,
                  validator: FieldValidator.fieldNotEmpty,
                  onChanged: (val) => password = val,
                ),
              ),
              sh(40),
              Button(
                text: "utils.connexion".tr(),
                buttonType: ButtonType.primary,
                height: formatHeight(54),
                onTap: () async {
                  if (!(resetPasswordFormKey.currentState?.validate() ??
                      false)) {
                    return;
                  }
                  Navigator.of(ctx).pop(true);
                },
              ),
              SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom + formatHeight(12)),
            ],
          ),
        );
      },
    );
    if (rep ?? false) return password;
    return null;
  }

  static Future<bool?> _showCguBottomSheet(
      BuildContext context, WidgetRef ref) async {
    final ScrollController scrollController = ScrollController();
    final future = AppMetadataController.getMetadataConfig();
    bool cgvuAccepted = false;

    final themeData = loadThemeData<AuthTemplateThemeData>(
      null,
      "authentication_theme",
      () => const AuthTemplateThemeData(),
      isDark: ref.read(isDarkModeProvider).isDarkMode,
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
                  onChanged: (val) {
                    newState(() => cgvuAccepted = !cgvuAccepted);
                  },
                  isChecked: cgvuAccepted,
                ),
                sh(33),
                Center(
                  child: Button(
                    text: "utils.continue".tr(),
                    height: formatHeight(54),
                    width: formatWidth(170),
                    enabled: cgvuAccepted,
                    onTap: () {
                      Navigator.pop(context, true);
                    },
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
  }
}
