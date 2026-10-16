import 'package:wina/config/theme.dart';
import 'package:wina/view/page/check_profil_step1_screen.dart';
import 'package:wina/view/page/settings/settings_node.dart';
import 'package:wina/view/widget/custom_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skeleton/skeleton.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wina/view/page/settings/reset_password_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import "package:iconsax/iconsax.dart" show Iconsax;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// Contenu d'un pane « lien légal ».
///
/// Le pane défile déjà verticalement (settings_node.dart) et reçoit donc une
/// hauteur infinie : le contenu doit se dimensionner intrinsèquement, sans
/// enfant flex ni défilement supplémentaire. Un champ absent OU vide affiche
/// le texte de repli, pour que la page reste lisible sans contenu Firestore.
@visibleForTesting
Widget legalPaneContent(String? html) {
  return HtmlWidget(
    (html == null || html.trim().isEmpty)
        ? 'bar.settings.no-content'.tr()
        : html,
  );
}

/// Entête de la page Paramètres (design 198:243) : retour, filet vertical,
/// icône réglages, titre, puis wordmark Wina à droite.
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CustomBackButton(onTap: () => context.pop()),
        sw(14),
        Container(
          width: 1,
          height: formatHeight(28),
          color: AppColor.headerRule,
        ),
        sw(14),
        Icon(Iconsax.setting_2, size: sp(33), color: AppColor.primaryColor),
        sw(12),
        Expanded(
          child: Text(
            'package.settings.section-title.settings'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(28, AppColor.primaryLabels),
          ),
        ),
        sw(12),
        const WinaWordmark(size: 30),
      ],
    );
  }
}

