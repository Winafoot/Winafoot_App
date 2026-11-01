// =============================================================================
// Configuration des paramètres (paquet settings_kosmos)
// =============================================================================
//
// PACKAGE: kosmos_settings
// CLÉ DE CONFIGURATION: "kosmos-settings" → KosmosSettingsConfig
//
// ⚠️ ATTENTION: La classe déclare super("Kosmos-Settings") mais doit être
// récupérée avec la clé "kosmos-settings" (minuscule).
//
// CLÉS DE THÈME:
//   - "kosmos-settings" → KosmosSettingsThemeData (page principale)
//   - "settings_cellule" → SettingsCelluleThemeData (cellules individuelles)
//
// PAGES UTILISANT CETTE CONFIG:
//   - SettingsPage : Page principale des paramètres (skeleton/view/page/profile/settings_page.dart)
//   - SettingsSubPage : Sous-pages de paramètres (navigation dans les sections)
//
// ROUTES RECOMMANDÉES:
//   AutoRoute(path: "profile/settings", page: SettingsPage),
//   AutoRoute(path: "profile/settings/:section", page: SettingsSubPage),
//
// =============================================================================
// STRUCTURE DES SETTINGS:
//
// KosmosSettingsConfig
// └── settingsSection: List<CelluleSection>
//     └── CelluleSection (ex: "Mon Compte")
//         ├── title: String (titre de la section)
//         └── cellules: List<CelluleModel>
//             └── CelluleModel (ex: "Données personnelles")
//                 ├── tag: String (identifiant unique)
//                 ├── type: CelluleType (tile, switcher, dropdown)
//                 ├── tileBuilder: Widget Function (titre)
//                 ├── subTitleBuilder: Widget Function (sous-titre)
//                 ├── prefixBuilder/prefixSvgPath: icône gauche
//                 ├── onTap: action au clic
//                 ├── onSwitch: action pour switcher
//                 └── sectionChild: CelluleSection? (sous-section)
//
// TYPES DE CELLULES (CelluleType):
//   - tile: Cellule cliquable standard avec flèche droite
//   - switcher: Cellule avec switch on/off
//   - dropdown: Cellule avec menu déroulant
//
// =============================================================================
// THÈMES:
//
// KosmosSettingsThemeData: Style de la page settings
//   - backgroundColor, appBarColor
//   - titleStyle, sectionTitleStyle
//   - logoutButtonStyle, deleteAccountButtonStyle
//
// SettingsCelluleThemeData: Style des cellules
//   - tileStyle, subTitleStyle
//   - backgroundColor, borderRadius
//   - prefixSize, suffixIcon
//   - switchActiveColor, switchInactiveColor
//
// =============================================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skeleton/skeleton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wina/billing/access_info.dart';
import 'package:wina/config/legal_links.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/view/page/abonnement_screen.dart';
import 'package:wina/view/page/mes_equipes_screen.dart';
import 'package:wina/view/widget/app_notif.dart';

// =============================================================================
// SIGN-IN TYPE DETECTION
// =============================================================================

enum SignInType {
  emailPassword,
  google,
  apple,
  facebook,
  anonymous,
  none,
  unknown,
}

SignInType getCurrentUserSignInType() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return SignInType.none;
  }

  if (user.isAnonymous) {
    return SignInType.anonymous;
  }

  final providers = user.providerData.map((p) => p.providerId).toList();

  if (providers.contains('password')) {
    return SignInType.emailPassword;
  }
  if (providers.contains('google.com')) {
    return SignInType.google;
  }
  if (providers.contains('apple.com')) {
    return SignInType.apple;
  }
  if (providers.contains('facebook.com')) {
    return SignInType.facebook;
  }

  return SignInType.unknown;
}

bool isSocialLogin() {
  final type = getCurrentUserSignInType();
  return type == SignInType.google ||
      type == SignInType.apple ||
      type == SignInType.facebook;
}

