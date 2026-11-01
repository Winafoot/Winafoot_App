import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kosmos_auth/kosmos_auth.dart' show KosmosAuth;
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/skeleton_config.dart' show kCloudRegion;
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/code_field.dart';

/// Confirmation de l'adresse e-mail par code : le coach saisit les 6 chiffres
/// reçus après son inscription (callable `verifyEmailCode`).
///
/// Se ferme avec `true` quand l'adresse est vérifiée, `false` si le coach choisit
/// « Plus tard » : l'app n'exige pas la vérification (`emailMustBeVerified`
/// vaut `false`), il peut la faire depuis un nouvel envoi plus tard.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.email});

  /// Adresse à laquelle le code a été envoyé (affichée seulement).
  final String email;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final TextEditingController _code = TextEditingController();
  bool _busy = false;
  bool _error = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String code = _code.text.trim();
    if (code.length != kEmailCodeLength) {
      setState(() => _error = true);
      showAppNotif(
        context,
        title: 'Code incomplet',
        subTitle: 'Saisissez les $kEmailCodeLength chiffres reçus par e-mail.',
        success: false,
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = false;
    });
    final String? failure = (await KosmosAuth.verifyEmailCode(
      code,
      region: kCloudRegion,
    )).fold((String l) => l, (_) => null);
    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _busy = false;
        _error = true;
      });
      showAppNotif(
        context,
        title: 'Vérification impossible',
        subTitle: failure,
        success: false,
      );
      return;
    }

    showAppNotif(
      context,
      title: 'Adresse confirmée',
      subTitle: 'Merci, votre adresse e-mail est vérifiée.',
    );
    Navigator.of(context).pop(true);
  }

  Future<bool> _resend() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final bool sent = await KosmosAuth.sendEmailVerification(
      user.uid,
      region: kCloudRegion,
    );
    if (!mounted) return sent;
    showAppNotif(
      context,
      title: sent ? 'Code renvoyé' : 'Envoi impossible',
      subTitle:
          sent
              ? 'Un nouveau code vient d’être envoyé à ${widget.email}.'
              : 'Réessayez dans un instant.',
      success: sent,
    );
    return sent;
  }

  @override
  Widget build(BuildContext context) {
    return CheckProfilScaffold(
      title: 'Confirmez votre e-mail',
      portraitOnPhone: true,
      children: <Widget>[
        Text(
          'Nous avons envoyé un code à 6 chiffres à ${widget.email}. '
          'Saisissez-le ci-dessous pour confirmer votre adresse.',
          style: AppThemeStyle.regularStyle(cFs(13), AppColor.secondaryLabels),
        ),
        cSh(20),
        const CpLabel('Code de vérification'),
        cSh(8),
        CpCodeField(
          controller: _code,
          error: _error,
          autofocus: true,
          onChanged: (_) {
            if (_error) setState(() => _error = false);
          },
          onCompleted: (_) => _submit(),
        ),
        cSh(6),
        ResendCodeLink(onResend: _resend),
        cSh(18),
        CpButton(label: _busy ? 'Vérification…' : 'Valider', onTap: _submit),
        cSh(10),
        CpButton(
          label: 'Plus tard',
          soft: true,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
