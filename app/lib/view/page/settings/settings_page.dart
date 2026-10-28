import 'dart:async' show unawaited;

import 'package:kosmos_auth/kosmos_auth.dart' show KosmosAuth;
import 'package:wina/billing/access_info.dart';
import 'package:wina/config/legal_links.dart';
import 'package:wina/config/skeleton_config.dart' show kCloudRegion;
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/confirm_dialog.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/view/page/abonnement_screen.dart';
import 'package:wina/view/page/check_profil_step1_screen.dart';
import 'package:wina/view/page/mes_equipes_screen.dart';
import 'package:wina/view/page/mon_adjoint_screen.dart';
import 'package:wina/view/page/settings/settings_node.dart';
import 'package:wina/view/widget/custom_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
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
    final List<SettingsNode> socialNodes = _socialNodes();

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
                              subtitle:
                                  'package.settings.node.security.subtitle'
                                      .tr(),
                              onTap: () => _showSecurityDialog(context, ref),
                              children: [],
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

                        // Abonnement : seulement pour un compte propriétaire (un compte d'équipe liée
                        // n'a ni abonnement ni équipes à gérer).
                        if (ref.watch(accessInfoProvider).valueOrNull
                            case final AccessInfo access when !access.isLinked)
                          SettingsItem(
                            title: 'app.subscription.title'.tr(),
                            children: [
                              SettingsNode(
                                title: 'app.settings-extra.change-plan'.tr(),
                                subtitle:
                                    'app.settings-extra.change-plan-sub'.tr(),
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => const AbonnementScreen(
                                              changePlan: true,
                                            ),
                                      ),
                                    ),
                                children: [],
                              ),
                              SettingsNode(
                                title:
                                    'app.settings-extra.manage-subscription'
                                        .tr(),
                                subtitle:
                                    'app.settings-extra.manage-subscription-sub'
                                        .tr(),
                                onTap:
                                    () => launchUrl(
                                      Uri.parse(
                                        defaultTargetPlatform ==
                                                TargetPlatform.iOS
                                            ? 'https://apps.apple.com/account/subscriptions'
                                            : 'https://play.google.com/store/account/subscriptions',
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                children: [],
                              ),
                              SettingsNode(
                                title: 'app.settings-extra.my-teams'.tr(),
                                subtitle:
                                    'app.settings-extra.my-teams-sub'.tr(),
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => const MesEquipesScreen(),
                                      ),
                                    ),
                                children: [],
                              ),
                              SettingsNode(
                                title: 'app.assistant.title'.tr(),
                                subtitle: 'app.assistant.settings-sub'.tr(),
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => const MonAdjointScreen(),
                                      ),
                                    ),
                                children: [],
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
                              onTap: () => openLegalLink(context, kPrivacyUri),
                            ),
                            SettingsNode(
                              title: 'package.settings.node.link.cgvu'.tr(),
                              onTap: () => openLegalLink(context, kCguUri),
                            ),
                            SettingsNode(
                              title:
                                  'package.settings.node.link.legal-notice'
                                      .tr(),
                              onTap: () => openLegalLink(context, kLegalNoticeUri),
                            ),
                          ],
                        ),

                        // Réseaux sociaux : un réseau sans adresse dans
                        // `app_config/metadata` est masqué, la section aussi
                        // quand aucun n'est configuré.
                        if (socialNodes.isNotEmpty)
                          SettingsItem(
                            title: 'package.settings.section-title.social'.tr(),
                            children: socialNodes,
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
            // Déconnexion et suppression du compte visibles d'emblée, en petits
            // boutons discrets (le menu « ⋯ » reste disponible).
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                _AccountActionButton(
                  icon: Iconsax.logout,
                  label: 'package.skeleton.profile.logout'.tr(),
                  color: AppColor.primaryColor,
                  onTap: () => UserController.logoutUser(context, ref),
                ),
                _AccountActionButton(
                  icon: Iconsax.trash,
                  label: 'account.delete.action'.tr(),
                  color: AppColor.destructive,
                  onTap: () => _confirmAndDeleteAccount(context, ref),
                ),
              ],
            ),
            sh(8),
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
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          child: Text('account.delete.action'.tr()),
                          onPressed: () => Navigator.of(context).pop('delete'),
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
              if (action == 'delete' && context.mounted) {
                await _confirmAndDeleteAccount(context, ref);
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Petit bouton en pastille de la carte de profil (déconnexion, suppression du compte) :
/// contour fin, texte de 12 px, volontairement discret.
class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: .55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppThemeStyle.semiBStyle(12, color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Réseaux sociaux de l'app, dans l'ordre d'affichage : Instagram, TikTok, YouTube, Facebook, LinkedIn.
///
/// Les adresses viennent de `app_config/metadata` (champs `instagramUrl`, `tiktokUrl`, `youtubeUrl`,
/// `facebookUrl`, `linkedinUrl`). Les cinq réseaux sont toujours listés ; tant que l'adresse d'un compte
/// n'est pas renseignée, son entrée est affichée mais n'ouvre rien.
List<SettingsNode> _socialNodes() {
  final AppMetadataConfig? config =
      GetIt.I.isRegistered<AppMetadataConfig>()
          ? GetIt.I<AppMetadataConfig>()
          : null;

  SettingsNode node(String key, String? url, Widget icon) {
    final String? target = url?.trim();
    return SettingsNode(
      title: 'package.settings.node.social.$key'.tr(),
      icon: icon,
      onTap: () async {
        // Compte pas encore renseigné : l'entrée est visible, sans destination.
        if (target == null || target.isEmpty) return;
        try {
          await launchUrl(
            Uri.parse(target),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          // Adresse invalide ou aucune application pour l'ouvrir : on reste sur la page.
        }
      },
    );
  }

  return <SettingsNode>[
    node(
      'instagram',
      config?.instagramUrl,
      SvgPicture.asset('assets/svg/insta.svg'),
    ),
    node(
      'tiktok',
      config?.tiktokUrl,
      SvgPicture.asset('assets/svg/tiktok.svg'),
    ),
    node(
      'youtube',
      config?.youtubeUrl,
      SvgPicture.asset('assets/svg/youtube.svg'),
    ),
    node(
      'facebook',
      config?.facebookUrl,
      SvgPicture.asset('assets/svg/fb.svg'),
    ),
    node(
      'linkedin',
      config?.linkedinUrl,
      Image.asset('assets/images/img_linkedin.png', fit: BoxFit.cover),
    ),
  ];
}

/// Suppression du compte depuis l'app, pour tous les types de connexion (e-mail,
/// Google...) : Google Play et l'App Store exigent qu'elle soit possible sans quitter l'app.
///
/// Le serveur (callable `deleteAccount`) agit sur le compte de l'appelant : profil, effectif, matchs,
/// compositions et compte d'authentification. Aucune ressaisie du mot de passe n'est donc demandée,
/// ce qui sert aussi les comptes Google, qui n'en ont pas.
Future<void> _confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    barrierColor: AppColor.scrim,
    builder:
        (BuildContext ctx) => AppConfirmDialog(
          title: 'account.delete.title'.tr(),
          message: 'account.delete.message'.tr(),
          primaryLabel: 'account.delete.keep'.tr(),
          onPrimary: () => Navigator.of(ctx).pop(false),
          secondaryLabel: 'account.delete.confirm'.tr(),
          secondaryAccent: AppColor.destructive,
          onSecondary: () => Navigator.of(ctx).pop(true),
        ),
  );
  if (confirmed != true || !context.mounted) return;

  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Chargement bloquant : la suppression passe par le réseau et ne doit pas être relancée.
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColor.scrim,
      builder:
          (_) => const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          ),
    ),
  );

  final result = await KosmosAuth.deleteAccount(user.uid, region: kCloudRegion);
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  final bool deleted = result.fold((_) => false, (ok) => ok);
  if (!deleted) {
    PopupAlert.toast(
      context,
      FToast().init(context),
      title: 'utils.error'.tr(),
      subtitle: 'account.delete.error'.tr(),
      type: AlertType.error,
    );
    return;
  }

  // Le compte n'existe plus côté serveur : on nettoie la session locale sans redirection automatique,
  // puis on ouvre l'écran de connexion avec le message « Votre compte a été supprimé ».
  await UserController.logoutUser(context, ref, false, true);
  if (!context.mounted) return;
  final router = AutoRouter.of(context);
  router.popUntilRoot();
  router.replaceNamed('/auth/login?logout=true&deleteAccount=true');
}

