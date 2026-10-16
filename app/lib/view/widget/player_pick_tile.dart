import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/player.dart';

/// Tuile de joueur sélectionnable : maillot au-dessus, nom en dessous, bordure
/// verte quand elle est retenue.
///
/// Partagée par les deux popups de la maquette qui font choisir un joueur —
/// « Remplacer un joueur » (match en direct) et « Choisissez un joueur à
/// placer » (placement de la composition). Les deux montrent la même tuile au
/// design ; la garder à un seul endroit évite qu'elles ne divergent.
class PlayerPickTile extends StatelessWidget {
  const PlayerPickTile({
    super.key,
    required this.player,
    required this.selected,
    required this.jerseyAsset,
    required this.onTap,
  });

  final Player player;
  final bool selected;
  final String jerseyAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: formatWidth(96),
        padding: EdgeInsets.symmetric(
          horizontal: formatWidth(8),
          vertical: formatHeight(8),
        ),
        decoration: BoxDecoration(
          color: AppColor.background,
          borderRadius: BorderRadius.circular(r(12)),
          border: Border.all(
            color: selected ? AppColor.primaryColor : AppColor.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(jerseyAsset, width: sp(34), height: sp(34)),
            sh(6),
            Text(
              player.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.mediumStyle(
                11,
                selected ? AppColor.primaryColor : AppColor.primaryLabels,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
