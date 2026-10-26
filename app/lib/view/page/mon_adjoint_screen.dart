import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/assistant_repository.dart';
import 'package:wina/providers/assistant_providers.dart';
import 'package:wina/services/register_validation.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/confirm_dialog.dart';

/// Même règle que le serveur : 3 à 30 caractères, minuscules, chiffres et tirets (ni au début ni à la fin).
final RegExp _identifierPattern = RegExp(r'^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$');

/// Paramètres → « Mon adjoint » : le coach crée le compte de son adjoint (identifiant et mot de passe), le
/// réinitialise ou le supprime. L'adjoint se connecte ensuite sur son téléphone et accède uniquement au match
/// en cours, dès que le coach l'a lancé.
class MonAdjointScreen extends ConsumerStatefulWidget {
  const MonAdjointScreen({super.key});

  @override
  ConsumerState<MonAdjointScreen> createState() => _MonAdjointScreenState();
}

class _MonAdjointScreenState extends ConsumerState<MonAdjointScreen> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _busy = false;
  bool _changingPassword = false;
  String? _identifierError;
  String? _passwordError;
  String? _serverError;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate({required bool withIdentifier}) {
    final List<String> missing = RegisterValidation.passwordViolations(
      _password.text,
    );
    setState(() {
      _serverError = null;
      _identifierError =
          !withIdentifier ||
                  _identifierPattern.hasMatch(
                    _identifier.text.trim().toLowerCase(),
                  )
              ? null
              : 'app.teams.identifier-invalid'.tr();
      _passwordError =
          missing.isEmpty ? null : 'Il manque : ${missing.join(', ')}.';
    });
    return _identifierError == null && _passwordError == null;
  }

  String _messageFor(AssistantError error) {
    switch (error) {
      case AssistantError.identifierTaken:
        return 'app.teams.identifier-taken'.tr();
      case AssistantError.alreadyExists:
        return 'app.assistant.already-exists'.tr();
      case AssistantError.invalid:
        return 'app.teams.invalid'.tr();
      case AssistantError.other:
        return 'utils.error-default'.tr();
    }
  }

  /// Exécute un appel serveur : écran « occupé », erreur affichée sur l'écran, jamais bloqué.
  Future<void> _run(Future<void> Function() action, String doneMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _identifier.clear();
      _password.clear();
      setState(() {
        _busy = false;
        _changingPassword = false;
      });
      showAppNotif(context, title: doneMessage);
    } on AssistantException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = _messageFor(e.error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = 'utils.error-default'.tr();
      });
    }
  }

  void _create() {
    if (!_validate(withIdentifier: true)) return;
    _run(
      () => AssistantRepository.create(
        identifier: _identifier.text.trim().toLowerCase(),
        password: _password.text,
      ),
      'app.assistant.created'.tr(),
    );
  }

  void _resetPassword() {
    if (!_validate(withIdentifier: false)) return;
    _run(
      () => AssistantRepository.resetPassword(_password.text),
      'app.assistant.password-changed'.tr(),
    );
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (BuildContext ctx) => AppConfirmDialog(
            title: 'app.assistant.delete-title'.tr(),
            message: 'app.assistant.delete-message'.tr(),
            primaryLabel: 'app.assistant.keep'.tr(),
            onPrimary: () => Navigator.of(ctx).pop(),
            secondaryLabel: 'app.assistant.delete'.tr(),
            onSecondary: () {
              Navigator.of(ctx).pop();
              _run(AssistantRepository.delete, 'app.assistant.deleted'.tr());
            },
          ),
    );
  }

  Widget _error(String? text) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: formatHeight(6)),
      child: Text(
        text,
        style: AppThemeStyle.regularStyle(12, DefaultColor.error),
      ),
    );
  }

  Widget _identifierField() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      CpLabel('${'app.assistant.identifier'.tr()}*'),
      sh(8),
      CpTextField(
        controller: _identifier,
        hint: 'app.assistant.identifier-hint'.tr(),
        error: _identifierError != null,
        autofillHints: const <String>[AutofillHints.username],
      ),
      if (_identifierError != null)
        _error(_identifierError)
      else
        Padding(
          padding: EdgeInsets.only(top: formatHeight(6)),
          child: Text(
            'app.teams.identifier-help'.tr(),
            style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
          ),
        ),
    ],
  );

  Widget _passwordField() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      CpLabel('${'app.teams.password'.tr()}*'),
      sh(8),
      CpTextField(
        controller: _password,
        hint: '6 caractères min., Aa, 1 et un symbole',
        obscure: true,
        error: _passwordError != null,
        autofillHints: const <String>[AutofillHints.newPassword],
      ),
      _error(_passwordError),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Assistant?> assistant = ref.watch(myAssistantProvider);
    final Assistant? current = assistant.valueOrNull;

    return CheckProfilScaffold(
      title: 'app.assistant.title'.tr(),
      width: formatWidth(560),
      onBack: () => Navigator.of(context).maybePop(),
      children: <Widget>[
        Text(
          'app.assistant.intro'.tr(),
          style: AppThemeStyle.regularStyle(14, AppColor.secondaryLabels),
        ),
        sh(16),
        if (assistant.isLoading && !assistant.hasValue)
          const Center(child: CircularProgressIndicator())
        else if (current == null) ...<Widget>[
          _identifierField(),
          sh(14),
          _passwordField(),
          if (_serverError != null) ...<Widget>[sh(12), _error(_serverError)],
          sh(18),
          Opacity(
            opacity: _busy ? 0.6 : 1,
            child: CpButton(label: 'app.assistant.create'.tr(), onTap: _create),
          ),
        ] else ...<Widget>[
          CpLabel('app.assistant.identifier'.tr()),
          sh(8),
          Text(
            current.identifier,
            style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
          ),
          sh(6),
          Text(
            'app.assistant.login-help'.tr(),
            style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
          ),
          sh(18),
          if (_changingPassword) ...<Widget>[
            _passwordField(),
            if (_serverError != null) ...<Widget>[sh(12), _error(_serverError)],
            sh(14),
            Row(
              children: <Widget>[
                Expanded(
                  child: CpButton(
                    label: 'app.teams.later'.tr(),
                    soft: true,
                    onTap:
                        () => setState(() {
                          _changingPassword = false;
                          _passwordError = null;
                          _password.clear();
                        }),
                  ),
                ),
                sw(16),
                Expanded(
                  child: Opacity(
                    opacity: _busy ? 0.6 : 1,
                    child: CpButton(
                      label: 'app.assistant.save-password'.tr(),
                      onTap: _resetPassword,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            if (_serverError != null) ...<Widget>[_error(_serverError), sh(12)],
            CpButton(
              label: 'app.assistant.change-password'.tr(),
              soft: true,
              onTap: () => setState(() => _changingPassword = true),
            ),
            sh(12),
            Opacity(
              opacity: _busy ? 0.6 : 1,
              child: CpButton(
                label: 'app.assistant.delete'.tr(),
                soft: true,
                onTap: _confirmDelete,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
