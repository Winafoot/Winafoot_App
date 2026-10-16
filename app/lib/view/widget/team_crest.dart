import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Chemin de l'écusson (bouclier) d'équipe.
const String kCrestAsset = 'assets/svg/crest_shield.svg';

/// Écusson d'équipe (bouclier). Neutre (gris) par défaut ; teinté de la couleur
/// d'équipe ([color]) — typiquement la couleur du maillot — quand fournie.
class TeamCrest extends StatelessWidget {
  const TeamCrest({super.key, this.color, this.size = 92});

  /// Teinte appliquée à l'écusson (couleur du maillot). `null` = écusson neutre.
  final Color? color;

  /// Largeur logique (design 1194×834) — la hauteur suit le ratio du bouclier.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      kCrestAsset,
      width: formatWidth(size),
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}