// =============================================================================
// LIENS EXTERNES (métadonnées distantes + ouverture protégée)
// =============================================================================

/// Lit une métadonnée de l'app, ou `null` si l'[AppMetadataConfig] n'est pas
/// enregistrée ou si la valeur est vide.
///
/// Sert à masquer les entrées de settings qui n'ont pas de destination.
String? _appMetadata(String? Function(AppMetadataConfig config) getter) {
  if (!GetIt.I.isRegistered<AppMetadataConfig>()) return null;
  final String? value = getter(GetIt.I<AppMetadataConfig>());
  return (value == null || value.isEmpty) ? null : value;
}

/// Vrai si au moins une URL de réseau social est configurée.
bool _hasSocialUrl() =>
    _appMetadata((c) => c.facebookUrl) != null ||
    _appMetadata((c) => c.instagramUrl) != null ||
    _appMetadata((c) => c.tiktokUrl) != null ||
    _appMetadata((c) => c.twitterUrl) != null ||
    _appMetadata((c) => c.linkedinUrl) != null ||
    _appMetadata((c) => c.snapchatUrl) != null;

/// Ouvre [uri] et prévient l'utilisateur si aucune application ne peut la gérer.
///
/// Nécessaire car `launchUrl` renvoie `false` ou lève une exception selon la
/// plateforme : sur Android 11+, la visibilité de paquets empêche la résolution
/// de l'intent si le schéma n'est pas déclaré dans `<queries>` (AndroidManifest).
Future<void> _launchOrNotify(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri)) return;
  } catch (_) {
    // Aucune application installée ne gère ce lien : on tombe sur la notif.
  }
  if (!context.mounted) return;
  showAppNotif(
    context,
    title: "utils.error".tr(),
    subTitle: "utils.error-default".tr(),
    success: false,
  );
}

/// Vrai pour un compte propriétaire (accès chargé et non lié à un propriétaire) : les comptes d'équipe
/// liée n'ont ni abonnement ni équipes à gérer.
bool _isOwner(WidgetRef ref) {
  final AccessInfo? info = ref.watch(accessInfoProvider).valueOrNull;
  return info != null && !info.isLinked;
}

/// Restaure les achats du store et prévient l'utilisateur du résultat.
Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
  bool found = false;
  try {
    found = await ref.read(billingServiceProvider).restore();
  } catch (_) {
    if (!context.mounted) return;
    showAppNotif(
      context,
      title: "utils.error".tr(),
      subTitle: "utils.error-default".tr(),
      success: false,
    );
    return;
  }
  if (!context.mounted) return;
  showAppNotif(
    context,
    title:
        found
            ? "app.settings-extra.restore".tr()
            : "app.subscription.restore-none".tr(),
  );
}

