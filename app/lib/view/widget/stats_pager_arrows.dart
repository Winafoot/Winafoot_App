import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';

/// Flèches ‹ › de pagination des colonnes de statistiques : avancent ou
/// reculent d'une largeur de fenêtre ; grisées en butée. Partagé par le bilan
/// individuel et l'écran de coupure (« Si Pause 2 »).
class StatsPagerArrows extends StatelessWidget {
  const StatsPagerArrows({super.key, required this.controller});

  final ScrollController controller;

  void _page(double direction) {
    if (!controller.hasClients) return;
    final ScrollPosition position = controller.position;
    final double target = (controller.offset +
            direction * position.viewportDimension)
        .clamp(0.0, position.maxScrollExtent);
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _arrow(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      // Zone tactile portée au minimum ergonomique (48x48 dp) : l'icône garde
      // sa taille, seule la surface cliquable grandit autour.
      child: SizedBox(
        width: kMinInteractiveDimension,
        height: kMinInteractiveDimension,
        child: Center(
          child: Icon(
            icon,
            size: sp(24),
            color: enabled ? AppColor.primaryLabels : AppColor.disabled,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final bool canGoLeft = controller.hasClients && controller.offset > 0;
        final bool canGoRight =
            !controller.hasClients ||
            controller.offset < controller.position.maxScrollExtent - 0.5;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _arrow(Iconsax.arrow_circle_left, canGoLeft, () => _page(-1)),
            // 39 d'origine moins les 24 de marge tactile ajoutés entre les deux
            // icônes : l'écart visuel reste celui de la maquette.
            sw(15),
            _arrow(Iconsax.arrow_circle_right, canGoRight, () => _page(1)),
          ],
        );
      },
    );
  }
}