/// Pastille d'icône des cellules de réglages : disque vert de 37 px et glyphe
/// blanc. Le disque reste vert quelle que soit la sélection (Figma).
class _CircleGlyph extends StatelessWidget {
  const _CircleGlyph({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: r(18.5),
      backgroundColor: AppColor.primaryColor,
      child: SvgPicture.asset(
        asset,
        width: sp(17),
        height: sp(17),
        colorFilter: const ColorFilter.mode(
          AppColor.textLight,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class SettingsWebPage extends ConsumerWidget {
  const SettingsWebPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config =
        GetIt.I.isRegistered<AppMetadataConfig>()
            ? GetIt.I<AppMetadataConfig>()
            : null;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: [
            const AppBackground(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sh(16),
                  const _SettingsHeader(),
                  sh(12),
                  Container(height: 1, color: AppColor.headerRule),
                  sh(16),
                  Expanded(
                    child: SettingsView(
                      leftHeaderBuilder: (context) {
                        final user = ref.watch(userProvider).user;
                        final imgUrl =
                            user?.userProfileImage?.compressedUrl ??
                            user?.userProfileImage?.url;
                        return userHeader(context, imgUrl, user, ref);
                      },
                      items: [
                        SettingsItem(
                          title:
                              'package.settings.section-title.personnal-data'
                                  .tr(),
                          children: [
                            // Identité de l'équipe : la cellule rouvre le
                            // formulaire de profil en mode édition pour
                            // corriger le nom de l'équipe, d'où le chevron
                            // des cellules navigables.
                            SettingsNode(
                              title:
                                  ref
                                              .watch(coachProfileProvider)
                                              .valueOrNull
                                              ?.teamName
                                              ?.trim()
                                              .isNotEmpty ??
                                          false
                                      ? ref
                                          .watch(coachProfileProvider)
                                          .valueOrNull!
                                          .teamName!
                                          .trim()
                                      : 'app.mon-equipe.nom-equipe-defaut'.tr(),
                              subtitle:
                                  ref.watch(userProvider).user?.email ?? "",
                              onTap:
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder:
                                          (_) => const CheckProfilStep1Screen(
                                            editMode: true,
                                          ),
                                    ),
                                  ),
                              children: [],
                            ),
                            SettingsNode(
                              leadingBuilder:
                                  (_) => const _CircleGlyph(
                                    asset: 'assets/svg/ic_security.svg',
                                  ),
                              title:
                                  'package.settings.node.security.title'.tr(),
                              paneTitle:
                                  'package.settings.node.security.title'.tr(),
                              subtitle:
                                  'package.settings.node.security.subtitle'
                                      .tr(),
                              children: [
                                SettingsNode(
                                  title:
                                      'package.settings.node.change-email.title'
                                          .tr(),
                                  paneTitle:
                                      'package.settings.node.change-email.title'
                                          .tr(),
                                  subtitle:
                                      ref.watch(userProvider).user?.email ?? "",
                                  contentBuilder: (context) {
                                    return _EditEmailForm(
                                      initialEmail:
                                          ref
                                              .watch(userProvider)
                                              .user
                                              ?.email ??
                                          '',
                                    );
                                  },
                                ),
                                SettingsNode(
                                  title:
                                      'package.settings.node.change-password.title'
                                          .tr(),
                                  paneTitle:
                                      'package.settings.node.change-password.title'
                                          .tr(),
                                  subtitle:
                                      ref
                                                  .watch(userProvider)
                                                  .securityMetadata
                                                  ?.lastPasswordUpdate !=
                                              null
                                          ? 'package.settings.node.change-password.subtitle'.tr(
                                            namedArgs: {
                                              "timeAgo":
                                                  DateTime.now()
                                                      .difference(
                                                        ref
                                                            .watch(userProvider)
                                                            .securityMetadata!
                                                            .lastPasswordUpdate!,
                                                      )
                                                      .formatTimeAgo(),
                                            },
                                          )
                                          : "utils.by-default".tr(),
                                  contentBuilder: (context) {
                                    return const ChangePasswordForm();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Paramètres
                        SettingsItem(
                          title: 'package.settings.section-title.settings'.tr(),
                          children: [
                            SettingsNode(
                              leadingBuilder:
                                  (_) => const _CircleGlyph(
                                    asset: 'assets/svg/ic_notif.svg',
                                  ),
                              title:
                                  'package.settings.node.email-notif.title'
                                      .tr(),
                              subtitle:
                                  (ref
                                              .watch(userProvider)
                                              .metadata
                                              ?.enableEmailNotification ??
                                          false)
                                      ? 'utils.activate'.tr()
                                      : 'utils.deactivate'.tr(),
                              trailingBuilder: (isSelected) {
                                final enabled =
                                    ref
                                        .watch(userProvider)
                                        .metadata
                                        ?.enableEmailNotification ??
                                    false;
                                return KosmosSwicth(
                                  isActive: enabled,
                                  onSwipe: (newVal) async {
                                    await NotifPermissionController.setEmailNotificationPermission(
                                      newVal,
                                      FirebaseAuth.instance.currentUser!.uid,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),

                        // Autres
                        SettingsItem(
                          title: 'package.settings.section-title.other'.tr(),
                          children: [
                            SettingsNode(
                              leadingBuilder:
                                  (_) => _CircleGlyph(
                                    asset: 'assets/svg/help.svg',
                                  ),
                              title: 'package.settings.node.help.title'.tr(),
                              subtitle:
                                  'package.settings.node.help.subtitle'.tr(),
                              onTap: () async {
                                final String contactEmail =
                                    GetIt.I.isRegistered<AppMetadataConfig>()
                                        ? GetIt.I<AppMetadataConfig>()
                                                .contactEmail ??
                                            ""
                                        : "";
                                if (contactEmail.isEmpty) return;
                                await launchUrl(
                                  Uri.parse(
                                    "mailto:$contactEmail?subject=Aide",
                                  ),
                                );
                              },
                            ),
                            SettingsNode(
                              leadingBuilder:
                                  (_) => _CircleGlyph(
                                    asset: 'assets/svg/share.svg',
                                  ),
                              title: 'package.settings.node.share.title'.tr(),
                              subtitle:
                                  'package.settings.node.share.subtitle'.tr(),
                              onTap: () async {
                                final String? message =
                                    GetIt.I.isRegistered<AppMetadataConfig>()
                                        ? GetIt.I<AppMetadataConfig>()
                                            .shareMessage
                                        : null;
                                await SharePlus.instance.share(
                                  ShareParams(
                                    text:
                                        message ??
                                        'package.settings.node.share.subtitle'
                                            .tr(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // Liens
                        SettingsItem(
                          title: 'package.settings.section-title.link'.tr(),
                          children: [
                            SettingsNode(
                              title:
                                  'package.settings.node.link.privacy-policy'
                                      .tr(),
                              contentBuilder:
                                  (context) => legalPaneContent(
                                    config?.confidentialityPolicy,
                                  ),
                            ),
                            SettingsNode(
                              title: 'package.settings.node.link.cgvu'.tr(),
                              contentBuilder:
                                  (context) => legalPaneContent(config?.cgvu),
                            ),
                            SettingsNode(
                              title:
                                  'package.settings.node.link.legal-notice'
                                      .tr(),
                              contentBuilder:
                                  (context) =>
                                      legalPaneContent(config?.legalNotice),
                            ),
                          ],
                        ),

                        // Réseaux sociaux
                        SettingsItem(
                          title: 'package.settings.section-title.social'.tr(),
                          children: [
                            SettingsNode(
                              title:
                                  'package.settings.node.social.facebook'.tr(),
                              icon: SvgPicture.asset('assets/svg/fb.svg'),
                              onTap: () async {
                                final String? url =
                                    GetIt.I.isRegistered<AppMetadataConfig>()
                                        ? GetIt.I<AppMetadataConfig>()
                                            .facebookUrl
                                        : null;
                                if (url != null) {
                                  await launchUrl(Uri.parse(url));
                                }
                              },
                            ),
                            SettingsNode(
                              title:
                                  'package.settings.node.social.instagram'.tr(),
                              icon: SvgPicture.asset('assets/svg/insta.svg'),
                              onTap: () async {
                                final String? url =
                                    GetIt.I.isRegistered<AppMetadataConfig>()
                                        ? GetIt.I<AppMetadataConfig>()
                                            .instagramUrl
                                        : null;
                                if (url != null) {
                                  await launchUrl(Uri.parse(url));
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userHeader(
    BuildContext context,
    String? imgUrl,
    dynamic user,
    WidgetRef ref,
  ) {
    final String teamName =
        ref.watch(coachProfileProvider).valueOrNull?.teamName?.trim() ?? '';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Identité de la carte : nom d'équipe + email, centrés (Figma).
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            sh(30),
            Text(
              teamName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(25, AppColor.primaryLabels),
            ),
            sh(6),
            Text(
              user?.email ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(
                14,
                AppColor.primaryLabels.withValues(alpha: .65),
              ),
            ),
            sh(14),
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(Iconsax.more, color: AppColor.primaryColor),
            onPressed: () async {
              final action = await showCupertinoModalPopup<String>(
                context: context,
                builder:
                    (context) => CupertinoActionSheet(
                      message: Text('utils.what-do-you-want-to-do'.tr()),
                      actions: [
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          child: Text('package.skeleton.profile.logout'.tr()),
                          onPressed: () => Navigator.of(context).pop('logout'),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        child: Text('utils.cancel'.tr()),
                        onPressed: () => Navigator.of(context).pop(null),
                      ),
                    ),
              );
              if (action == 'logout' && context.mounted) {
                // Logout unifié : passe par le skeleton (nettoie fcmToken +
                // config locale, invalide userProvider, redirige vers login),
                // au lieu d'un signOut brut qui contournait ce nettoyage.
                await UserController.logoutUser(context, ref);
              }
            },
          ),
        ),
      ],
    );
  }

}

/// Formulaire de changement d'email (réglages).
///
/// Widget dédié afin de posséder ses [TextEditingController] et de les libérer
/// (`dispose()`) à la fermeture du volet.
class _EditEmailForm extends StatefulWidget {
  const _EditEmailForm({required this.initialEmail});

  final String initialEmail;

  @override
  State<_EditEmailForm> createState() => _EditEmailFormState();
}

class _EditEmailFormState extends State<_EditEmailForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormClassicField(
                controller: _emailController,
                fieldName: 'package.field.auth.email.title'.tr(),
                hintText: 'package.field.auth.email.hint'.tr(),
                validator: AuthValidator.validEmail,
              ),
              sh(14),
              FormClassicField(
                controller: _passwordController,
                fieldName: 'package.field.auth.actual-password.title'.tr(),
                hintText: 'package.field.auth.actual-password.hint'.tr(),
                isSecretField: true,
                isRequired: true,
                validator: FieldValidator.fieldNotEmpty,
              ),
              sh(24),
              CpButton(
                label: 'utils.save'.tr(),
                onTap: () => _submitEmailChange(
                  context,
                  _emailController.text.trim(),
                  _passwordController.text,
                ),
              ),
              sh(12),
              const CpRequiredNote(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitEmailChange(
    BuildContext context,
    String newEmail,
    String currentPassword,
  ) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _toast(context, 'utils.error', 'package.kosmos-auth.user-not-found');
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      // Firebase Auth ne bascule sur la nouvelle adresse qu'après le clic sur
      // le lien reçu ; EmailSync recopie ensuite l'adresse dans Firestore.
      await user.verifyBeforeUpdateEmail(newEmail);
      if (!context.mounted) return;
      _toast(
        context,
        'utils.success',
        'package.kosmos-auth.success-change-email',
        type: AlertType.success,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      final messageKey =
          e.code == 'wrong-password'
              ? 'package.kosmos-auth.wrong-password'
              : e.code == 'invalid-email'
              ? 'package.kosmos-auth.invalid-email'
              : 'utils.error-default';
      _toast(context, 'utils.error', messageKey);
    } catch (_) {
      if (!context.mounted) return;
      _toast(context, 'utils.error', 'utils.error-default');
    }
  }

  void _toast(
    BuildContext context,
    String titleKey,
    String subtitleKey, {
    AlertType type = AlertType.error,
  }) {
    PopupAlert.toast(
      context,
      FToast().init(context),
      title: titleKey.tr(),
      subtitle: subtitleKey.tr(),
      type: type,
    );
  }
}
