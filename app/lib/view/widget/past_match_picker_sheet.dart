import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/match_wizard.dart';

const List<String> _kMonths = <String>[
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String _formatDate(DateTime? d) {
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')} ${_kMonths[d.month - 1]}';
}

/// Ouvre la feuille « Copier depuis un match précédent » : liste des matchs
/// terminés portant une composition, du plus récent au plus ancien. [onPick]
/// reçoit le match choisi ; la feuille se ferme avant l'appel.
Future<void> showPastMatchPickerSheet(
  BuildContext context, {
  required ValueChanged<GameMatch> onPick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColor.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(cR(20))),
    ),
    builder: (_) => _PastMatchPickerSheet(onPick: onPick),
  );
}

class _PastMatchPickerSheet extends ConsumerWidget {
  const _PastMatchPickerSheet({required this.onPick});

  final ValueChanged<GameMatch> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GameMatch>> matchesAsync = ref.watch(
      finishedMatchesProvider,
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: cW(24), vertical: cH(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'app.past-match-picker-sheet.titre'.tr(),
              style: AppThemeStyle.semiBStyle(cFs(16), AppColor.primaryLabels),
            ),
            cSh(12),
            matchesAsync.when(
              data: (List<GameMatch> all) {
                final List<GameMatch> matches = all
                    .where((GameMatch m) => m.composition != null)
                    .toList(growable: false);
                if (matches.isEmpty) {
                  return Text(
                    'app.past-match-picker-sheet.aucun-match'.tr(),
                    style: AppThemeStyle.regularStyle(
                      cFs(13),
                      AppColor.secondaryLabels,
                    ),
                  );
                }
                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => cSh(10),
                    itemBuilder: (BuildContext context, int i) {
                      final GameMatch match = matches[i];
                      return _PastMatchTile(
                        match: match,
                        onTap: () {
                          Navigator.of(context).pop();
                          onPick(match);
                        },
                      );
                    },
                  ),
                );
              },
              loading:
                  () => AppLoader(
                    padding: EdgeInsets.symmetric(vertical: cH(20)),
                  ),
              error:
                  (Object e, _) => Text(
                    'app.past-match-picker-sheet.erreur-chargement'.tr(),
                    style: AppThemeStyle.regularStyle(
                      cFs(13),
                      AppColor.secondaryLabels,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'un match précédent : adversaire + date, puis les puces schéma /
/// joueurs / statistiques (mêmes puces que le hub « Coup d'envoi »).
class _PastMatchTile extends StatelessWidget {
  const _PastMatchTile({required this.match, required this.onTap});

  final GameMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final MatchComposition? comp = match.composition;
    // Bascules seules (comme « X / 37 » du paramétrage) : les stats calculées
    // d'un ancien match ne comptent pas.
    final List<String> stats = toggleKeys(match.enabledStatKeys);
    final String opponent =
        match.opponent.name.isEmpty
            ? 'app.past-match-picker-sheet.equipe-adverse'.tr()
            : match.opponent.name;
    return Material(
      color: AppColor.background,
      borderRadius: BorderRadius.circular(cR(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(14)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cW(16), vertical: cH(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'app.past-match-picker-sheet.vs-adversaire'.tr(
                        args: <String>[opponent],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeStyle.semiBStyle(
                        cFs(14),
                        AppColor.primaryLabels,
                      ),
                    ),
                  ),
                  cSw(8),
                  Text(
                    _formatDate(match.finishedAt),
                    style: AppThemeStyle.regularStyle(
                      cFs(12),
                      AppColor.secondaryLabels,
                    ),
                  ),
                ],
              ),
              cSh(8),
              Wrap(
                spacing: cW(8),
                runSpacing: cH(6),
                children: <Widget>[
                  if (comp != null) InfoChip(comp.formationLabel),
                  if (comp != null)
                    InfoChip(
                      'app.past-match-picker-sheet.n-joueurs'.tr(
                        args: <String>['${comp.placedCount}'],
                      ),
                    ),
                  if (stats.isNotEmpty)
                    InfoChip(
                      'app.past-match-picker-sheet.n-statistiques'.tr(
                        args: <String>['${stats.length}'],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
