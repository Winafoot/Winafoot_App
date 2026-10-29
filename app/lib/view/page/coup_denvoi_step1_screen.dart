import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/view/page/coup_denvoi_step2_screen.dart';
import 'package:wina/view/widget/adjoint_button.dart';
import 'package:wina/view/widget/match_wizard.dart';
import 'package:wina/view/widget/team_crest.dart';

/// Assistant « Coup d'envoi » — étape 1 : choix de l'adversaire.
///
/// Colonne « Mon équipe » (alimentée par le profil coach) vs colonne « Équipe
/// adverse » (nom saisi + catégorie / division). « Suivant » désactivé tant
/// qu'aucun nom d'adversaire n'est saisi.
class CoupDEnvoiStep1Screen extends ConsumerStatefulWidget {
  const CoupDEnvoiStep1Screen({super.key});

  @override
  ConsumerState<CoupDEnvoiStep1Screen> createState() =>
      _CoupDEnvoiStep1ScreenState();
}

class _CoupDEnvoiStep1ScreenState extends ConsumerState<CoupDEnvoiStep1Screen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(matchDraftProvider).opponent.name,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CoachProfile? coach = ref.watch(coachProfileProvider).valueOrNull;
    final GameMatch draft = ref.watch(matchDraftProvider);
    final MatchDraftNotifier notifier = ref.read(matchDraftProvider.notifier);

    final TeamCategory? category = draft.opponent.category ?? coach?.category;
    final TeamDivision? division = draft.opponent.division ?? coach?.division;

    return MatchWizardScaffold(
      title: 'app.coup-denvoi-step1.titre'.tr(),
      onBack: () => Navigator.of(context).maybePop(),
      bottomCta: WizardCtaButton(
        label: 'app.coup-denvoi-step1.suivant'.tr(),
        enabled: draft.isOpponentValid,
        onTap: () {
          // L'adversaire hérite par défaut de la catégorie / division de
          // l'équipe si le coach ne les a pas modifiées.
          if (draft.opponent.category == null && coach?.category != null) {
            notifier.setOpponentCategory(coach!.category!);
          }
          if (draft.opponent.division == null && coach?.division != null) {
            notifier.setOpponentDivision(coach!.division!);
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CoupDEnvoiStep2Screen(),
            ),
          );
        },
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhoneLayout ? 16 : cW(40),
            vertical: isPhoneLayout ? 4 : cH(80),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _ownColumn(coach)),
              // Centre : bouton « Mon adjoint » en haut (entre les deux noms d'équipe), « VS » dessous.
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isPhoneLayout ? 12 : cW(24),
                ),
                child: Column(
                  children: <Widget>[
                    const AdjointButton(),
                    SizedBox(height: isPhoneLayout ? 10 : cH(40)),
                    const VsBadge(),
                  ],
                ),
              ),
              Expanded(child: _opponentColumn(notifier, category, division)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ownColumn(CoachProfile? coach) {
    return Column(
      children: <Widget>[
        TeamLabelBadge('app.coup-denvoi-step1.mon-equipe'.tr()),
        cSh(14),
        // Téléphone : sans écusson, pour tenir dans la hauteur sans défiler.
        if (!isPhoneLayout) ...<Widget>[TeamCrest(size: 92), cSh(14)],
        // Nom figé (grisé, non cliquable) : seul celui de l'adversaire se saisit.
        Container(
          width: isPhoneLayout ? 230 : cW(300),
          padding: EdgeInsets.symmetric(horizontal: cW(14), vertical: cH(10)),
          decoration: BoxDecoration(
            color: AppColor.divider.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(cR(12)),
          ),
          child: Text(
            coach?.teamName ?? 'app.coup-denvoi-step1.mon-equipe'.tr(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(cFs(21), AppColor.secondaryLabels),
          ),
        ),
        cSh(14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: cW(8),
          runSpacing: cH(8),
          children: <Widget>[
            if (coach?.category != null) InfoChip(coach!.category!.label),
            if (coach?.division != null) InfoChip(coach!.division!.label),
            if (coach?.coachFirstName != null)
              InfoChip(
                'app.coup-denvoi-step1.coach'.tr(
                  namedArgs: <String, String>{'prenom': coach!.coachFirstName!},
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _opponentColumn(
    MatchDraftNotifier notifier,
    TeamCategory? category,
    TeamDivision? division,
  ) {
    return Column(
      children: <Widget>[
        TeamLabelBadge('app.coup-denvoi-step1.equipe-adverse'.tr()),
        cSh(14),
        if (!isPhoneLayout) ...<Widget>[TeamCrest(size: 92), cSh(14)],
        SizedBox(
          // Même largeur que les pilules Catégorie/Division juste en dessous :
          // sans borne, `IntrinsicWidth` laissait le nom déborder de l'écran.
          width: isPhoneLayout ? 230 : cW(300),
          // Encadré + crayon : signale que le nom est à taper.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(cR(12)),
              border: Border.all(color: AppColor.primaryColor, width: 1.5),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: cW(14),
                vertical: cH(10),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _name,
                      textAlign: TextAlign.center,
                      minLines: 1,
                      maxLines: 2,
                      maxLength: 40,
                      // Deux lignes pour l'affichage seulement : sans ces deux réglages,
                      // Flutter traite le champ en multi-lignes et Entrée insère un saut
                      // de ligne dans le nom au lieu de valider la saisie.
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      cursorColor: AppColor.primaryColor,
                      style: AppThemeStyle.semiBStyle(
                        cFs(21),
                        AppColor.primaryLabels,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'app.coup-denvoi-step1.hint-nom-equipe'.tr(),
                        hintStyle: AppThemeStyle.mediumStyle(
                          cFs(21),
                          AppColor.secondaryLabels,
                        ),
                      ),
                      onChanged: notifier.setOpponentName,
                    ),
                  ),
                  cSw(8),
                  Icon(
                    Iconsax.edit_2,
                    size: cIc(20),
                    color: AppColor.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        cSh(18),
        SizedBox(
          width: isPhoneLayout ? 230 : cW(300),
          child: LabeledPillDropdown<TeamCategory>(
            label: 'app.coup-denvoi-step1.categorie'.tr(),
            value: category,
            values: TeamCategory.values,
            labelOf: (TeamCategory c) => c.label,
            onChanged: notifier.setOpponentCategory,
          ),
        ),
        cSh(10),
        SizedBox(
          width: isPhoneLayout ? 230 : cW(300),
          child: LabeledPillDropdown<TeamDivision>(
            label: 'app.coup-denvoi-step1.division'.tr(),
            value: division,
            values: TeamDivision.values,
            labelOf: (TeamDivision d) => d.name.toUpperCase(),
            onChanged: notifier.setOpponentDivision,
          ),
        ),
      ],
    );
  }
}
