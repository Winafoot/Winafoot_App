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

/// Fond plein écran + contenu dans la zone sûre : le visuel de terrain couvre tout l'écran (sous
/// l'encoche et la barre système, sans bordures), seul le contenu [child] évite les zones système.
///
/// À utiliser à la place de `SafeArea` dans le `body` d'un `Scaffold`, sans `AppBackground` dans le contenu.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AppBackground(),
        // Zone sûre SYMÉTRIQUE : en paysage l'encoche n'est que d'un côté, un SafeArea classique décalerait
        // le contenu ; on réserve la plus grande marge latérale des deux côtés pour le garder centré.
        // Plein cadre : le contenu garde la taille qu'il avait quand le fond était un de ses enfants.
        Builder(
          builder: (BuildContext context) {
            final EdgeInsets p = MediaQuery.paddingOf(context);
            // Les pages ont déjà ~16 dp de marge propre : on retire autant de la marge système pour que le contenu
            // démarre juste après l'encoche / la caméra (et pas 16 dp plus loin), des deux côtés.
            final double side =
                (p.left > p.right ? p.left : p.right) - 16 > 0
                    ? (p.left > p.right ? p.left : p.right) - 16
                    : 0;
            return Padding(
              padding: EdgeInsets.fromLTRB(side, p.top, side, p.bottom),
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                removeTop: true,
                removeRight: true,
                removeBottom: true,
                child: SizedBox.expand(child: child),
              ),
            );
          },
        ),
      ],
    );
  }
}
