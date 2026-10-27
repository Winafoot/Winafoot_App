import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:skeleton/skeleton.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/config/legal_links.dart';
import 'package:wina/routes/app_router.gr.dart';
import 'package:wina/services/coach_registration.dart';
import 'package:wina/services/register_validation.dart';
import 'package:wina/view/page/verify_email_page.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/social_sign_in_ui.dart';

/// Inscription d'un coach, page 1 : e-mail, mot de passe, prénom et CGU.
///
/// Un clic crée le compte (`registerCoach`), connecte le coach et envoie le code
/// de vérification de l'e-mail, qu'il saisit à l'écran suivant. La page 2 (club, catégorie, division, format) est l'écran
/// « Finalisez votre profil », que la passerelle skeleton ouvre tant que
/// `profilCompleted` est faux : un coach qui quitte entre les deux y revient.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  final TextEditingController _firstname = TextEditingController();
  late final TapGestureRecognizer _cguTap;

  bool _acceptedCgu = false;
  bool _busy = false;

  /// Champs à corriger, affichés en rouge après un envoi refusé localement.
  Set<RegisterField> _invalid = <RegisterField>{};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _cguTap =
        TapGestureRecognizer()
          ..onTap = () => openLegalLink(context, kCguUri);
  }

  @override
  void dispose() {
    _cguTap.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _firstname.dispose();
    super.dispose();
  }

  void _revalidate() {
    if (!_submitted) return;
    setState(() => _invalid = _currentInvalidFields());
  }

  Set<RegisterField> _currentInvalidFields() {
    return RegisterValidation.invalidFields(
      email: _email.text,
      password: _password.text,
      confirmation: _confirmation.text,
      firstname: _firstname.text,
      acceptedCgu: _acceptedCgu,
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    final Set<RegisterField> invalid = _currentInvalidFields();
    if (invalid.isNotEmpty) {
      setState(() {
        _submitted = true;
        _invalid = invalid;
      });
      showAppNotif(
        context,
        title: 'Informations incomplètes',
        subTitle: _firstProblem(invalid),
        success: false,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await CoachRegistration.register(
        email: _email.text,
        password: _password.text,
        firstname: _firstname.text,
        acceptedCgu: _acceptedCgu,
      );
    } on RegistrationException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppNotif(
        context,
        title: 'Inscription impossible',
        subTitle: messageFor(e),
        success: false,
      );
      // Compte créé mais connexion refusée : le coach se connecte à la main.
      return;
    }

    if (!mounted) return;
    // Le code de vérification est parti avec l'inscription : le coach le saisit
    // ici, ou passe (« Plus tard ») sans bloquer l'entrée dans l'app.
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (_) => VerifyEmailPage(email: _email.text.trim().toLowerCase()),
      ),
    );
    await _enterApp();
  }

  /// Charge le coach connecté puis ouvre l'app (« Finalisez votre profil » s'ouvre
  /// tant que son profil n'est pas complété).
  Future<void> _enterApp() async {
    if (!mounted) return;
    await ref.read(userProvider).init(context);
    if (!mounted) return;
    AutoRouter.of(
      context,
    ).pushAndPopUntil(const LoggedUserAppCoreRoute(), predicate: (_) => false);
  }

  /// Message affiché pour chaque cause d'échec de l'inscription.
  @visibleForTesting
  static String messageFor(RegistrationException e) {
    switch (e.error) {
      case RegistrationError.emailTaken:
        return 'Un compte existe déjà avec cette adresse. Connectez-vous.';
      case RegistrationError.invalidInput:
        final String? detail = e.message?.trim();
        return detail != null && detail.isNotEmpty
            ? detail
            : 'Vérifiez les informations saisies.';
      case RegistrationError.cguRefused:
        return 'Vous devez accepter les conditions générales d’utilisation.';
      case RegistrationError.tooManyAttempts:
        return 'Trop de tentatives. Réessayez dans un moment.';
      case RegistrationError.network:
        return 'Connexion impossible. Vérifiez votre réseau et réessayez.';
      case RegistrationError.unknown:
        return 'L’inscription a échoué. Réessayez, ou connectez-vous si '
            'vous avez déjà reçu un e-mail de bienvenue.';
    }
  }

  String _firstProblem(Set<RegisterField> invalid) {
    if (invalid.contains(RegisterField.email)) {
      return 'Saisissez une adresse e-mail valide.';
    }
    if (invalid.contains(RegisterField.password)) {
      final List<String> missing = RegisterValidation.passwordViolations(
        _password.text,
      );
      return 'Le mot de passe doit contenir ${missing.join(', ')}.';
    }
    if (invalid.contains(RegisterField.confirmation)) {
      return 'Les mots de passe ne correspondent pas.';
    }
    if (invalid.contains(RegisterField.firstname)) {
      return 'Saisissez votre prénom.';
    }
    return 'Acceptez les conditions générales d’utilisation pour continuer.';
  }

  @override
  Widget build(BuildContext context) {
    return CheckProfilScaffold(
      title: 'Créer mon compte',
      portraitOnPhone: true,
      onBack: () => Navigator.of(context).maybePop(),
      children: <Widget>[
        const CpLabel('Adresse e-mail*'),
        sh(8),
        CpTextField(
          controller: _email,
          hint: 'Ex. coach@monclub.fr',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.email],
          onChanged: (_) => _revalidate(),
          error: _invalid.contains(RegisterField.email),
        ),
        sh(18),
        const CpLabel('Prénom du coach*'),
        sh(8),
        CpTextField(
          controller: _firstname,
          hint: 'Ex. John',
          autofillHints: const <String>[AutofillHints.givenName],
          onChanged: (_) => _revalidate(),
          error: _invalid.contains(RegisterField.firstname),
        ),
        sh(18),
        const CpLabel('Mot de passe*'),
        sh(8),
        CpTextField(
          controller: _password,
          hint: '6 caractères min., Aa, 1 et un symbole',
          obscure: true,
          autofillHints: const <String>[AutofillHints.newPassword],
          onChanged: (_) => _revalidate(),
          error: _invalid.contains(RegisterField.password),
        ),
        sh(18),
        const CpLabel('Confirmer le mot de passe*'),
        sh(8),
        CpTextField(
          controller: _confirmation,
          hint: 'Saisissez-le à nouveau',
          obscure: true,
          autofillHints: const <String>[AutofillHints.newPassword],
          onChanged: (_) => _revalidate(),
          error: _invalid.contains(RegisterField.confirmation),
        ),
        sh(20),
        _CguCheckbox(
          value: _acceptedCgu,
          error: _invalid.contains(RegisterField.cgu),
          recognizer: _cguTap,
          onChanged: (bool v) {
            setState(() => _acceptedCgu = v);
            _revalidate();
          },
        ),
        sh(24),
        CpButton(
          label: _busy ? 'Création…' : 'Créer mon compte',
          onTap: _submit,
        ),
        sh(14),
        const CpRequiredNote(),
        sh(22),
        SocialSignInButtons(onSignedIn: _enterApp),
      ],
    );
  }
}

/// Case « J'accepte les CGU », avec le lien vers les conditions.
class _CguCheckbox extends StatelessWidget {
  const _CguCheckbox({
    required this.value,
    required this.error,
    required this.recognizer,
    required this.onChanged,
  });

  final bool value;
  final bool error;
  final GestureRecognizer recognizer;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppThemeStyle.regularStyle(
      13,
      error ? AppColor.destructive : AppColor.primaryLabels,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: sp(24),
          height: sp(24),
          child: Checkbox(
            value: value,
            activeColor: AppColor.primaryColor,
            side: BorderSide(
              color: error ? AppColor.destructive : AppColor.divider,
              width: 1.5,
            ),
            onChanged: (bool? v) => onChanged(v ?? false),
          ),
        ),
        sw(12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: formatHeight(3)),
            child: Text.rich(
              TextSpan(
                style: base,
                children: <InlineSpan>[
                  const TextSpan(text: 'J’accepte les '),
                  TextSpan(
                    text: 'conditions générales d’utilisation',
                    recognizer: recognizer,
                    style: base.copyWith(
                      color: AppColor.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '*'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
