// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kosmos_auth/controller/auth.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:skeleton/skeleton.dart';
import 'package:skeleton/theme/profile/settings/settings_theme.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// {@category Skeleton}
///
/// Par défaut, la page de paramètres utilise le thème défini dans [kDefaultSkeletonSettingsThemeData].
/// Vous pouvez définir votre propre thème en utilisant [SkeletonSettingsThemeData] via la key "skeleton-settings".
///
class SettingsPage extends StatefulHookConsumerWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final KosmosSettingsConfig config;

  late final List<CelluleSection> settingsSections;

  late final authConfig = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

  @override
  void initState() {
    config = (getAppModel().dependencies.packages["kosmos-settings"]
            as KosmosSettingsConfig?) ??
        KosmosSettingsConfig();
    settingsSections = config.settingsSection.call(ref);

    for (var section in settingsSections) {
      final index = settingsSections.indexOf(section);
      settingsSections[index] = _updateOnTapWithRedirect(section);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    late final KosmosSettingsThemeData themeData = loadThemeData(
      null,
      "kosmos-settings",
      () => kDefaultSettingsTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return getResponsiveValue<Widget>(context,
        defaultValue: _buildWeb(context),
        phone: _buildPhone(context, themeData));
  }

  CelluleSection _updateOnTapWithRedirect(CelluleSection node) {
    for (var cellule in node.cellules) {
      if (cellule.type == CelluleType.action && cellule.sectionChild != null) {
        final index = node.cellules.indexOf(cellule);
        node.cellules[index] =
            cellule.copyWith(onTap: (_, __, {bool? redirectToChildren}) async {
          await AutoRouter.of(context)
              .pushNamed("${config.pathSettingsNode}${cellule.tag}");

          return null;
        });
      }
      if (cellule.sectionChild != null) {
        _updateOnTapWithRedirect(cellule.sectionChild!);
      }
    }
    return node;
  }

  Widget _buildPhone(BuildContext context, KosmosSettingsThemeData themeData) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: themeData.pageBackgroundColor,
      child: Stack(
        children: [
          if (themeData.settingsBackgroundPageScrollable == false &&
              themeData.settingsBackgroundPage != null)
            Positioned.fill(
                child: themeData.settingsBackgroundPage!(context, ref)),
          Positioned.fill(
            child: SingleChildScrollView(
              primary: true,
              physics: const ClampingScrollPhysics(),
              // physics: const BouncingScrollPhysics(),
              child: Stack(
                children: [
                  if (themeData.settingsBackgroundPageScrollable == true &&
                      themeData.settingsBackgroundPage != null)
                    Positioned.fill(
                        child: themeData.settingsBackgroundPage!(context, ref)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).padding.top +
                              formatHeight(20)),
                      if (config.showAppLogo) ...[
                        SizedBox(
                          height: config.logoSize.height,
                          width: MediaQuery.of(context).size.width,
                          child: Stack(
                            children: [
                              const SizedBox(width: double.infinity),
                              Positioned(
                                  child: Center(
                                      child: _createImageLogo(
                                          authConfig!.logoPath,
                                          authConfig!.logoFormat))),
                              Positioned(
                                  top: formatHeight(10),
                                  left: 0,
                                  child: ButtonBack(
                                      onTap: () => AutoRouter.of(context).pop(),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: formatWidth(27.5)))),
                              Positioned(
                                top: formatHeight(10),
                                right: 0,
                                child: InkWell(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: formatWidth(27.5)),
                                    child: Icon(Icons.more_horiz_rounded,
                                        color: themeData.actionIconColor,
                                        size: formatWidth(26)),
                                  ),
                                  onTap: () async =>
                                      await _showProfilAction(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            ButtonBack(
                              color: themeData.actionIconColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: formatWidth(27.5)),
                              onTap: () => AutoRouter.of(context).pop(),
                            ),
                            const Spacer(),
                            InkWell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: formatWidth(27.5)),
                                child: Icon(Icons.more_horiz_rounded,
                                    color: themeData.actionIconColor,
                                    size: formatWidth(26)),
                              ),
                              onTap: () async =>
                                  await _showProfilAction(context),
                            ),
                          ],
                        ),
                      ],
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: formatWidth(27.5)),
                        child: SettingsProfil(
                          settingsConfig: config,
                          settingsSection: settingsSections,
                          profilImage: ref
                                  .watch(userProvider)
                                  .user
                                  ?.userProfileImage
                                  ?.compressedUrl ??
                              ref
                                  .watch(userProvider)
                                  .user
                                  ?.userProfileImage
                                  ?.url ??
                              ref.watch(userProvider).user?.profileImage,
                          fullName:
                              "${ref.watch(userProvider).user?.firstname ?? ""} ${ref.watch(userProvider).user?.lastname ?? ""}",
                          email: ref.watch(userProvider).user?.email,
                        ),
                      ),
                      SizedBox(
                          height: formatHeight(12) +
                              MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeb(
    BuildContext context,
  ) {
    late final KosmosSettingsThemeData themeData = loadThemeData(
      null,
      "kosmos-settings",
      () => kDefaultSettingsTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    return _buildPhone(context, themeData);
  }

  Future<void> _showProfilAction(BuildContext context) async {
    bool canDeleteAccount =
        ((await config.canDeleteAccount?.call(ref)) ?? true);

    final String? eventTag = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        message: Text(config.profilActionTitleText.tr()),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: Text("package.skeleton.profile.logout".tr()),
            onPressed: () => Navigator.of(ctx).pop("logout"),
          ),
          if (canDeleteAccount)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: Text("package.skeleton.profile.delete-account".tr()),
              onPressed: () => Navigator.of(ctx).pop("delete-account"),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text("utils.cancel".tr()),
          onPressed: () => Navigator.of(ctx).pop(null),
        ),
      ),
    );

    if (eventTag == null) return;

    final SkeletonAppConfig? authConfig = getAppModel()
        .dependencies
        .packages["skeleton_app_config"] as SkeletonAppConfig?;

    await {
      "logout": (BuildContext ctx) async {
        EasyLoading.show(status: "utils.loading".tr());

        AnalyticsAuthController.logout();
        if (authConfig?.authentificationConfig.logoutCallback != null) {
          return await authConfig?.authentificationConfig.logoutCallback
              ?.call(context, ref);
        }
        await UserController.logoutUser(context, ref);
        EasyLoading.dismiss();
      },
      "delete-account": _areYouSureDeleteProfil,
    }[eventTag]!
        .call(context);
  }

  /// Affiche un dialogue pour confirmer la suppression du compte.
  /// Si l'utilisateur accepte, appelle [KosmosAuth.deleteAccount] avec l'UID
  /// de l'utilisateur actuel, puis appelle [UserController.logoutUser] pour
  /// se déconnecter et supprimer le profil, et redirige vers la page d'accueil.
  /// Si l'utilisateur refuse, ferme le dialogue et ne fait rien.
  /// Displays a dialog to confirm account deletion.
  /// If the user confirms, it attempts to delete the account using
  /// [KosmosAuth.deleteAccount] with the current user's UID.
  /// If the deletion is successful, logs out and redirects to the main route.
  /// If the deletion fails, shows an error toast.
  /// If the user cancels, dismisses the dialog without taking further action.
  /// Affiche un dialogue pour confirmer la suppression du compte.
  /// Si l'utilisateur accepte, appelle [KosmosAuth.deleteAccount] avec l'UID
  /// de l'utilisateur actuel, puis appelle [UserController.logoutUser] pour
  /// Affiche un dialogue pour confirmer la suppression du compte.
  /// Si l'utilisateur accepte, appelle [KosmosAuth.deleteAccount] avec l'UID
  /// de l'utilisateur actuel, puis appelle [UserController.logoutUser] pour
  /// se déconnecter et supprimer le profil, et redirige vers la page d'accueil.
  /// Si l'utilisateur refuse, ferme le dialogue et ne fait rien.
  Future<void> _areYouSureDeleteProfil(BuildContext context) async {
    final theme = loadThemeData(
        null, "button_secondary", () => const KosmosButtonThemeData(),
        isDark: ref.watch(isDarkModeProvider).isDarkMode)!;

    final rep = await config.areYouSureDeleteAccount?.call(context) ??
        await PopupAlert.dialogBox<bool>(context,
            title: "package.skeleton.profile.delete-my-account".tr(),
            subtitle:
                "package.skeleton.profile.delete-my-account-subtitle".tr(),
            actionsBuilder: [
              (ctx) => Center(
                    child: Button(
                      buttonType: ButtonType.primary,
                      onTap: () => Navigator.of(ctx).pop(true),
                      text: "utils.yes".tr(),
                      width: formatWidth(140),
                      height: formatHeight(54),
                    ),
                  ),
              (ctx) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      sh(10),
                      Center(
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(false),
                          child: Padding(
                            padding: pwh(7.5, 15),
                            child: Text("utils.no".tr(),
                                style: theme.buttonTextStyle ??
                                    DefaultAppStyle.darkBlue(14)),
                          ),
                        ),
                      )
                    ],
                  ),
            ]);

    if (rep == true) {
      EasyLoading.show(status: "utils.loading".tr());
      final rep = await KosmosAuth.deleteAccount(
        FirebaseAuth.instance.currentUser!.uid,
        region: authConfig?.cloudRegion ?? "us-central1",
      );

      await UserController.logoutUser(context, ref, true, true);
      return await rep.fold((l) {
        EasyLoading.dismiss();
        PopupAlert.toast(context, FToast().init(context),
            title: "utils.error".tr(), subtitle: l.toString());
      }, (r) {
        EasyLoading.dismiss();

        if (!mounted) {
          printError("SettingsPage is not mounted");
          return;
        }
        final route = (getAppModel()
                .dependencies
                .packages["skeleton_app_config"] as SkeletonAppConfig?)
            ?.mainRouteInfo;
        if (route == null) return;

        AutoRouter.of(context).pushAndPopUntil(route, predicate: (_) => false);
      });
    }
    EasyLoading.dismiss();
  }

  Widget _createImageLogo(String path, LogoFormat format) {
    if (format == LogoFormat.svg) {
      return SvgPicture.asset(path,
          width: config.logoSize.width, height: config.logoSize.height);
    } else {
      return Image.asset(path,
          width: config.logoSize.width, height: config.logoSize.height);
    }
  }
}
