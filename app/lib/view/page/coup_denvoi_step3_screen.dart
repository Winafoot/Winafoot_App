import 'package:wina/view/page/gerer_equipe_nav.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/view/page/gerer_equipe_count_screen.dart';
import 'package:wina/view/page/gerer_equipe_placement_screen.dart';
import 'package:wina/view/page/match_live_screen.dart';
import 'package:wina/view/page/parametrer_stats_screen.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/adjoint_button.dart';
import 'package:wina/view/widget/match_wizard.dart';
import 'package:wina/view/widget/past_match_picker_sheet.dart';
import 'package:wina/view/widget/team_crest.dart';

/// Nom de la route du hub « Coup d'envoi » (pour y revenir après le sous-flux
/// « Gérer mon équipe »).
const String kCoupDEnvoiHubRoute = 'coup-denvoi-hub';

/// Assistant « Coup d'envoi » — étape 3 : « Gérez le match avant de démarrer ».
///
/// Hub : gérer l'équipe (composition) + paramétrer les statistiques + copier
/// depuis un match précédent. « Démarrer le match » reste désactivé tant que
/// l'équipe et les statistiques ne sont pas prêtes (phases 2–3).
class CoupDEnvoiStep3Screen extends ConsumerStatefulWidget {
  const CoupDEnvoiStep3Screen({super.key});

  @override
  ConsumerState<CoupDEnvoiStep3Screen> createState() =>
      _CoupDEnvoiStep3ScreenState();
}

class _CoupDEnvoiStep3ScreenState extends ConsumerState<CoupDEnvoiStep3Screen> {
  @override
  void initState() {
    super.initState();
    // Persiste le brouillon du match (users/{uid}/matches) à l'entrée du hub.
    WidgetsBinding.instance.addPostFrameCallback((_) => _persistDraft());
  }

  Future<void> _persistDraft() async {
    final GameMatch draft = ref.read(matchDraftProvider);
    try {
      final String id = await MatchRepository.saveDraft(draft);
      if (draft.id == null) {
        ref.read(matchDraftProvider.notifier).setId(id);
      }
    } catch (_) {
      // Persistance non bloquante : l'assistant continue de fonctionner.
    }
  }

