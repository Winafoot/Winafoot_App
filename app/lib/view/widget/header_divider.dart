import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';

/// Filet vertical de séparation des entêtes de page (après la flèche retour,
/// entre le titre, le chrono, le score…). 1 px de large, [height] de haut.
class HeaderDivider extends StatelessWidget {
  const HeaderDivider({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: formatHeight(height),
      color: AppColor.divider,
    );
  }
}
