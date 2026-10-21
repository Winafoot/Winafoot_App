import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/data/coach_profile_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart' show PlayerCount;
import 'package:wina/config/theme.dart';
import 'package:wina/view/page/check_profil_step2_screen.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';

/// Check profil — étape 1 : « Finalisez votre profil coach ».
///
/// Collecte le nom du coach (si inconnu), le nom de l'équipe, la catégorie, la division
/// et le format de jeu (5, 8 ou 11 joueurs) ;
/// « Continuer » enregistre ces informations puis passe à l'étape 2 (maillots).
/// Affichée par la passerelle skeleton tant que `profilCompleted` est faux.
///
/// En [editMode], le même écran sert à MODIFIER ces
/// informations depuis les paramètres : « Enregistrer » sauvegarde et revient
/// en arrière, sans enchaîner sur l'étape des maillots — celle-ci n'a de sens
/// qu'à la première complétion. Réutiliser ce formulaire plutôt que d'en
/// écrire un second garde une seule validation et une seule mise en page.
class CheckProfilStep1Screen extends StatefulWidget {
  const CheckProfilStep1Screen({super.key, this.editMode = false});

  /// Ouvert depuis les paramètres pour corriger un profil déjà complet.
  final bool editMode;

  @override
  State<CheckProfilStep1Screen> createState() => _CheckProfilStep1ScreenState();
}

class _CheckProfilStep1ScreenState extends State<CheckProfilStep1Screen> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _equipe = TextEditingController();
  TeamCategory? _category;
  TeamDivision? _division;
  PlayerCount? _format;

  /// Le compte porte déjà son format (posé par le back-office) : il se lit
  /// mais ne se choisit plus, les règles Firestore le verrouillent.
  bool _formatLocked = false;

  /// Nom complet déjà connu (coach inscrit depuis l'app : son prénom) : le champ
  /// n'est plus demandé à l'onboarding, seulement en modification.
  bool _nameKnown = false;
  bool _busy = false;

  /// Vrai dès qu'un « Continuer » a échoué : les champs obligatoires restés
  /// vides passent alors en rouge, jusqu'à ce qu'ils soient renseignés.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  /// Pré-remplit le formulaire avec les informations déjà enregistrées (retour
  /// sur l'étape 1 après une saisie partielle, ou modification), à défaut avec
  /// le nom saisi par l'admin à la création du compte (best-effort : champs
  /// laissés vides en cas d'échec).
  Future<void> _prefill() async {
    try {
      final CoachProfile profile =
          await CoachProfileRepository.watchCoachProfile().first;
      final String coachName = profile.coachName?.trim() ?? '';
      final String? name =
          coachName.isNotEmpty
              ? coachName
              : await CoachProfileRepository.loadInitialCoachName();
      if (!mounted) return;
      setState(() {
        if (name != null && _nom.text.isEmpty) _nom.text = name;
        final String teamName = profile.teamName?.trim() ?? '';
        if (teamName.isNotEmpty && _equipe.text.isEmpty) {
          _equipe.text = teamName;
        }
        _category ??= profile.category;
        _division ??= profile.division;
        _format ??= profile.teamFormat;
        _formatLocked = profile.teamFormat != null;
        _nameKnown = coachName.isNotEmpty;
      });
    } catch (_) {
      // Pré-remplissage best-effort.
    }
  }

  @override
  void dispose() {
    _nom.dispose();
    _equipe.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy) return;
    if (_nom.text.trim().isEmpty ||
        _equipe.text.trim().isEmpty ||
        _category == null ||
        _division == null ||
        _format == null) {
      setState(() => _submitted = true);
      showAppNotif(
        context,
        title: 'Champs obligatoires',
        subTitle: 'Renseignez tous les champs pour continuer.',
        success: false,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await CoachProfileRepository.saveTeamInfo(
        coachName: _nom.text.trim(),
        teamName: _equipe.text.trim(),
        category: _category!,
        division: _division!,
        // Déjà posé : l'écrire de nouveau serait refusé par les règles.
        teamFormat: _formatLocked ? null : _format,
      );
    } catch (e) {
      // L'étape 2 n'écrit que les maillots et `profilCompleted` : sans cette
      // écriture, le profil serait marqué complet mais vide. On reste ici.
      if (!mounted) return;
      setState(() => _busy = false);
      showAppNotif(
        context,
        title: 'app.check-profil-data.enregistrement-impossible'.tr(),
        subTitle: '$e',
        success: false,
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (widget.editMode) {
      showAppNotif(
        context,
        title: 'Équipe mise à jour',
        subTitle: 'Vos informations ont bien été enregistrées.',
      );
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CheckProfilStep2Screen()),
    );
  }

  /// Rafraîchit l'état rouge des champs texte à la saisie (sans effet tant
  /// qu'aucune validation n'a échoué).
  void _onFieldChanged(String _) {
    if (_submitted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CheckProfilScaffold(
      title:
          widget.editMode
              ? 'Modifier mon équipe'
              : 'Finalisez votre profil coach',
      // Édition depuis les paramètres : retour à la liste. En onboarding on
      // laisse `onBack` nul, le profil devant être complété avant d'entrer.
      onBack: widget.editMode ? () => Navigator.of(context).maybePop() : null,
      children: [
        if (!_nameKnown || widget.editMode) ...<Widget>[
          const CpLabel('Nom complet du coach*'),
          sh(8),
          CpTextField(
            controller: _nom,
            hint: 'Ex. John Doe',
            onChanged: _onFieldChanged,
            error: _submitted && _nom.text.trim().isEmpty,
          ),
          sh(18),
        ],
        const CpLabel('Nom de votre équipe*'),
        sh(8),
        CpTextField(
          controller: _equipe,
          hint: 'Ex. Les bleus de Nice',
          onChanged: _onFieldChanged,
          error: _submitted && _equipe.text.trim().isEmpty,
        ),
        sh(18),
        const CpLabel('Catégorie*'),
        sh(8),
        CpDropdown<TeamCategory>(
          value: _category,
          values: TeamCategory.values,
          labelOf: (TeamCategory v) => v.label,
          onChanged: (TeamCategory v) => setState(() => _category = v),
          error: _submitted && _category == null,
        ),
        sh(18),
        const CpLabel('Division*'),
        sh(8),
        CpDropdown<TeamDivision>(
          value: _division,
          values: TeamDivision.values,
          labelOf: (TeamDivision v) => v.label,
          onChanged: (TeamDivision v) => setState(() => _division = v),
          error: _submitted && _division == null,
        ),
        sh(18),
        const CpLabel('Format de jeu*'),
        sh(8),
        if (_formatLocked)
          CpBox(
            child: Text(
              '${_format!.value} joueurs',
              style: AppThemeStyle.regularStyle(15, AppColor.primaryLabels),
            ),
          )
        else
          CpDropdown<PlayerCount>(
            value: _format,
            values: const <PlayerCount>[
              PlayerCount.five,
              PlayerCount.eight,
              PlayerCount.eleven,
            ],
            labelOf: (PlayerCount v) => '${v.value} joueurs',
            onChanged: (PlayerCount v) => setState(() => _format = v),
            error: _submitted && _format == null,
          ),
        sh(28),
        CpButton(
          label: widget.editMode ? 'Enregistrer' : 'Continuer',
          onTap: _continue,
        ),
        sh(14),
        const CpRequiredNote(),
      ],
    );
  }
}
