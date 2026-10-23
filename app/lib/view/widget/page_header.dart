import 'package:flutter/material.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/custom_back_button.dart';
import 'package:wina/view/widget/header_divider.dart';

/// Entête de haut de page : icône de section, titre et signature Wina.
///
/// Selon l'écran, une flèche retour ([onBack]) précède l'icône — accolée à
/// celle-ci ([backDivider] à `false`) ou séparée par un [HeaderDivider]
/// ([backDivider] à `true`) — et des [actions] (cloche, réglages…) peuvent
/// s'insérer avant la signature.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconSize = 26,
    this.onBack,
    this.backDivider = false,
    this.actions = const <Widget>[],
  });

  final IconData icon;
  final String title;
  final double iconSize;

  /// Flèche retour optionnelle. `null` sur les écrans racines (onglets).
  final VoidCallback? onBack;

  /// Sépare la flèche retour de l'icône par un [HeaderDivider] plutôt que par
  /// un simple espace.
  final bool backDivider;

  /// Widgets insérés entre le titre et la signature (cloche, réglages…).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (onBack != null) ...<Widget>[
          CustomBackButton(onTap: onBack!),
          if (backDivider) ...<Widget>[
            cSw(7),
            const HeaderDivider(),
            cSw(7),
          ] else
            cSw(14),
        ],
        Icon(icon, size: cIc(iconSize), color: AppColor.primaryColor),
        cSw(10),
        Text(
          title,
          style: AppThemeStyle.semiBStyle(cFs(28), AppColor.primaryLabels),
        ),
        const Spacer(),
        ...actions,
        const WinaWordmark(size: 34),
      ],
    );
  }
}
