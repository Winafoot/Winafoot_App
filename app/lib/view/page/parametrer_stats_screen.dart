import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/view/widget/gerer_equipe_scaffold.dart';
import 'package:wina/view/widget/stat_tone.dart';
import 'package:wina/view/widget/match_wizard.dart';

/// Écran « Paramétrez les statistiques » : active/désactive les statistiques
/// suivies pendant le match : 28 bascules en 2 colonnes de 14, « Perdus » (rouge) à gauche et
/// « Gagnés » (vert) à droite, chacune dans son ordre de priorité.
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
        style: AppThemeStyle.mediumStyle(cFs(15), AppColor.secondaryLabels),
      ),
      action: WizardCtaButton(
        label: 'utils.validate'.tr(),
        enabled: _selected.isNotEmpty,
        onTap: _validate,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isPhoneLayout ? 16 : cW(40),
          0,
          isPhoneLayout ? 16 : cW(40),
          cH(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _column(
                'app.parametrer-stats.perdus'.tr(),
                statsOfSide(kStatToggles, StatSide.bad),
              ),
            ),
            cSw(16),
            Expanded(
              child: _column(
                'app.parametrer-stats.gagnes'.tr(),
                statsOfSide(kStatToggles, StatSide.good),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _column(String title, List<StatDef> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ThemeTitle(title),
        for (final StatDef s in stats) ...<Widget>[
          _StatToggle(
            label: s.label,
            tint: statTint(s.key),
            value: _selected.contains(s.key),
            onChanged: (bool on) => _toggle(s.key, on),
          ),
          cSh(isPhoneLayout ? 6 : 10),
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
      padding: EdgeInsets.only(left: cW(4), top: cH(6), bottom: cH(10)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppThemeStyle.semiBStyle(cFs(15), AppColor.primaryLabels),
      ),
    );
  }
}

class _StatToggle extends StatelessWidget {
  const _StatToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.tint,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Fond selon la nature de la stat (vert, rouge, jaune pour le carton jaune).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: cW(16), right: cW(8)),
      height: isPhoneLayout ? 34 : cH(44),
      decoration: BoxDecoration(
        color:
            tint == null
                ? AppColor.surface
                : Color.alphaBlend(tint!, AppColor.surface),
        borderRadius: BorderRadius.circular(cR(12)),
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
              style: AppThemeStyle.mediumStyle(cFs(14), AppColor.primaryLabels),
            ),
          ),
          cSw(8),
          Transform.scale(
            // Le Switch Material garde sa taille native : on le réduit pour
            // qu'il tienne dans la pastille compacte du téléphone.
            scale: isPhoneLayout ? 0.7 : 1,
            child: Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeThumbColor: AppColor.textLight,
              activeTrackColor: AppColor.primaryColor,
              inactiveThumbColor: AppColor.textLight,
              inactiveTrackColor: AppColor.disabled,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
