import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/routes/app_router.gr.dart';

/// Bouton « Réglages » des entêtes : ouvre la page Paramètres déclarée dans
/// l'app router. On vise [ProfileParentRoute] sans enfant explicite : sa route
/// fille `settings` est `initial: true`, donc auto_route y redirige seul.
///
/// `navigate` (et non `push`) pour rester idempotent — un second appui revient
/// sur la page déjà empilée au lieu d'en ajouter une deuxième. L'écran couvre
/// la barre de navigation basse (qui vit dans `MonEquipeScreen`) ; on en
/// revient par le retour arrière.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => AutoRouter.of(context).navigate(const ProfileParentRoute()),
      child: Icon(
        Iconsax.setting_2,
        size: sp(24),
        color: AppColor.primaryLabels,
      ),
    );
  }
}
