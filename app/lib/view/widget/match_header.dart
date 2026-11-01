import 'package:flutter/material.dart';
import 'package:wina/config/phone_scale.dart';
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
    this.trailing,
    this.middle,
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

  /// Bouton accolé au score. Sur téléphone (écran de direct) il remplace la
  /// signature Wina pour laisser la place aux contrôles agrandis.
  final Widget? trailing;

  /// Contenu centré entre [trailing] et le logo (téléphone : joueur sélectionné).
  final Widget? middle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (onBack != null) ...<Widget>[
          CustomBackButton(onTap: onBack!),
          cSw(7),
          const HeaderDivider(),
          cSw(7),
        ],
        WhistleIcon(size: cIc(24), color: AppColor.primaryColor),
        // Écran de direct : pas de titre (le chrono, le score et les
        // deux pilules occupent déjà toute la largeur).
        if (controls.isEmpty) ...<Widget>[
          cSw(10),
          Text(
            title,
            style: AppThemeStyle.semiBStyle(cFs(24), AppColor.primaryLabels),
          ),
        ],
        cSw(16),
        const HeaderDivider(),
        cSw(16),
        Text(
          clock,
          style: AppThemeStyle.boldStyle(
            cFs(clockFontSize),
            AppColor.primaryColor,
          ),
        ),
        for (int i = 0; i < controls.length; i++) ...<Widget>[
          cSw(16),
          if (i > 0) ...<Widget>[const HeaderDivider(), cSw(16)],
          controls[i],
        ],
        cSw(16),
        const HeaderDivider(),
        cSw(16),
        Text(
          '$scoreUs - $scoreThem',
          style: AppThemeStyle.boldStyle(
            cFs(controls.isNotEmpty ? 26 : 22),
            AppColor.primaryLabels,
          ),
        ),
        if (trailing != null) ...<Widget>[cSw(8), trailing!],
        // Le logo reste visible sur téléphone : il se réduit s'il manque de place.
        if (middle != null) ...<Widget>[
          cSw(8),
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: middle),
            ),
          ),
          cSw(8),
          WinaWordmark(size: isPhoneLayout ? 24 : 30),
        ] else
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: WinaWordmark(size: isPhoneLayout ? 24 : 30),
              ),
            ),
          ),
      ],
    );
  }
}
