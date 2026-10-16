import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/custom_back_button.dart';
import 'package:wina/view/widget/header_divider.dart';
import 'package:wina/view/widget/whistle_icon.dart';

/// Entête commune des écrans de match (« Match en cours », les coupures
/// « Pause » / « Mi-temps » et « Match terminé ») : flèche retour optionnelle,
/// sifflet, titre, chrono, score et signature Wina, séparés par des
/// [HeaderDivider].
///
/// L'écran « Match en cours » insère ses contrôles interactifs (pilules pause /
/// mi-temps) via [controls] : la première pilule est accolée au chrono, les
/// suivantes sont séparées par un [HeaderDivider], comme le score.
class MatchHeader extends StatelessWidget {
  const MatchHeader({
    super.key,
    required this.title,
    required this.clock,
    required this.scoreUs,
    required this.scoreThem,
    this.onBack,
    this.clockFontSize = 24,
    this.controls = const <Widget>[],
  });

  final String title;
  final String clock;
  final int scoreUs;
  final int scoreThem;

  /// Flèche retour. `null` sur « Match terminé », qui n'en affiche pas.
  final VoidCallback? onBack;

  /// Taille du chrono. L'écran « Match en cours » l'affiche en 26, les coupures
  /// en 24.
  final double clockFontSize;

  /// Contrôles insérés entre le chrono et le score (pilules pause / mi-temps).
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (onBack != null) ...<Widget>[
          CustomBackButton(onTap: onBack!),
          sw(7),
          const HeaderDivider(),
          sw(7),
        ],
        WhistleIcon(size: sp(24), color: AppColor.primaryColor),
        sw(10),
        Text(
          title,
          style: AppThemeStyle.semiBStyle(24, AppColor.primaryLabels),
        ),
        sw(16),
        const HeaderDivider(),
        sw(16),
        Text(
          clock,
          style: AppThemeStyle.boldStyle(clockFontSize, AppColor.primaryColor),
        ),
        for (int i = 0; i < controls.length; i++) ...<Widget>[
          sw(16),
          if (i > 0) ...<Widget>[const HeaderDivider(), sw(16)],
          controls[i],
        ],
        sw(16),
        const HeaderDivider(),
        sw(16),
        Text(
          '$scoreUs - $scoreThem',
          style: AppThemeStyle.boldStyle(22, AppColor.primaryLabels),
        ),
        const Spacer(),
        const WinaWordmark(size: 30),
      ],
    );
  }
}
