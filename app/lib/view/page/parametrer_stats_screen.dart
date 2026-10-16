import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/view/widget/gerer_equipe_scaffold.dart';
import 'package:wina/view/widget/match_wizard.dart';

/// Thèmes de chaque colonne (12 / 11 / 14 bascules), dans l'ordre de lecture
/// du client. Un thème n'est jamais coupé entre deux colonnes : aucune borne
/// d'index à recaler quand le catalogue bouge. Tout thème absent d'ici
/// disparaîtrait de l'écran (le test du paramétrage le vérifie).
const List<List<StatCategory>> _kColumns = <List<StatCategory>>[
  <StatCategory>[
    StatCategory.passes,
    StatCategory.efficacite,
    StatCategory.tirs,
    StatCategory.offensives,
  ],
  <StatCategory>[StatCategory.coupsDePiedArretes, StatCategory.fautesSanctions],
  <StatCategory>[
    StatCategory.gardienDefense,
    StatCategory.technique,
    StatCategory.duels,
  ],
];

/// Écran « Paramétrez les statistiques » : active/désactive les statistiques
/// suivies pendant le match (3 colonnes de bascules, un titre par thème).
/// Les 5 statistiques calculées (totaux, réussite de passes) n'y figurent pas :
/// elles s'affichent d'elles-mêmes quand toutes leurs composantes sont suivies.
/// « Valider » enregistre la sélection sur le match et revient au hub.
class ParametrerStatsScreen extends ConsumerStatefulWidget {
  const ParametrerStatsScreen({super.key});

  @override
  ConsumerState<ParametrerStatsScreen> createState() =>
      _ParametrerStatsScreenState();
}

class _ParametrerStatsScreenState extends ConsumerState<ParametrerStatsScreen> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    // Seules les bascules : une clé calculée héritée d'un ancien match (ou d'une
    // copie) n'est ni affichée ni comptée. Rien de reconnu → défauts.
    final List<String> existing = toggleKeys(
      ref.read(matchDraftProvider).enabledStatKeys,
    );
    _selected =
        (existing.isNotEmpty ? existing : defaultEnabledStatKeys()).toSet();
  }

  void _toggle(String key, bool on) =>
      setState(() => on ? _selected.add(key) : _selected.remove(key));

  void _validate() {
    ref.read(matchDraftProvider.notifier).setEnabledStats(_selected.toList());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GererEquipeScaffold(
      title: 'app.parametrer-stats.titre'.tr(),
      headerTrailing: Text(
        'app.parametrer-stats.selection'.tr(
          args: <String>['${_selected.length}', '${kStatToggles.length}'],
        ),
        style: AppThemeStyle.mediumStyle(15, AppColor.secondaryLabels),
      ),
      action: WizardCtaButton(
        label: 'utils.validate'.tr(),
        enabled: _selected.isNotEmpty,
        onTap: _validate,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          formatWidth(40),
          0,
          formatWidth(40),
          formatHeight(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < _kColumns.length; i++) ...<Widget>[
              if (i > 0) sw(16),
              Expanded(child: _column(_kColumns[i])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _column(List<StatCategory> themes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final StatCategory theme in themes) ...<Widget>[
          _ThemeTitle(theme.label),
          for (final StatDef s in kStatToggles)
            if (s.category == theme) ...<Widget>[
              _StatToggle(
                label: s.label,
                value: _selected.contains(s.key),
                onChanged: (bool on) => _toggle(s.key, on),
              ),
              sh(10),
            ],
        ],
      ],
    );
  }
}

/// Titre d'un thème, posé au-dessus de ses bascules.
class _ThemeTitle extends StatelessWidget {
  const _ThemeTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: formatWidth(4),
        top: formatHeight(6),
        bottom: formatHeight(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppThemeStyle.semiBStyle(15, AppColor.primaryLabels),
      ),
    );
  }
}

class _StatToggle extends StatelessWidget {
  const _StatToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: formatWidth(16), right: formatWidth(8)),
      height: formatHeight(44),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColor.primaryLabels.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.mediumStyle(14, AppColor.primaryLabels),
            ),
          ),
          sw(8),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeThumbColor: AppColor.textLight,
            activeTrackColor: AppColor.primaryColor,
            inactiveThumbColor: AppColor.textLight,
            inactiveTrackColor: AppColor.disabled,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
