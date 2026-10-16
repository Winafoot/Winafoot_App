import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/view/page/gerer_equipe_numbers_screen.dart';
import 'package:wina/view/widget/gerer_equipe_scaffold.dart';

/// Ouvre le sous-flux « Gérer mon équipe » depuis un brouillon vierge.
///
/// Un club dont le format est fixé (`teamFormat`) n'a pas à le choisir : on
/// saute [GererEquipeCountScreen] et on enchaîne avec ce format. Sans format
/// (comptes existants), l'écran de choix s'ouvre comme avant.
Future<void> startGererEquipeFlow(BuildContext context, WidgetRef ref) async {
  ref.read(compositionDraftProvider.notifier).reset();
  final PlayerCount? clubFormat = ref.read(teamFormatProvider);
  if (clubFormat == null) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GererEquipeCountScreen()),
    );
    return;
  }
  await continueWithPlayerCount(context, ref, clubFormat.value);
}

/// Pose le nombre de joueurs puis enchaîne sur les numéros : d'abord la popup
/// qui réserve des numéros aux remplaçants, puis l'écran « Attribuez les
/// numéros ». La popup n'est ouverte QUE d'ici : un chemin qui saute le choix
/// du nombre doit donc passer par cette fonction, sinon les remplaçants
/// retombent en silence sur l'intervalle contigu (`subNumbersOf`).
Future<void> continueWithPlayerCount(
  BuildContext context,
  WidgetRef ref,
  int count,
) async {
  ref.read(compositionDraftProvider.notifier).setCount(count);
  // « Popup qui arrive juste avant les interfaces (Gérer mon équipe step 2) »,
  // dit la maquette : le coach choisit d'abord quels numéros iront aux
  // remplaçants.
  await showSubNumbersDialog(context, ref);
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const GererEquipeNumbersScreen()),
  );
}

/// Sous-flux « Gérer mon équipe » — étape 1 : nombre de joueurs (11 / 8 / 5).
/// Ouvert seulement pour les comptes sans format de club (cf.
/// [startGererEquipeFlow]).
class GererEquipeCountScreen extends ConsumerWidget {
  const GererEquipeCountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GererEquipeScaffold(
      title: 'app.gerer-equipe-count.titre'.tr(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: formatHeight(24)),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: formatWidth(20),
              runSpacing: formatHeight(16),
              children: <Widget>[
                for (final PlayerCount c in PlayerCount.values)
                  _CountCard(
                    count: c,
                    onTap: () => continueWithPlayerCount(context, ref, c.value),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.count, required this.onTap});

  final PlayerCount count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double badge = sp(18);
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(r(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(18)),
        child: Container(
          width: formatWidth(210),
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(20),
            vertical: formatHeight(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'app.gerer-equipe-count.matchs-a'.tr(),
                      style: AppThemeStyle.mediumStyle(
                        15,
                        AppColor.primaryLabels,
                      ),
                    ),
                    TextSpan(
                      text: 'app.gerer-equipe-count.joueurs'.tr(
                        args: <String>['${count.value}'],
                      ),
                      style: AppThemeStyle.semiBStyle(
                        15,
                        AppColor.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              sh(12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'app.gerer-equipe-count.choisir'.tr(),
                    style: AppThemeStyle.boldStyle(14, AppColor.primaryLabels),
                  ),
                  sw(8),
                  SizedBox(
                    width: badge,
                    height: badge,
                    child: Icon(
                      Iconsax.arrow_circle_right,
                      size: sp(11),
                      color: AppColor.primaryLabels,
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
