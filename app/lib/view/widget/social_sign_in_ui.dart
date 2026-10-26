import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skeleton/skeleton.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/services/social_sign_in.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';

/// Fournisseurs proposés sur cet appareil : Google partout, Apple sur iOS
/// seulement (pas de configuration Apple côté Android).
List<AuthTiers> availableSocialTiers() {
  final bool ios = !kIsWeb && Platform.isIOS;
  return <AuthTiers>[AuthTiers.google, if (ios) AuthTiers.apple];
}

/// Connexion Google / Apple depuis un écran : demande les CGU à un nouveau coach
/// et affiche les erreurs. Renvoie `true` quand le coach est connecté.
Future<bool> runSocialSignIn(BuildContext context, AuthTiers tiers) async {
  final SocialProvider provider = switch (tiers) {
    AuthTiers.apple => SocialProvider.apple,
    _ => SocialProvider.google,
  };
  final SocialSignInResult result = await SocialSignIn.signIn(
    provider,
    askCgu: () => _askCgu(context),
  );
  if (!context.mounted) return result.isSignedIn;

  switch (result.outcome) {
    case SocialSignInOutcome.cancelled:
    case SocialSignInOutcome.signedIn:
    case SocialSignInOutcome.created:
      break;
    case SocialSignInOutcome.cguRefused:
      showAppNotif(
        context,
        title: 'Inscription annulée',
        subTitle:
            'Vous devez accepter les conditions générales d’utilisation '
            'pour créer un compte.',
        success: false,
      );
    case SocialSignInOutcome.failed:
      showAppNotif(
        context,
        title: 'Connexion impossible',
        subTitle: result.message ?? 'Une erreur est survenue, réessayez.',
        success: false,
      );
  }
  return result.isSignedIn;
}

Future<bool> _askCgu(BuildContext context) async {
  final bool? accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColor.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(cR(24))),
    ),
    builder: (_) => const _CguSheet(),
  );
  return accepted == true;
}

/// Acceptation des CGU d'un nouveau coach (première connexion Google / Apple).
class _CguSheet extends StatefulWidget {
  const _CguSheet();

  @override
  State<_CguSheet> createState() => _CguSheetState();
}

class _CguSheetState extends State<_CguSheet> {
  bool _accepted = false;
  late final TapGestureRecognizer _cguTap;

  @override
  void initState() {
    super.initState();
    _cguTap =
        TapGestureRecognizer()
          ..onTap =
              () => AutoRouter.of(context).pushNamed('legal-information/cgvu');
  }

  @override
  void dispose() {
    _cguTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppThemeStyle.regularStyle(
      cFs(13),
      AppColor.primaryLabels,
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(cW(24), cH(22), cW(24), cH(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Bienvenue !',
              style: AppThemeStyle.semiBStyle(cFs(18), AppColor.primaryLabels),
            ),
            cSh(8),
            Text(
              'Pour créer votre compte, acceptez nos conditions générales '
              'd’utilisation.',
              style: AppThemeStyle.regularStyle(
                cFs(13),
                AppColor.secondaryLabels,
              ),
            ),
            cSh(16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: cW(24),
                  height: cH(24),
                  child: Checkbox(
                    value: _accepted,
                    activeColor: AppColor.primaryColor,
                    side: BorderSide(color: AppColor.divider, width: 1.5),
                    onChanged: (bool? v) => setState(() => _accepted = v ?? false),
                  ),
                ),
                cSw(12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: cH(3)),
                    child: Text.rich(
                      TextSpan(
                        style: base,
                        children: <InlineSpan>[
                          const TextSpan(text: 'J’accepte les '),
                          TextSpan(
                            text: 'conditions générales d’utilisation',
                            recognizer: _cguTap,
                            style: base.copyWith(
                              color: AppColor.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            cSh(20),
            Opacity(
              opacity: _accepted ? 1 : .4,
              child: CpButton(
                label: 'Créer mon compte',
                onTap: () {
                  if (_accepted) Navigator.of(context).pop(true);
                },
              ),
            ),
            cSh(10),
            CpButton(
              label: 'Annuler',
              soft: true,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// « ou inscrivez-vous avec » + boutons Google / Apple, pour la page
/// d'inscription (la page de connexion utilise ceux du paquet skeleton).
class SocialSignInButtons extends StatefulWidget {
  const SocialSignInButtons({super.key, required this.onSignedIn});

  /// Appelé quand le coach est connecté (compte existant ou tout juste créé).
  final VoidCallback onSignedIn;

  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  bool _busy = false;

  Future<void> _tap(AuthTiers tiers) async {
    if (_busy) return;
    setState(() => _busy = true);
    final bool signedIn = await runSocialSignIn(context, tiers);
    if (!mounted) return;
    setState(() => _busy = false);
    if (signedIn) widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    final List<AuthTiers> tiers = availableSocialTiers();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Divider(color: AppColor.divider)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: cW(12)),
              child: Text(
                'ou inscrivez-vous avec',
                style: AppThemeStyle.regularStyle(
                  cFs(12),
                  AppColor.secondaryLabels,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColor.divider)),
          ],
        ),
        cSh(14),
        for (final AuthTiers t in tiers) ...<Widget>[
          _SocialButton(
            label: t == AuthTiers.apple ? 'Apple' : 'Google',
            svgAsset:
                t == AuthTiers.apple
                    ? 'assets/svg/apple.svg'
                    : 'assets/svg/google.svg',
            onTap: _busy ? null : () => _tap(t),
          ),
          if (t != tiers.last) cSh(10),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.svgAsset,
    required this.onTap,
  });

  final String label;
  final String svgAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(cR(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(999)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: cH(13)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cR(999)),
            border: Border.all(color: AppColor.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(svgAsset, height: cH(20)),
              cSw(10),
              Text(
                'Continuer avec $label',
                style: AppThemeStyle.semiBStyle(
                  cFs(14),
                  AppColor.primaryLabels,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
