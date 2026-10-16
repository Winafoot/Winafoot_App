import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';

/// Chemin du visuel de terrain utilisé en fond de tous les écrans de l'app.
const String kFieldBgAsset = 'assets/images/field_bg.webp';

/// Fond standard de l'app (calque « lin_bg » du Figma) : [kFieldBgAsset]
/// occupe la moitié basse de l'écran, et par-dessus un dégradé linéaire uni
/// (couleur de fond de l'app) opaque jusqu'à 64% de la hauteur, qui s'estompe
/// ensuite rapidement (92% → 82% → 65%) jusqu'à un voile léger (31%) en bas —
/// le visuel de terrain reste visible en filigrane, sans jamais redevenir cru
/// (assez de contraste pour lire les maillots posés dessus).
/// Stops exacts du Figma : 0% et 64% à 100%, 71% à 92%, 80% à 82%,
/// 87% à 65%, 100% à 31%.
///
/// À placer en première position d'une `Stack` (derrière le contenu).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.5,
              child: Image.asset(kFieldBgAsset, fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    AppColor.background,
                    AppColor.background,
                    AppColor.background.withValues(alpha: 0.92),
                    AppColor.background.withValues(alpha: 0.82),
                    AppColor.background.withValues(alpha: 0.65),
                    AppColor.background.withValues(alpha: 0.31),
                  ],
                  stops: const <double>[0.0, 0.64, 0.71, 0.80, 0.87, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
