import 'package:flutter/material.dart';
import 'package:kosmos_auth/kosmos_auth.dart' show KosmosAuth;
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/skeleton_config.dart' show kCloudRegion;
import 'package:wina/config/theme.dart';
import 'package:wina/services/register_validation.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/code_field.dart';

/// Fin de « Mot de passe oublié » : le coach saisit le code à 6 chiffres reçu par
/// e-mail (`sendResetPassword`) et choisit son nouveau mot de passe
/// (callable `confirmPasswordReset`). Se ferme avec `true` une fois le mot de
/// passe changé : il se reconnecte alors depuis la page de connexion.
class ResetPasswordCodePage extends StatefulWidget {
  const ResetPasswordCodePage({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordCodePage> createState() => _ResetPasswordCodePageState();
}

class _ResetPasswordCodePageState extends State<ResetPasswordCodePage> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();

  bool _busy = false;
  bool _submitted = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  bool get _codeInvalid => _code.text.trim().length != kEmailCodeLength;
  bool get _passwordInvalid =>
      RegisterValidation.passwordViolations(_password.text).isNotEmpty;
  bool get _confirmationInvalid => _confirmation.text != _password.text;

  void _revalidate() {
    if (_submitted) setState(() {});
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _submitted = true);

    if (_codeInvalid) {
      showAppNotif(
        context,
        title: 'Code incomplet',
        subTitle: 'Saisissez les $kEmailCodeLength chiffres reçus par e-mail.',
        success: false,
      );
      return;
    }
    if (_passwordInvalid) {
      final String missing =
          RegisterValidation.passwordViolations(_password.text).join(', ');
      showAppNotif(
        context,
        title: 'Mot de passe trop faible',
        subTitle: 'Le mot de passe doit contenir $missing.',
        success: false,
      );
      return;
    }
    if (_confirmationInvalid) {
      showAppNotif(
        context,
        title: 'Mots de passe différents',
        subTitle: 'Les deux mots de passe doivent être identiques.',
        success: false,
      );
      return;
    }

    setState(() => _busy = true);
    final String? failure = (await KosmosAuth.confirmPasswordReset(
      email: widget.email,
      code: _code.text.trim(),
      newPassword: _password.text,
      region: kCloudRegion,
    )).fold((String l) => l, (_) => null);
    if (!mounted) return;

    if (failure != null) {
      setState(() => _busy = false);
      showAppNotif(
        context,
        title: 'Réinitialisation impossible',
        subTitle: failure,
        success: false,
      );
      return;
    }

    showAppNotif(
      context,
      title: 'Mot de passe modifié',
      subTitle: 'Connectez-vous avec votre nouveau mot de passe.',
    );
    Navigator.of(context).pop(true);
  }

  Future<bool> _resend() async {
    final bool sent = (await KosmosAuth.resetPassword(
      widget.email,
      region: kCloudRegion,
    )).fold((_) => false, (bool r) => r);
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
      title: 'Nouveau mot de passe',
      portraitOnPhone: true,
      onBack: () => Navigator.of(context).maybePop(),
      children: <Widget>[
        Text(
          'Si un compte existe pour ${widget.email}, un code à 6 chiffres '
          'vient d’y être envoyé. Saisissez-le puis choisissez votre nouveau '
          'mot de passe.',
          style: AppThemeStyle.regularStyle(cFs(13), AppColor.secondaryLabels),
        ),
        cSh(20),
        const CpLabel('Code reçu par e-mail*'),
        cSh(8),
        CpCodeField(
          controller: _code,
          autofocus: true,
          error: _submitted && _codeInvalid,
          onChanged: (_) => _revalidate(),
        ),
        cSh(6),
        ResendCodeLink(onResend: _resend),
        cSh(12),
        const CpLabel('Nouveau mot de passe*'),
        cSh(8),
        CpTextField(
          controller: _password,
          hint: '6 caractères min., Aa, 1 et un symbole',
          obscure: true,
          autofillHints: const <String>[AutofillHints.newPassword],
          onChanged: (_) => _revalidate(),
          error: _submitted && _passwordInvalid,
        ),
        cSh(18),
        const CpLabel('Confirmer le mot de passe*'),
        cSh(8),
        CpTextField(
          controller: _confirmation,
          hint: 'Saisissez-le à nouveau',
          obscure: true,
          autofillHints: const <String>[AutofillHints.newPassword],
          onChanged: (_) => _revalidate(),
          error: _submitted && _confirmationInvalid,
        ),
        cSh(24),
        CpButton(
          label: _busy ? 'Enregistrement…' : 'Changer mon mot de passe',
          onTap: _submit,
        ),
        cSh(14),
        const CpRequiredNote(),
      ],
    );
  }
}
