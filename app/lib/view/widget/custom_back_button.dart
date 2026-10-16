import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';

/// Bouton de retour circulaire partagé de l'app : chevron
/// [Iconsax.arrow_circle_left] en [AppColor.primaryLabels], dans un disque
/// transparent de 40 (icône de 24). Rendu et taille strictement identiques sur
/// tous les écrans — aucun paramètre de style ni de taille.
class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double d = formatWidth(40);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: d,
          height: d,
          child: Icon(
            Iconsax.arrow_circle_left,
            size: sp(24),
            color: AppColor.primaryLabels,
          ),
        ),
      ),
    );
  }
}
