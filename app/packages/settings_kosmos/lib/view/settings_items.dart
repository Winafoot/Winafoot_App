// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:settings_kosmos/model/settings_config.dart';
import 'package:settings_kosmos/theme/settings_theme_data.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// {@category Widget}
/// {@category KosmosSettings}
///
/// Ce Widget permet d'afficher le contenu de la page de Settings. En commeçant par le profil de l'utilisateur, puis les sections de paramètres.
/// Vous pouvez configurer la section profil ainsi que la liste des cellules via [KosmosSettingsConfig] donnée en paramètre.
/// La liste des [CelluleSection] doit être donnée en paramètre, si celle-ci est uniquement présente dans la configuration, elle ne sera pas utilisé.
///
/// Vous devez fournir les informations relatives à l'utilisateur via les paramètres [profilImage] (url internet uniquement, pas d'asset local),
/// [fullName] et [email].
///
/// **/!\ SKELETON /!\**, si vous utiliser l'un des skeletons de Kosmos Digital, vous n'avez pas besoin de créer vous-même ce widget.
/// les pages de settings déjà existantes l'utilise. Vous devez uniquement configurer la "PackageDependencies" via le clé "kosmos-settings" avec
/// un objet [KosmosSettingsConfig] en paramètre.
///
class SettingsProfil extends StatefulHookConsumerWidget {
  final KosmosSettingsConfig? settingsConfig;
  final List<CelluleSection> settingsSection;

  final String? profilImage;
  final String? fullName;
  final String? email;

  /// Theme
  final String? themeName;
  final KosmosSettingsThemeData? theme;
  final String? settingsCelluleThemeName;
  final SettingsCelluleThemeData? settingsCelluleTheme;

  const SettingsProfil({
    super.key,
    this.settingsConfig,
    required this.settingsSection,
    this.profilImage,
    this.fullName,
    this.email,
    this.settingsCelluleThemeName,
    this.settingsCelluleTheme,

    /// Theme
    this.themeName,
    this.theme,
  });

  @override
  ConsumerState<SettingsProfil> createState() => _SettingsProfilState();
}

class _SettingsProfilState extends ConsumerState<SettingsProfil> {
  late final KosmosSettingsConfig settingsConfig =
      widget.settingsConfig ?? KosmosSettingsConfig();
 