/// Formulaire de changement d'email (réglages).
///
/// Widget dédié afin de posséder ses [TextEditingController] et de les libérer
/// (`dispose()`) à la fermeture du volet.
class _EditEmailForm extends StatefulWidget {
  const _EditEmailForm({required this.initialEmail, this.onDone});

  final String initialEmail;

  /// Appelé après l'envoi réussi du lien de confirmation (ferme la fenêtre).
  final VoidCallback? onDone;

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
                onTap:
                    () => _submitEmailChange(
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
      widget.onDone?.call();
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

/// Fenêtre de réglage : carte arrondie, titre, croix de fermeture et contenu défilable.
Future<void> _showSettingsDialog(
  BuildContext context,
  String title,
  Widget Function(BuildContext dialogContext) content,
) {
  return showDialog<void>(
    context: context,
    builder:
        (BuildContext ctx) => Dialog(
          backgroundColor: AppColor.surface,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          style: AppThemeStyle.semiBStyle(
                            20,
                            AppColor.primaryLabels,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                        color: AppColor.primaryLabels,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  content(ctx),
                ],
              ),
            ),
          ),
        ),
  );
}

/// Changement de mot de passe : mot de passe actuel (ré-authentification), nouveau, confirmation.
Future<void> _showChangePasswordDialog(BuildContext context) {
  return _showSettingsDialog(
    context,
    'package.settings.node.change-password.title'.tr(),
    (BuildContext ctx) =>
        ChangePasswordForm(onSuccess: () => Navigator.of(ctx).pop()),
  );
}

