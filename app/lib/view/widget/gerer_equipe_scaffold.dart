import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/custom_back_button.dart';

/// Ossature des écrans du sous-flux « Gérer mon équipe » : entête (retour +
/// icône équipe + « Gérer mon équipe » + logo), fond terrain, grand titre
/// (centré sans action, aligné à gauche avec [action] à droite), contenu.
class GererEquipeScaffold extends StatelessWidget {
  const GererEquipeScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
    this.action,
    this.leading,
    this.headerTrailing,
  });

  /// Grand titre de l'étape (ex. « Choisissez le nombre de joueurs »).
  final String title;
  final Widget child;
  final VoidCallback? onBack;

  /// Action en haut à droite (ex. bouton « Suivant » / « Valider »).
  final Widget? action;

  /// Widget aligné à gauche de la barre de titre (ex. boutons « Modifier »).
  /// Quand fourni, le titre est centré entre [leading] et [action].
  final Widget? leading;

  /// Widget placé dans l'entête, avant le logo (ex. compteur de sélection).
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const AppBackground(),
            Column(
              children: <Widget>[
                if (isPhoneLayout)
                  _PhoneBar(
                    title: title,
                    onBack: onBack,
                    leading: leading,
                    trailing: headerTrailing,
                    action: action,
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPhoneLayout ? 16 : cW(40),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        cSh(isPhoneLayout ? 8 : 18),
                        _Header(onBack: onBack, trailing: headerTrailing),
                        cSh(isPhoneLayout ? 6 : 14),
                        Container(height: 1, color: AppColor.divider),
                        cSh(isPhoneLayout ? 6 : 20),
                        if (action == null)
                          Center(child: _title())
                        else if (leading == null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(child: _title()),
                              action!,
                            ],
                          )
                        else
                          // Ligne et non Stack : avec des boutons « Modifier » plus
                          // larges, le titre centré en Stack passait dessous. Ici
                          // il prend la place restante et se réduit au besoin.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              leading!,
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isPhoneLayout ? 8 : cW(16),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: _title(),
                                  ),
                                ),
                              ),
                              action!,
                            ],
                          ),
                      ],
                    ),
                  ),
                cSh(isPhoneLayout ? 4 : 8),
                // PAS de `SingleChildScrollView` ici, contrairement au jumeau
                // `MatchWizardScaffold` : une contrainte de
                // hauteur non bornée casserait deux des six écrans hôtes —
                // gerer_equipe_numbers_screen (`Column > Expanded`) et
                // gerer_equipe_placement_screen (`Row(stretch)`). Le défaut
                // clavier y est latent : le seul écran à champ,
                // gerer_equipe_composition_screen, se protège déjà par le
                // `SingleChildScrollView` de `_CompositionsList`.
                Expanded(child: child),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _title() => Text(
    title,
    style: AppThemeStyle.semiBStyle(
      isPhoneLayout ? cFs(24) : cFs(30),
      AppColor.primaryLabels,
    ),
  );
}

/// Téléphone (paysage, ~360 dp de haut) : une seule barre au lieu de l'entête
/// à deux étages. Retour, « Gérer mon équipe » en légende au-dessus du titre de
/// l'étape, puis les actions. Le logo est retiré pour rendre la hauteur au
/// contenu ; la zone tactile du retour est de 44.
class _PhoneBar extends StatelessWidget {
  const _PhoneBar({
    required this.title,
    this.onBack,
    this.leading,
    this.trailing,
    this.action,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
          child: Row(
            children: <Widget>[
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Iconsax.arrow_circle_left,
                      size: 26,
                      color: AppColor.primaryLabels,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'app.gerer-equipe-scaffold.titre'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeStyle.regularStyle(
                        cFs(14),
                        AppColor.secondaryLabels,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeStyle.semiBStyle(
                        cFs(24),
                        AppColor.primaryLabels,
                      ),
                    ),
                  ],
                ),
              ),
              if (leading != null) ...<Widget>[
                const SizedBox(width: 8),
                leading!,
              ],
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                trailing!,
              ],
              if (action != null) ...<Widget>[
                const SizedBox(width: 8),
                action!,
              ],
            ],
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColor.divider,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onBack, this.trailing});

  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CustomBackButton(
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        cSw(7),
        Container(
          width: 1,
          height: isPhoneLayout ? 20 : cH(28),
          color: AppColor.divider,
        ),
        cSw(7),
        Icon(Iconsax.people, size: cIc(26), color: AppColor.primaryColor),
        cSw(10),
        Text(
          'app.gerer-equipe-scaffold.titre'.tr(),
          style: AppThemeStyle.semiBStyle(cFs(28), AppColor.primaryLabels),
        ),
        const Spacer(),
        if (trailing != null) ...<Widget>[trailing!, cSw(18)],
        WinaWordmark(size: isPhoneLayout ? 22 : 34),
      ],
    );
  }
}
