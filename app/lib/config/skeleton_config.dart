import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/routes/app_router.gr.dart';
import 'package:wina/view/page/check_profil_step1_screen.dart';
import 'package:flutter/widgets.dart';

import 'package:skeleton/controller/user_controller.dart';
import 'package:skeleton/skeleton.dart';
import 'package:wina/view/page/reset_password_code_page.dart';
import 'package:wina/view/widget/social_sign_in_ui.dart';

/// Région où les Cloud Functions du projet sont déployées.
/// `FirebaseFunctions.instance` viserait `us-central1`, où rien ne tourne.
const String kCloudRegion = 'europe-west9';

/// Domaine des adresses techniques des comptes d'équipe liés : l'identifiant saisi à la connexion devient
/// `<identifiant>@equipes.wina.invalid` (même valeur que LINKED_EMAIL_DOMAIN côté serveur).
const String kLinkedEmailDomain = 'equipes.wina.invalid';

SkeletonAppConfig initSkeletonAppConfig() {
  return SkeletonAppConfig(
    cloudRegion: kCloudRegion,
    logoPath: "assets/images/app_logo.png",
    logoFormat: LogoFormat.png,
    mainRouteInfo: const LoggedUserAppCoreRoute(),
    authentificationConfig: SkeletonAuthentificationConfig(
      userType: "client",
      // Les comptes d'équipe liés se connectent par identifiant (sans « @ »).
      identifierEmailDomain: kLinkedEmailDomain,
      // Connexion biométrique désactivée : l'app ne propose pas de l'activer, la connexion
      // se fait par e-mail et mot de passe.
      enableLocalAuth: false,
      registerFirst: false,
      // Inscription libre : le lien « Créer maintenant » de la connexion ouvre
      // RegisterPage (page 1), puis la passerelle ouvre « Finalisez votre profil »
      // (page 2). On n'utilise pas la page de création du socle.
      canCreateAccount: true,
      createAccountRoute: '/auth/register',
      showBackButton: false,
      // Tant que `profilCompleted` est faux, la passerelle skeleton appelle ce
      // callback : on ouvre l'écran « Finalisez votre profil » (étape 1). Le
      // retour non-null court-circuite la redirection par défaut.
      showCompleteProfil: (context, user) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CheckProfilStep1Screen(),
          ),
        );
        return 'check-profil';
      },
      // Wordmark au-dessus de la carte. C'est le seul point d'insertion vivant
      // sur le chemin tablette (`LoginPage._buildWeb`) : `showLogoOnPage` et
      // `logoPath` ne sont lus que par la branche téléphone d'`AuthParent`.
      webLoginPageTitleBuilder:
          (BuildContext context, WidgetRef ref) => Padding(
            padding: EdgeInsets.only(bottom: formatHeight(28)),
            child: SvgPicture.asset(
              "assets/svg/logo_inline.svg",
              width: sp(88),
            ),
          ),
      // Contenu du CTA « Connexion » : le `Button` Kosmos n'a pas d'emplacement
      // d'icône, seul ce crochet permet d'y poser la pastille fléchée de la
      // maquette. Le bouton garde sa pilule verte, son loader et son mutex.
      loginButtonBuilder:
          (BuildContext context, WidgetRef ref) => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "utils.connexion".tr(),
                style: AppThemeStyle.semiBStyle(16, AppColor.textLight),
              ),
              sw(7),
              SizedBox(
                width: sp(22),
                height: sp(22),
                child: Icon(
                  Iconsax.arrow_circle_right,
                  size: sp(13),
                  color: AppColor.textLight,
                ),
              ),
            ],
          ),
      // « Mot de passe oublié » : le code part par e-mail, l'écran suivant le demande
      // avec le nouveau mot de passe (au lieu d'un lien à ouvrir).
      onResetPasswordCodeSent: (BuildContext context, String email) async {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ResetPasswordCodePage(email: email.trim()),
          ),
        );
      },
      showLogoOnPage: false,
      emailMustBeVerified: false,
      sendEmailVerificationIfNotVerified: false,
      canLoginWithPhone: false,
      // Google (partout) et Apple (iOS) : la connexion et la création de la fiche
      // coach passent par SocialSignIn (la fiche est écrite par le serveur).
      authTiers: availableSocialTiers(),
      tiersSignIn: (BuildContext context, WidgetRef ref, AuthTiers tiers) =>
          runSocialSignIn(context, tiers),
      logoutCallback: (BuildContext context, WidgetRef ref) async {
        await UserController.logoutUser(context, ref);
      },
    ),
  );
}
