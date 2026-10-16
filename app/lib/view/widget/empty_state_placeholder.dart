import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';

/// État vide standard : icône optionnelle (en [AppColor.disabled]) + titre +
/// sous-titre optionnel, centrés. Reproduit les placeholders « Aucune
/// notification », « Aucun match joué », « Aucun résultat »…
class EmptyStatePlaceholder extends StatelessWidget {
  const EmptyStatePlaceholder({
    super.key,
    this.icon,
    this.iconSize = 48,
    required this.title,
    this.subtitle,
    this.titleSize = 16,
    this.padding,
  });

  final IconData? icon;
  final double iconSize;
  final String title;
  final String? subtitle;
  final double titleSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final Widget content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: sp(iconSize), color: AppColor.disabled),
            sh(14),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppThemeStyle.semiBStyle(titleSize, AppColor.primaryLabels),
          ),
          if (subtitle != null) ...<Widget>[
            sh(icon != null ? 6 : 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppThemeStyle.regularStyle(13, AppColor.secondaryLabels),
            ),
          ],
        ],
      ),
    );
    return padding == null
        ? content
        : Padding(padding: padding!, child: content);
  }
}