/// Changement d'adresse e-mail : nouvelle adresse et mot de passe actuel.
Future<void> _showChangeEmailDialog(BuildContext context, String currentEmail) {
  return _showSettingsDialog(
    context,
    'package.settings.node.change-email.title'.tr(),
    (BuildContext ctx) => _EditEmailForm(
      initialEmail: currentEmail,
      onDone: () => Navigator.of(ctx).pop(),
    ),
  );
}

/// Sécurité : choix entre l'adresse e-mail et le mot de passe, chacun dans sa propre fenêtre.
Future<void> _showSecurityDialog(BuildContext context, WidgetRef ref) {
  final String email = ref.read(userProvider).user?.email ?? '';
  Widget choice(
    BuildContext ctx,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      title,
      style: AppThemeStyle.semiBStyle(16, AppColor.primaryLabels),
    ),
    subtitle:
        subtitle.isEmpty
            ? null
            : Text(
              subtitle,
              style: AppThemeStyle.regularStyle(13, AppColor.secondaryLabels),
            ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      Navigator.of(ctx).pop();
      onTap();
    },
  );
  return _showSettingsDialog(
    context,
    'package.settings.node.security.title'.tr(),
    (BuildContext ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        choice(
          ctx,
          'package.settings.node.change-email.title'.tr(),
          email,
          () => _showChangeEmailDialog(context, email),
        ),
        const Divider(height: 1),
        choice(
          ctx,
          'package.settings.node.change-password.title'.tr(),
          '',
          () => _showChangePasswordDialog(context),
        ),
      ],
    ),
  );
}