  /// Démarre le match : enregistre d'abord le brouillon complet (composition +
  /// statistiques renseignées entre-temps) puis ouvre l'écran « Match en cours ».
  Future<void> _startMatch() async {
    await _persistDraft();
    if (!mounted) return;
    AnalyticsController.logEvent('match_started');
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MatchLiveScreen()));
  }

  /// Ouvre la feuille de choix d'un match précédent et applique sa composition
  /// + ses statistiques activées au brouillon courant (« Copier depuis un
  /// match précédent »).
  void _copyFromPreviousMatch() {
    showPastMatchPickerSheet(
      context,
      onPick: (GameMatch source) {
        final MatchComposition? composition = source.composition;
        if (composition == null) return;
        final MatchDraftNotifier notifier = ref.read(
          matchDraftProvider.notifier,
        );
        notifier.setComposition(composition);
        // Bascules seules : un ancien match porte aussi des clés de stats
        // calculées, qui fausseraient la pastille « N statistiques ».
        notifier.setEnabledStats(toggleKeys(source.enabledStatKeys));
        _persistDraft();
        showAppNotif(
          context,
          title: 'app.coup-denvoi-step3.composition-copiee'.tr(),
          subTitle:
              source.opponent.name.isEmpty
                  ? 'app.coup-denvoi-step3.repris-match-precedent'.tr()
                  : 'app.coup-denvoi-step3.repris-match-contre'.tr(
                    namedArgs: <String, String>{
                      'adversaire': source.opponent.name,
                    },
                  ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameMatch draft = ref.watch(matchDraftProvider);
    final CoachProfile? coach = ref.watch(coachProfileProvider).valueOrNull;
    // Prêt à démarrer : équipe gérée (composition complète) ET statistiques
    // paramétrées.
    final bool ready = draft.isReadyToStart;

    return MatchWizardScaffold(
      title: 'app.coup-denvoi-step3.titre'.tr(),
      onBack: () => Navigator.of(context).maybePop(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isPhoneLayout ? double.infinity : cW(980),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhoneLayout ? 16 : cW(40),
            vertical: isPhoneLayout ? 4 : cH(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: cW(14),
                runSpacing: cH(10),
                children: <Widget>[
                  _HubActionButton(
                    label: 'app.coup-denvoi-step3.gerer-equipe'.tr(),
                    onTap: () {
                      // Repart de la composition déjà attachée au match (ex.
                      // « Copier depuis un match précédent ») s'il y en a
                      // une, plutôt que de toujours repartir de zéro : on
                      // saute directement au placement (déjà rempli, prêt à
                      // être ajusté) au lieu de rejouer tout le sous-flux.
                      final MatchComposition? existing = draft.composition;
                      final CompositionDraftNotifier notifier = ref.read(
                        compositionDraftProvider.notifier,
                      );
                      if (existing != null) {
                        notifier.loadFromComposition(
                          existing,
                          maxSquad: ref.read(maxSquadSizeProvider).valueOrNull,
                        );
                        openGererScreen(
                          context,
                          kGererPlacementRoute,
                          () => const GererEquipePlacementScreen(),
                        );
                      } else {
                        startGererEquipeFlow(context, ref);
                      }
                    },
                  ),
                  _HubActionButton(
                    label: 'app.coup-denvoi-step3.parametrer-statistiques'.tr(),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ParametrerStatsScreen(),
                          ),
                        ),
                  ),
                  _HubActionButton(
                    label: 'app.coup-denvoi-step3.copier-match-precedent'.tr(),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'utils.choose'.tr(),
                          style: AppThemeStyle.regularStyle(
                            cFs(14),
                            AppColor.secondaryLabels,
                          ),
                        ),
                        Icon(
                          Iconsax.arrow_down_1_copy,
                          size: cIc(20),
                          color: AppColor.primaryLabels,
                        ),
                      ],
                    ),
                    onTap: _copyFromPreviousMatch,
                  ),
                ],
              ),
              cSh(isPhoneLayout ? 16 : 64),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _ownColumn(draft, coach)),
                  _centerColumn(ready),
                  Expanded(child: _opponentColumn(draft)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ownColumn(GameMatch draft, CoachProfile? coach) {
    // Nom + puces : d'abord l'état de préparation du match (composition /
    // joueurs / statistiques), puis l'identité de l'équipe (profil coach :
    // catégorie / division / coach), en miroir de la colonne adverse.
    final String name =
        (coach?.teamName?.trim().isNotEmpty ?? false)
            ? coach!.teamName!.trim()
            : 'app.coup-denvoi-step3.mon-equipe'.tr();
    final MatchComposition? comp = draft.composition;
    final List<Widget> chips = <Widget>[
      if (coach?.category != null) InfoChip(coach!.category!.label),
      if (coach?.division != null) InfoChip(coach!.division!.label),
      if (coach?.coachFirstName != null)
        InfoChip(
          'app.coup-denvoi-step3.coach'.tr(
            namedArgs: <String, String>{'prenom': coach!.coachFirstName!},
          ),
        ),
      if (comp != null) InfoChip(comp.formationLabel),
      if (comp != null)
        InfoChip(
          'app.coup-denvoi-step3.nb-joueurs'.tr(
            namedArgs: <String, String>{'n': '${comp.placedCount}'},
          ),
        ),
      if (draft.enabledStatKeys.isNotEmpty)
        InfoChip(
          'app.coup-denvoi-step3.nb-statistiques'.tr(
            namedArgs: <String, String>{'n': '${draft.enabledStatKeys.length}'},
          ),
        ),
    ];
    return Column(
      children: <Widget>[
        TeamLabelBadge('app.coup-denvoi-step3.mon-equipe'.tr()),
        cSh(14),
        TeamCrest(
          size: isPhoneLayout ? 72 : 92,
          color: draft.ownJersey?.color.color,
        ),
        cSh(14),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppThemeStyle.semiBStyle(cFs(21), AppColor.primaryLabels),
        ),
        if (chips.isNotEmpty) ...<Widget>[
          cSh(14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: cW(8),
            runSpacing: cH(8),
            children: chips,
          ),
        ],
      ],
    );
  }

  Widget _centerColumn(bool ready) {
    return Padding(
      padding: EdgeInsets.only(
        top: isPhoneLayout ? 2 : cH(24),
        left: isPhoneLayout ? 12 : cW(24),
        right: isPhoneLayout ? 12 : cW(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // « Mon adjoint » au milieu, entre les deux équipes, bien visible avant de lancer le match.
          const AdjointButton(),
          cSh(isPhoneLayout ? 8 : 18),
          const VsBadge(),
          cSh(isPhoneLayout ? 10 : 18),
          WizardCtaButton(
            label: 'app.coup-denvoi-step3.demarrer-match'.tr(),
            enabled: ready,
            onTap: () => _startMatch(),
          ),
          cSh(10),
          SizedBox(
            width: isPhoneLayout ? 150 : cW(210),
            child: Text(
              ready
                  ? 'app.coup-denvoi-step3.pret'.tr()
                  : 'app.coup-denvoi-step3.non-pret'.tr(),
              textAlign: TextAlign.center,
              style: AppThemeStyle.regularStyle(
                cFs(12),
                AppColor.secondaryLabels,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opponentColumn(GameMatch draft) {
    final String name =
        draft.opponent.name.isEmpty
            ? 'app.coup-denvoi-step3.equipe-adverse'.tr()
            : draft.opponent.name;
    return Column(
      children: <Widget>[
        TeamLabelBadge('app.coup-denvoi-step3.equipe-adverse'.tr()),
        cSh(14),
        TeamCrest(
          size: isPhoneLayout ? 72 : 92,
          color: draft.opponent.jerseyColor?.color,
        ),
        cSh(14),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppThemeStyle.semiBStyle(cFs(21), AppColor.primaryLabels),
        ),
        cSh(14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: cW(8),
          runSpacing: cH(8),
          children: <Widget>[
            if (draft.opponent.category != null)
              InfoChip(draft.opponent.category!.label),
            if (draft.opponent.division != null)
              InfoChip(draft.opponent.division!.label),
          ],
        ),
      ],
    );
  }
}

/// Bouton d'action du hub (pilule blanche + pastille fléchée verte ou
/// [trailing] personnalisé).
class _HubActionButton extends StatelessWidget {
  const _HubActionButton({
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final double badge = cIc(22);
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(cR(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(24)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cW(18), vertical: cH(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: AppThemeStyle.mediumStyle(
                  cFs(14),
                  AppColor.primaryLabels,
                ),
              ),
              cSw(10),
              trailing ??
                  SizedBox(
                    width: badge,
                    height: badge,
                    child: Icon(
                      Iconsax.arrow_circle_right,
                      size: cIc(13),
                      color: AppColor.primaryLabels,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