/// Initialise la configuration des paramètres de l'application.
///
/// Cette fonction définit toute la structure de navigation des settings:
/// - Sections principales (Mon Compte, Paramètres, Autres, Liens, Réseaux sociaux)
/// - Cellules dans chaque section (avec titre, sous-titre, icône, action)
/// - Sous-sections imbriquées (ex: Sécurité > Changer email, Changer mot de passe)
///
/// 📍 UTILISÉ DANS: SettingsPage via `getAppModel().dependencies.packages["kosmos-settings"]`
///
KosmosSettingsConfig initKosmosSettingsConfig() {
  return KosmosSettingsConfig(
    settingsSection:
        (ref) => <CelluleSection>[
          /// Section "Mon Compte"
          CelluleSection(
            title:
                (_, __) => "package.settings.section-title.personnal-data".tr(),
            cellules: <CelluleModel>[
              /// Node "Données personnelles" + son image de profil
              CelluleModel(
                tag: "personnal-data",
                tileBuilder:
                    (_, ref) =>
                        "${ref.watch(userProvider).user?.firstname ?? ""} ${ref.watch(userProvider).user?.lastname ?? ""}",
                subTitleBuilder:
                    (_, ref) => ref.watch(userProvider).user?.email ?? "",
                onTap: (_, __) {
                  return;
                },
                prefixBuilder:
                    (_, ref) =>
                        ref
                                        .watch(userProvider)
                                        .user
                                        ?.userProfileImage
                                        ?.compressedUrl !=
                                    null ||
                                ref
                                        .watch(userProvider)
                                        .user
                                        ?.userProfileImage
                                        ?.url !=
                                    null
                            ? CachedNetworkImage(
                              imageUrl:
                                  ref
                                      .watch(userProvider)
                                      .user
                                      ?.userProfileImage
                                      ?.compressedUrl ??
                                  ref
                                      .watch(userProvider)
                                      .user
                                      ?.userProfileImage
                                      ?.url ??
                                  "",
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => Image.asset(
                                    "assets/images/img_user_profil.png",
                                  ),
                            )
                            : const SizedBox(),
                sectionChild: CelluleSection(
                  title:
                      (_, __) => "package.settings.section-title.modify".tr(),
                  cellules: [
                    /// Node "Informations personnelles"
                    CelluleModel(
                      tag: "personnal-content",
                      onTap: (context, __) {
                        AutoRouter.of(
                          context,
                        ).pushNamed("app/profile/modify/personnal-content");
                        return null;
                      },
                      tileBuilder:
                          (_, __) =>
                              "package.settings.node.change-personnal-content.title"
                                  .tr(),
                      subTitleBuilder:
                          (_, ref) =>
                              "package.settings.node.change-personnal-content.subtitle"
                                  .tr(),
                    ),

                    /// Node "Utilisateurs bloqués"
                    CelluleModel(
                      tag: "blocked-users",
                      onTap: (context, __) {
                        AutoRouter.of(
                          context,
                        ).pushNamed("app/profile/user-info/bloqued-users");
                        return null;
                      },
                      tileBuilder:
                          (_, __) =>
                              "package.settings.node.blocked-users.title".tr(),
                      subTitleBuilder:
                          (_, ref) =>
                              "package.settings.node.blocked-users.subtitle"
                                  .tr(),
                    ),
                  ],
                ),
              ),

              /// Node "Sécurité"
              CelluleModel(
                tag: "personnal-security",
                onTap: (_, __) => null,
                tileBuilder:
                    (_, __) => "package.settings.node.security.title".tr(),
                subTitleBuilder:
                    (_, __) => "package.settings.node.security.subtitle".tr(),
                prefixSvgPath: "assets/svg/ic_security.svg",
                sectionChild: CelluleSection(
                  title:
                      (_, __) => "package.settings.section-title.security".tr(),
                  cellules: [
                    /// Node "Changer de mot de passe" (masqué si social login)
                    if (!isSocialLogin())
                      CelluleModel(
                        tag: "security-change-password",
                        onTap: (context, __) {
                          AutoRouter.of(
                            context,
                          ).pushNamed("app/profile/security/password");
                          return null;
                        },
                        tileBuilder:
                            (_, __) =>
                                "package.settings.node.change-password.title"
                                    .tr(),
                        subTitleBuilder:
                            (_, ref) =>
                                ref
                                            .watch(userProvider)
                                            .securityMetadata
                                            ?.lastPasswordUpdate !=
                                        null
                                    ? "package.settings.node.change-password.subtitle"
                                        .tr(
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
                      ),

                    /// Node "Numéro de téléphone"
                    CelluleModel(
                      tag: "security-phone-number",
                      onTap: (context, __) {
                        AutoRouter.of(
                          context,
                        ).pushNamed("app/profile/security/phone-number");
                        return null;
                      },
                      tileBuilder:
                          (_, __) =>
                              "package.settings.node.phone-number.title".tr(),
                      subTitleBuilder:
                          (_, ref) => ref.watch(userProvider).user?.phone ?? "",
                    ),
                  ],
                ),
              ),

              /// Node "Moyens de paiement"
              // CelluleModel(
              //   tag: "personnal-payment",
              //   onTap: (_, __) {},
              //   tileBuilder: (_, __) => "package.settings.node.payment.title".tr(),
              //   subTitleBuilder: (_, __) => "package.settings.node.payment.subtitle".tr(),
              //   prefixSvgPath: "assets/svg/ic_payment.svg",
              // ),
            ],
          ),

          /// Section "Abonnement" : uniquement pour un compte propriétaire (pas un compte d'équipe liée).
          if (_isOwner(ref))
            CelluleSection(
              title: (_, __) => "app.subscription.title".tr(),
              cellules: <CelluleModel>[
                /// Node "Mes équipes"
                CelluleModel(
                  tag: "my-teams",
                  onTap: (context, __) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MesEquipesScreen(),
                      ),
                    );
                    return null;
                  },
                  tileBuilder: (_, __) => "app.settings-extra.my-teams".tr(),
                  subTitleBuilder:
                      (_, __) => "app.settings-extra.my-teams-sub".tr(),
                ),

                /// Node "Changer de formule" : plus ou moins d'équipes, effet immédiat (hausse) ou au renouvellement (baisse)
                CelluleModel(
                  tag: "change-plan",
                  onTap: (context, __) async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => const AbonnementScreen(changePlan: true),
                      ),
                    );
                    return null;
                  },
                  tileBuilder: (_, __) => "app.settings-extra.change-plan".tr(),
                  subTitleBuilder:
                      (_, __) => "app.settings-extra.change-plan-sub".tr(),
                ),

                /// Node "Gérer mon abonnement" (page de gestion du store)
                CelluleModel(
                  tag: "manage-subscription",
                  onTap: (context, __) async {
                    final String url =
                        defaultTargetPlatform == TargetPlatform.iOS
                            ? "https://apps.apple.com/account/subscriptions"
                            : "https://play.google.com/store/account/subscriptions";
                    await _launchOrNotify(context, Uri.parse(url));
                    return null;
                  },
                  tileBuilder:
                      (_, __) => "app.settings-extra.manage-subscription".tr(),
                  subTitleBuilder:
                      (_, __) =>
                          "app.settings-extra.manage-subscription-sub".tr(),
                ),

                /// Node "Restaurer mes achats"
                CelluleModel(
                  tag: "restore-purchases",
                  onTap: (context, ref) async {
                    await _restorePurchases(context, ref);
                    return null;
                  },
                  tileBuilder: (_, __) => "app.settings-extra.restore".tr(),
                ),
              ],
            ),

          /// Section "Paramètres"
          CelluleSection(
            title: (_, __) => "package.settings.section-title.settings".tr(),
            cellules: <CelluleModel>[
              /// Node "Notification Push"
              CelluleModel(
                tag: "settings-push-notif",
                type: CelluleType.switcher,
                tileBuilder:
                    (_, __) => "package.settings.node.push-notif.title".tr(),
                initialSwitchValue:
                    (_, ref) =>
                        ref
                            .watch(userProvider)
                            .metadata
                            ?.enablePushNotification ??
                        false,
                onSwitch:
                    (ctx, r, newVal) async =>
                        await NotifPermissionController.setPushNotificationPermission(
                          ctx,
                          r,
                          newVal,
                          FirebaseAuth.instance.currentUser!.uid,
                        ),
                subTitleBuilder:
                    (_, ref) =>
                        (ref
                                    .watch(userProvider)
                                    .metadata
                                    ?.enablePushNotification ??
                                false)
                            ? "utils.activate".tr()
                            : "utils.deactivate".tr(),
                prefixSvgPath: "assets/svg/ic_notif.svg",
              ),

              /// Node "Notification Email"
              CelluleModel(
                tag: "settings-email-notif",
                type: CelluleType.switcher,
                tileBuilder:
                    (_, __) => "package.settings.node.email-notif.title".tr(),
                initialSwitchValue:
                    (_, ref) =>
                        ref
                            .watch(userProvider)
                            .metadata
                            ?.enableEmailNotification ??
                        false,
                onSwitch:
                    (_, __, newVal) async =>
                        await NotifPermissionController.setEmailNotificationPermission(
                          newVal,
                          FirebaseAuth.instance.currentUser!.uid,
                        ),
                subTitleBuilder:
                    (_, ref) =>
                        (ref
                                    .watch(userProvider)
                                    .metadata
                                    ?.enableEmailNotification ??
                                false)
                            ? "utils.activate".tr()
                            : "utils.deactivate".tr(),
                prefixSvgPath: "assets/svg/ic_notif.svg",
              ),
            ],
          ),

          /// Section "Autres"
          CelluleSection(
            title: (_, __) => "package.settings.section-title.other".tr(),
            cellules: <CelluleModel>[
              /// Node "Aide" (masqué si aucun email de contact n'est configuré)
              if (_appMetadata((c) => c.contactEmail) != null)
                CelluleModel(
                  tag: "other-help",
                  onTap: (context, __) async {
                    final String? contactEmail = _appMetadata(
                      (c) => c.contactEmail,
                    );
                    if (contactEmail != null) {
                      await _launchOrNotify(
                        context,
                        Uri.parse("mailto:$contactEmail?subject=Aide&body="),
                      );
                    }
                    return null;
                  },
                  tileBuilder:
                      (_, __) => "package.settings.node.help.title".tr(),
                  subTitleBuilder:
                      (_, __) => "package.settings.node.help.subtitle".tr(),
                  prefixSvgPath: "assets/svg/help.svg",
                ),

              /// Node "Partager l'app"
              CelluleModel(
                tag: "other-share",
                // Cellule non affichée : l'écran de réglages de l'app a son propre bouton de partage.
                onTap: (_, __) => null,
                tileBuilder:
                    (_, __) => "package.settings.node.share.title".tr(),
                subTitleBuilder:
                    (_, __) => "package.settings.node.share.subtitle".tr(),
                prefixSvgPath: "assets/svg/share.svg",
              ),
            ],
          ),

          /// Section "Liens"
          CelluleSection(
            title: (_, __) => "package.settings.section-title.link".tr(),
            cellules: <CelluleModel>[
              /// Node "Politique de confidentialité"
              CelluleModel(
                tag: "link-policy",
                onTap: (context, __) async {
                  await openLegalLink(context, kPrivacyUri);
                  return null;
                },
                tileBuilder:
                    (_, __) => "package.settings.node.link.privacy-policy".tr(),
              ),

              /// Node "CGVU"
              CelluleModel(
                tag: "link-cgvu",
                onTap: (context, __) async {
                  await openLegalLink(context, kCguUri);
                  return null;
                },
                tileBuilder: (_, __) => "package.settings.node.link.cgvu".tr(),
              ),

              /// Node "Mentions légales"
              CelluleModel(
                tag: "link-legale-mention",
                onTap: (context, __) async {
                  await openLegalLink(context, kLegalNoticeUri);
                  return null;
                },
                tileBuilder:
                    (_, __) => "package.settings.node.link.legal-mention".tr(),
              ),

              /// Node "À Propos"
              CelluleModel(
                tag: "link-about",
                onTap: (context, __) {
                  AutoRouter.of(context).pushNamed("legal-information/about");
                  return null;
                },
                tileBuilder: (_, __) => "package.settings.node.link.about".tr(),
              ),
            ],
          ),

          /// Section "Réseaux sociaux" (masquée si aucune URL n'est configurée)
          if (_hasSocialUrl())
            CelluleSection(
              title: (_, __) => "package.settings.section-title.social".tr(),
              cellules: <CelluleModel>[
                /// Node "Notre page Facebook"
                if (_appMetadata((c) => c.facebookUrl) != null)
                  CelluleModel(
                    tag: "social-facebook",
                    onTap: (context, __) async {
                      final String? url = _appMetadata((c) => c.facebookUrl);
                      if (url != null) {
                        await _launchOrNotify(context, Uri.parse(url));
                      }
                      return null;
                    },
                    tileBuilder:
                        (_, __) => "package.settings.node.social.facebook".tr(),
                    prefixBuilder:
                        (_, __) => SvgPicture.asset(
                          "assets/svg/fb.svg",
                          fit: BoxFit.cover,
                        ),
                  ),

                /// Node "Notre page Instagram"
                if (_appMetadata((c) => c.instagramUrl) != null)
                  CelluleModel(
                    tag: "social-instagram",
                    onTap: (context, __) async {
                      final String? url = _appMetadata((c) => c.instagramUrl);
                      if (url != null) {
                        await _launchOrNotify(context, Uri.parse(url));
                      }
                      return null;
                    },
                    tileBuilder:
                        (_, __) =>
                            "package.settings.node.social.instagram".tr(),
                    prefixBuilder:
                        (_, __) => SvgPicture.asset(
                          "assets/svg/insta.svg",
                          fit: BoxFit.cover,
                        ),
                  ),

                /// Node "Notre page TikTok"
                if (_appMetadata((c) => c.tiktokUrl) != null)
                  CelluleModel(
                    tag: "social-tiktok",
                    onTap: (context, __) async {
                      final String? url = _appMetadata((c) => c.tiktokUrl);
                      if (url != null) {
                        await _launchOrNotify(context, Uri.parse(url));
                      }
                      return null;
                    },
                    tileBuilder:
                        (_, __) => "package.settings.node.social.tiktok".tr(),
                    prefixBuilder:
                        (_, __) => SvgPicture.asset(
                          "assets/svg/tiktok.svg",
                          fit: BoxFit.cover,
                        ),
                  ),

                /// Node "Notre page twitter"
                if (_appMetadata((c) => c.twitterUrl) != null)
                  CelluleModel(
                    tag: "social-twitter",
                    onTap: (context, __) async {
                      final String? url = _appMetadata((c) => c.twitterUrl);
                      if (url != null) {
                        await _launchOrNotify(context, Uri.parse(url));
                      }
                      return null;
                    },
                    tileBuilder:
                        (_, __) => "package.settings.node.social.twitter".tr(),
                    prefixBuilder:
                        (_, __) => SvgPicture.asset(
                          "assets/svg/twitter.svg",
                          fit: BoxFit.cover,
                        ),
                  ),

                /// Node "Notre page linkedin"
                if (_appMetadata((c) => c.linkedinUrl) != null)
                  CelluleModel(
                    tag: "social-linkedin",
                    onTap: (context, __) async {
                      final String? url = _appMetadata((c) => c.linkedinUrl);
                      if (url != null) {
                        await _launchOrNotify(context, Uri.parse(url));
                      }
                      return null;
                    },
                    tileBuilder:
                        (_, __) => "package.settings.node.social.linkedin".tr(),
                    prefixBuilder:
                        (_, __) => Image.asset(
                          "assets/images/img_linkedin.png",
                          fit: BoxFit.cover,
                        ),
                  ),

                /// Node "Notre page snapchat"
                if (_appMetadata((c) => c.snapchatUrl) != null)
                  CelluleModel(
                    tag: "social-snapchat",
                    onTap: (context, __) async {
                      final String? url = _appMetadata((c) => c.snapchatUrl);
                      if (url != null) {
                        await _launchOrNotify(context, Uri.parse(url));
                      }
                      return null;
                    },
                    tileBuilder:
                        (_, __) => "package.settings.node.social.snapchat".tr(),
                    prefixBuilder:
                        (_, __) => SvgPicture.asset(
                          "assets/svg/snap.svg",
                          fit: BoxFit.cover,
                        ),
                  ),
              ],
            ),
        ],
  );
}
