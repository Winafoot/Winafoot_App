import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      sh(18),
                      _Header(onBack: onBack, trailing: headerTrailing),
                      sh(14),
                      Container(height: 1, color: AppColor.divider),
                      sh(20),
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
                        Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: leading!,
                            ),
                            _title(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: action!,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                sh(8),
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

  Widget _title() =>
      Text(title, style: AppThemeStyle.semiBStyle(30, AppColor.primaryLabels));
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
        sw(7),
        Container(width: 1, height: formatHeight(28), color: AppColor.divider),
        sw(7),
        Icon(Iconsax.people, size: sp(26), color: AppColor.primaryColor),
        sw(10),
        Text(
          'app.gerer-equipe-scaffold.titre'.tr(),
          style: AppThemeStyle.semiBStyle(28, AppColor.primaryLabels),
        ),
        const Spacer(),
        if (trailing != null) ...<Widget>[trailing!, sw(18)],
        const WinaWordmark(size: 34),
      ],
    );
  }
}