  @override
  Widget build(BuildContext context) {
     late final KosmosSettingsThemeData themeData = loadThemeData(widget.theme,
      widget.themeName ?? "kosmos-settings", () => kDefaultSettingsTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
      );
  late final SettingsCelluleThemeData settingsCelluleThemeData = loadThemeData(
      widget.settingsCelluleTheme,
      widget.settingsCelluleThemeName ?? "settings_cellule",
      () => kDefaultCellule,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        sh(20),
        settingsConfig.settingsHeaderBuilder?.call(context, ref) ??
            _buildHeader(context, themeData, settingsCelluleThemeData),
        _buildSections(context, themeData, settingsCelluleThemeData),
        if (settingsConfig.showKosmosDigitalLine) ...[
          sh(23),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "package.settings.edited-by".tr(),
                    style: themeData.selectedByTextStyle,
                  ),
                  TextSpan(
                    text: "package.settings.kosmos-digital".tr(),
                    style: themeData.cliquableTextStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await launchUrl(
                            Uri.parse("https://kosmos-digital.com"));
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, KosmosSettingsThemeData themeData, SettingsCelluleThemeData settingsCelluleThemeData) {
    if (!settingsConfig.showProfilInfo) return const SizedBox();

    List<Widget> children = [];

    if (settingsConfig.showProfilImage) {
      children.add(
        Center(
          child: InkWell(
            onTap: settingsConfig.canModifyProfilImageCallback != null
                ? settingsConfig.canModifyProfilImageCallback!.call(ref)
                    ? () async => await _changeProfileImage(context)
                    : null
                : settingsConfig.canModifyProfilImage
                    ? settingsConfig.onModifyProfilButtonPressed ??
                        () async => await _changeProfileImage(context)
                    : null,
            child: Container(
              width: formatWidth(92),
              height: formatWidth(92),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(formatWidth(46)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: widget.profilImage != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(formatWidth(46)),
                            child: CachedNetworkImage(
                              imageUrl: widget.profilImage!,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              placeholder: (context, url) => Image.asset(
                                  "assets/images/img_default_user.png",
                                  package: "settings_kosmos",
                                  fit: BoxFit.cover),
                              errorWidget: (context, url, error) => Image.asset(
                                  "assets/images/img_default_user.png",
                                  package: "settings_kosmos",
                                  fit: BoxFit.cover),
                            ),
                          )
                        : Image.asset("assets/images/img_default_user.png",
                            package: "settings_kosmos", fit: BoxFit.cover),
                  ),
                  if (settingsConfig.canModifyProfilImageCallback?.call(ref) ??
                      settingsConfig.canModifyProfilImage) ...[
                    _getProfilModifButtonPositioned(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      if (settingsConfig.profilImagePosition ==
          ProfilImagePosition.bottomCenter) {
        children.add(sh(5));
      }
    }

    if (settingsConfig.showFullName) {
      if (settingsConfig.showProfilImage) children.add(sh(4.4));
      children.add(
        Center(
            child: Text(
                settingsConfig.profileNameBuilder?.call(ref) ??
                    widget.fullName ??
                    "",
                style: themeData.fullNameStyle,
                textAlign: TextAlign.center)),
      );
    }

    if (settingsConfig.showEmail) {
      children.add(
        Center(
            child: Text(widget.email ?? "",
                style: themeData.emailStyle, textAlign: TextAlign.center)),
      );
    }

    children.add(sh(13));
    children.add(const Divider(height: .5, thickness: 0));
    children.add(sh(themeData.sectionSpacing ?? 23));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children);
  }

  Widget _buildSections(BuildContext context, KosmosSettingsThemeData themeData, SettingsCelluleThemeData settingsCelluleThemeData) {
    final List<Widget> children = [];

    final sections = widget.settingsSection;

    for (final section in sections) {
      children.add(
        Padding(
          padding: section.padding ?? EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (section.showTitle)
                if (section.titleBuilder != null)
                  section.titleBuilder!.call(context, ref)
                else ...[
                  Text(section.title.call(context, ref),
                      style: themeData.sectionTitleStyle ??
                          DefaultAppStyle.darkBlue(16)),
                  sh(9),
                ],
              ...section.cellules.map(
                (cell) {
                  if (cell.hide?.call(context, ref) ?? false) {
                    return const SizedBox();
                  }
                  final isLast = section.cellules.last == cell;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsCellule(model: cell),
                      if (!isLast)
                        SizedBox(
                          height: settingsCelluleThemeData.spaceBetweenCellules,
                        ),
                    ],
                  );
                },
              ),
              if (section != sections.last && section.padding == null)
                sh(themeData.sectionSpacing ?? 23),
            ],
          ),
        ),
      );
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children);
  }

  Positioned _getProfilModifButtonPositioned(BuildContext context) {
    final child = Column(
      children: [
        Container(
          width: formatWidth(22),
          height: formatWidth(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(formatWidth(46)),
            color: Colors.black.withOpacity(.7),
          ),
          child: Center(
              child: SvgPicture.asset("assets/svg/edit.svg",
                  package: "settings_kosmos")),
        ),
      ],
    );

    if (settingsConfig.profilImagePosition ==
        ProfilImagePosition.bottomCenter) {
      return Positioned(
          bottom: -formatHeight(12), left: 0, right: 0, child: child);
    } else if (settingsConfig.profilImagePosition ==
        ProfilImagePosition.bottomRight) {
      return Positioned(bottom: 0, right: 0, child: child);
    } else {
      return Positioned(bottom: 0, left: 0, child: child);
    }
  }

  Future<void> _changeProfileImage(BuildContext context) async {
    /// Si c'est une application Web, nous prenons l'image depuis les documents directement (pas de camera)
    final String? eventTag = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        message: Text("utils.what-do-you-want-to-do".tr()),
        actions: [
          CupertinoActionSheetAction(
            child: Text("package.image.from-gallery".tr()),
            onPressed: () => Navigator.of(ctx).pop("from-gallery"),
          ),
          CupertinoActionSheetAction(
            child: Text("package.image.from-camera".tr()),
            onPressed: () => Navigator.of(ctx).pop("from-camera"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text("utils.cancel".tr()),
          onPressed: () => Navigator.of(ctx).pop(null),
        ),
      ),
    );

    if (eventTag == null) return;

    ImageSource source =
        eventTag == "from-gallery" ? ImageSource.gallery : ImageSource.camera;

    if (source == ImageSource.camera &&
        (await Permission.camera.isDenied ||
            await Permission.camera.isPermanentlyDenied)) {
      if (kDebugMode) {
        print(
            'Permission.camera.isDenied || Permission.camera.isPermanentlyDenied');
      }
      final perm = await Permission.camera.request();
      if (perm.isDenied || perm.isPermanentlyDenied) {
        return;
      }
    } else if (Platform.isIOS) {
      // PermissionStatus mediaLibraryPerm =
      //     await Permission.mediaLibrary.request();
      PermissionStatus photosPerm = await Permission.photos.request();
      PermissionStatus storagePerm = await Permission.storage.request();

      // if (source == ImageSource.gallery && !mediaLibraryPerm.isGranted) {
      //   if (kDebugMode) {
      //     print(
      //         'Permission.mediaLibrary.isDenied || Permission.mediaLibrary.isPermanentlyDenied');
      //   }
      //   final perm = await Permission.mediaLibrary.request();
      //   if (perm.isDenied || perm.isPermanentlyDenied) {
      //     await openAppSettings();
      //     return;
      //   }
      // } else
      if (source == ImageSource.gallery && !photosPerm.isGranted) {
        if (kDebugMode) {
          print(
              'Permission.photos.isDenied || Permission.photos.isPermanentlyDenied');
        }
        final perm = await Permission.photos.request();
        if (perm.isDenied || perm.isPermanentlyDenied) {
          if (context.mounted) {
            SettingsController.permissionToRedirectToSettings(
                context, "photos");
          }
          return;
        } else if (source == ImageSource.gallery && !storagePerm.isGranted) {
          if (kDebugMode) {
            print(
                'Permission.storage.isDenied || Permission.storage.isPermanentlyDenied');
          }
          final perm = await Permission.storage.request();
          if (perm.isDenied || perm.isPermanentlyDenied) {
            if (context.mounted) {
              SettingsController.permissionToRedirectToSettings(
                  context, "storage");
            }
            return;
          }
        }
      }
    } else {
      // "Remove this" => no need to use this now.
      // AndroidDeviceInfo androidDeviceInfo =
      //     await DeviceInfoPlugin().androidInfo;
      // bool sdkInt = (androidDeviceInfo.version.sdkInt) >= 33;

      // if (sdkInt) {
      //   PermissionStatus photosPerm = await Permission.photos.request();

      //   if (source == ImageSource.gallery && !photosPerm.isGranted) {
      //     if (kDebugMode) {
      //       print(
      //           'Permission.photos.isDenied || photosPerm.camera.isPermanentlyDenied');
      //     }
      //     if (context.mounted) {
      //       SettingsController.permissionToRedirectToSettings(
      //           context, "photos");
      //     }
      //     return;
      //   }
      // } else {
      //   PermissionStatus storagePermission = await Permission.storage.request();

      //   if (source == ImageSource.gallery && !storagePermission.isGranted) {
      //     print(
      //         'storagePermission.storage.isDenied || storagePermission.storage.isPermanentlyDenied');
      //     if (context.mounted) {
      //       SettingsController.permissionToRedirectToSettings(
      //           context, "storage");
      //     }
      //     return;
      //   }
      // }
    }

    final result = await {
      "from-gallery": ImageFileController.pickImageFromGallery,
      "from-camera": ImageFileController.pickImageFromCamera,
    }[eventTag]
        ?.call(context);

    if (result == null) return;

    final url = await ImageFileController.uploadFileToFirebaseStorage(result,
        "/users/${FirebaseAuth.instance.currentUser!.uid}/profileImage.${result.path.split(".").last}");

    if (url == null) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(), subtitle: "utils.error-default".tr());
      return;
    }

    Uint8List? compressedFile = await compressFile(File(result.path));
    // if (compressedFile == null) {
    //   if (mounted) {
    //     NotifBanner.showToast(
    //       context: context,
    //       fToast: FToast().init(context),
    //       subTitle: "app.error.error-occured",
    //       title: "utils.error".tr(),
    //     );
    //   }
    //   return;
    // }

    final String? compressedUrl = compressedFile == null
        ? null
        : await ImageFileController.uploadUint8ListToFirebaseStorage(
            compressedFile,
            "users/${FirebaseAuth.instance.currentUser!.uid}/compressed.${result.path.split("/").last}");
    // if (compressedUrl == null) {
    //   if (mounted) {
    //     NotifBanner.showToast(
    //       context: context,
    //       fToast: FToast().init(context),
    //       subTitle: "app.error.error-occured",
    //       title: "utils.error".tr(),
    //     );
    //   }
    //   return;
    // }
    final SizedImage image = SizedImage(url: url, compressedUrl: compressedUrl);

    if (await UserFirestoreController.updateData(
            {"userProfileImage": image.toJson(), "profilImage": url}) !=
        null) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(), subtitle: "utils.error-default".tr());
    }
  }
}
