import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';

/// Dialogue de confirmation standard : carte blanche arrondie, croix de
/// fermeture, titre + message centrés, bouton principal plein puis bouton
/// secondaire bordé (chacun avec une pastille fléchée). Reproduit le style des
/// popups du design (ex. « Quitter le match ? », « Supprimer ce joueur »).
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.primaryAccent,
    this.secondaryAccent,
  });

  final String title;
  final String message;

  /// Action « sûre » (bouton plein vert), ex. « Reprendre le match ».
  final String primaryLabel;
  final VoidCallback onPrimary;

  /// Action de sortie (bouton bordé), ex. « Quitter quand même ».
  final String secondaryLabel;
  final VoidCallback onSecondary;

  final Color? primaryAccent;
  final Color? secondaryAccent;

  @override
  Widget build(BuildContext context) {
    final Color primary = primaryAccent ?? AppColor.primaryColor;
    final Color secondary = secondaryAccent ?? AppColor.primaryLabels;
    return Dialog(
      backgroundColor: AppColor.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r(20))),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: formatWidth(470)),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: formatWidth(28),
                vertical: formatHeight(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppThemeStyle.semiBStyle(20, AppColor.primaryLabels),
                  ),
                  sh(12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppThemeStyle.regularStyle(
                      14,
                      AppColor.secondaryLabels,
                    ),
                  ),
                  sh(24),
                  _DialogButton(
                    label: primaryLabel,
                    filled: true,
                    accent: primary,
                    onTap: onPrimary,
                  ),
                  sh(12),
                  _DialogButton(
                    label: secondaryLabel,
                    filled: false,
                    accent: secondary,
                    onTap: onSecondary,
                  ),
                ],
              ),
            ),
            Positioned(
              top: formatHeight(10),
              right: formatWidth(10),
              child: InkWell(
                onTap: onPrimary,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(formatWidth(6)),
                  child: Icon(
                    Iconsax.close_circle,
                    size: sp(20),
                    color: AppColor.secondaryLabels,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton du dialogue : plein ou bordé, avec une pastille fléchée.
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.filled,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double badge = sp(22);
    final Color fg = filled ? AppColor.textLight : accent;
    final Color badgeBg = filled ? AppColor.textLight : accent;
    return Material(
      color: filled ? accent : AppColor.surface,
      borderRadius: BorderRadius.circular(r(28)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(28)),
        child: Container(
          decoration:
              filled
                  ? null
                  : BoxDecoration(
                    borderRadius: BorderRadius.circular(r(28)),
                    border: Border.all(color: AppColor.divider),
                  ),
          padding: EdgeInsets.symmetric(vertical: formatHeight(14)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(label, style: AppThemeStyle.semiBStyle(15, fg)),
              sw(10),
              SizedBox(
                width: badge,
                height: badge,
                child: Icon(
                  Iconsax.arrow_circle_right,
                  size: sp(13),
                  color: badgeBg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
