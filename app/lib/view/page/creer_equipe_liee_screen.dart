import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/billing/access_info.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/linked_team_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/services/register_validation.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';

/// Identifiant de connexion d'une équipe : 3 à 30 caractères, minuscules, chiffres et tirets
/// (ni tiret au début ni à la fin). Même règle que le serveur.
final RegExp _identifierPattern = RegExp(r'^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$');

/// Écran de création d'une équipe liée (formule à 2 ou 3 équipes) : chaque équipe a son propre compte,
/// qui se connecte avec un identifiant et un mot de passe. Le propriétaire peut le fermer (« Plus tard »).
class CreerEquipeLieeScreen extends ConsumerStatefulWidget {
  const CreerEquipeLieeScreen({super.key});

  @override
  ConsumerState<CreerEquipeLieeScreen> createState() => _CreerEquipeLieeScreenState();
}

class _CreerEquipeLieeScreenState extends ConsumerState<CreerEquipeLieeScreen> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _teamName = TextEditingController();

  TeamCategory _category = TeamCategory.values.first;
  TeamDivision _division = TeamDivision.values.first;
  PlayerCount _format = PlayerCount.eleven;

  bool _busy = false;
  String? _identifierError;
  String? _passwordError;
  String? _nameError;

  /// Message d'erreur renvoyé par le serveur (l'écran reste ouvert).
  String? _serverError;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _teamName.dispose();
    super.dispose();
  }

  /// Contrôles locaux, avant tout appel réseau. Renvoie vrai si tout est valide.
  bool _validate() {
    final String identifier = _identifier.text.trim().toLowerCase();
    final List<String> missing = RegisterValidation.passwordViolations(_password.text);
    setState(() {
      _serverError = null;
      _identifierError = _identifierPattern.hasMatch(identifier) ? null : 'app.teams.identifier-invalid'.tr();
      _passwordError = missing.isEmpty ? null : 'Il manque : ${missing.join(', ')}.';
      _nameError = _teamName.text.trim().isEmpty ? 'app.teams.field-required'.tr() : null;
    });
    return _identifierError == null && _passwordError == null && _nameError == null;
  }

  String _messageFor(LinkedTeamError error) {
    switch (error) {
      case LinkedTeamError.identifierTaken:
        return 'app.teams.identifier-taken'.tr();
      case LinkedTeamError.quotaReached:
        return 'app.teams.quota-reached'.tr();
      case LinkedTeamError.noSubscription:
        return 'app.teams.no-subscription'.tr();
      case LinkedTeamError.invalid:
        return 'app.teams.invalid'.tr();
      case LinkedTeamError.other:
        return 'utils.error-default'.tr();
    }
  }

  /// Équipes encore à créer, lues sans s'abonner (appelé hors du build). Au moins 1.
  int _missingNow() {
    final AccessInfo? info = ref.read(accessInfoProvider).valueOrNull;
    if (info == null) return 1;
    final int linked = ref.read(linkedTeamsProvider).valueOrNull?.length ?? 0;
    final int missing = missingTeams(info, linkedCount: linked, now: DateTime.now());
    return missing < 1 ? 1 : missing;
  }

  Future<void> _submit() async {
    if (_busy || !_validate()) return;
    // Lu avant l'appel : après, le flux des équipes liées peut déjà compter la nouvelle équipe.
    final bool moreToCreate = _missingNow() > 1;
    setState(() => _busy = true);
    try {
      await ref.read(createLinkedTeamProvider)(<String, Object?>{
        'identifier': _identifier.text.trim().toLowerCase(),
        'password': _password.text,
        'teamName': _teamName.text.trim(),
        'category': _category.name,
        'division': _division.name,
        'teamFormat': _format.value,
      });
      if (!mounted) return;
      showAppNotif(context, title: 'app.teams.created'.tr());
      if (moreToCreate) {
        // Il reste des équipes payées à créer : on repart sur un formulaire vierge.
        _identifier.clear();
        _password.clear();
        _teamName.clear();
        setState(() => _busy = false);
        return;
      }
      Navigator.of(context).pop();
    } on LinkedTeamException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = _messageFor(e.error);
      });
    } catch (_) {
      // Panne inattendue : l'écran ne doit pas rester bloqué en « occupé ».
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = 'utils.error-default'.tr();
      });
    }
  }

  /// Équipes encore à créer (au moins 1, puisque l'écran vient d'être ouvert pour en créer une).
  int _remaining() {
    final AccessInfo? info = ref.watch(accessInfoProvider).valueOrNull;
    if (info == null) return 1;
    final int linked = ref.watch(linkedTeamsProvider).valueOrNull?.length ?? 0;
    final int missing = missingTeams(info, linkedCount: linked, now: DateTime.now());
    return missing < 1 ? 1 : missing;
  }

  Widget _error(String? text) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: formatHeight(6)),
      child: Text(text, style: AppThemeStyle.regularStyle(12, DefaultColor.error)),
    );
  }

  Widget _identifierField() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      CpLabel('${'app.teams.identifier'.tr()}*'),
      sh(8),
      KeyedSubtree(
        key: const Key('team-identifier'),
        child: CpTextField(
          controller: _identifier,
          hint: 'app.teams.identifier-hint'.tr(),
          error: _identifierError != null,
          autofillHints: const <String>[AutofillHints.username],
        ),
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
      KeyedSubtree(
        key: const Key('team-password'),
        child: CpTextField(
          controller: _password,
          hint: '6 caractères min., Aa, 1 et un symbole',
          obscure: true,
          error: _passwordError != null,
          autofillHints: const <String>[AutofillHints.newPassword],
        ),
      ),
      _error(_passwordError),
    ],
  );

  Widget _nameField() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      CpLabel('${'app.teams.team-name'.tr()}*'),
      sh(8),
      KeyedSubtree(
        key: const Key('team-name'),
        child: CpTextField(
          controller: _teamName,
          hint: 'Ex. U15 Lyon',
          error: _nameError != null,
        ),
      ),
      _error(_nameError),
    ],
  );

  @override
  Widget build(BuildContext context) {
    // Deux colonnes sur une carte large : le formulaire tient dans la page sans défilement.
    return CheckProfilScaffold(
      title: 'app.teams.create-title'.tr(),
      width: formatWidth(860),
      onBack: () => Navigator.of(context).maybePop(),
      children: <Widget>[
        Text(
          'app.teams.create-intro'.tr(args: <String>['${_remaining()}']),
          style: AppThemeStyle.regularStyle(14, AppColor.secondaryLabels),
        ),
        sh(16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[_identifierField(), sh(14), _passwordField(), sh(14), _nameField()],
              ),
            ),
            sw(28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  CpLabel('app.teams.category'.tr()),
                  sh(8),
                  CpDropdown<TeamCategory>(
                    value: _category,
                    values: TeamCategory.values,
                    labelOf: (TeamCategory c) => c.label,
                    onChanged: (TeamCategory c) => setState(() => _category = c),
                  ),
                  sh(14),
                  CpLabel('app.teams.division'.tr()),
                  sh(8),
                  CpDropdown<TeamDivision>(
                    value: _division,
                    values: TeamDivision.values,
                    labelOf: (TeamDivision d) => d.label,
                    onChanged: (TeamDivision d) => setState(() => _division = d),
                  ),
                  sh(14),
                  CpLabel('app.teams.format'.tr()),
                  sh(8),
                  CpDropdown<PlayerCount>(
                    value: _format,
                    values: PlayerCount.values,
                    labelOf: (PlayerCount p) => p.label,
                    onChanged: (PlayerCount p) => setState(() => _format = p),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_serverError != null) ...<Widget>[sh(12), _error(_serverError)],
        sh(18),
        Row(
          children: <Widget>[
            Expanded(
              child: CpButton(label: 'app.teams.later'.tr(), soft: true, onTap: () => Navigator.of(context).maybePop()),
            ),
            sw(16),
            Expanded(
              child: Opacity(
                opacity: _busy ? 0.6 : 1,
                child: CpButton(label: 'app.teams.submit'.tr(), onTap: _submit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
