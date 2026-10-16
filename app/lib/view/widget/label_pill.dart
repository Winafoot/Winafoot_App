import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';

/// Petite pilule d'étiquette arrondie (schéma de formation, libellé court).
///
/// Les écrans en ajustent la couleur, la taille de texte et les marges via les
/// paramètres optionnels ; par défaut, chip gris clair, texte 12.
class LabelPill extends StatelessWidget {
  const LabelPill(
    this.label, {
    super.key,
    this.color,
    this.fontSize = 12,
    this.horizontalPadding = 12,
    this.verticalPadding = 5,
  });

  final String label;
  final Color? color;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(horizontalPadding),
        vertical: formatHeight(verticalPadding),
      ),
      decoration: BoxDecoration(
        color: color ?? AppColor.chipBackground,
        borderRadius: BorderRadius.circular(r(12)),
      ),
      child: Text(
        label,
        style: AppThemeStyle.semiBStyle(fontSize, AppColor.primaryLabels),
      ),
    );
  }
}
