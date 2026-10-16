import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'theme/alert_theme.dart';

enum AlertType {
  info,
  success,
  warning,
  error,
}

/// {@category Widget}
///
/// Box contenant un message d'alerte.
/// Il exitse plusieurs types d'alerte prédéfinis :
/// - [AlertType.info] : Message d'information (Bleu défini par [DefaultColor.info])
/// - [AlertType.success] : Message de succès (Vert défini par [DefaultColor.success])
/// - [AlertType.warning] : Message d'avertissement (Orange défini par [DefaultColor.warning])
/// - [AlertType.error] : Message d'erreur (Rouge défini par [DefaultColor.error])
///
/// Vous pouvez toutes fois customiser ou créer votre propre type d'alerte en passant par le [AlertTheme].
/// Par défaut, l'alerte est de type [AlertType.error].
///
/// Exemple :
///
/// ![alert_example](../../images/alert/alert_example.png)
///
/// ```dart
/// AlertMessage(
///   content:
///       "Texte d'exemple",
///   width: formatWidth(200), // Optionel, double.infinity par défaut
/// ),
/// AlertMessage(
///   content:
///       "Texte d'exemple",
///   type: AlertType.info, // Optionel, AlertType.error par défaut
/// ),
/// ```
class AlertMessage extends ConsumerWidget {
  final String content;
  final AlertType type;

  final double? width;

  /// Theme
  final String? themeName;
  final AlertTheme? theme;

  final TextStyle? textStyle;

  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final Border? border;
  final List<BoxShadow>? shadows;

  const AlertMessage({
    Key? key,
    required this.content,
    this.type = AlertType.error,
    this.width,

    /// Theme
    this.themeName,
    this.theme,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.constraints,
    this.padding,
    this.shadows,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getColorFromType();
    final themeData = loadThemeData(
      theme,
      themeName ?? "alert_message",
      () => const AlertTheme(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    return Container(
      width: width ?? double.infinity,
      constraints: constraints ?? themeData.constraints,
      padding: padding ??
          themeData.padding ??
          EdgeInsets.fromLTRB(formatWidth(14), formatHeight(9), formatWidth(7),
              formatHeight(9)),
      decoration: BoxDecoration(
        color: backgroundColor ??
            themeData.backgroundColor ??
            color.withOpacity(0.13),
        borderRadius: borderRadius ??
            themeData.borderRadius ??
            BorderRadius.circular(r(9)),
        border: border ?? themeData.border,
        boxShadow: shadows ?? themeData.shadows,
      ),
      child: Row(
        children: [
          SvgPicture.asset("assets/svg/ic_info.svg",
              package: "ui_kosmos_v4", color: color),
          sw(13),
          Flexible(
              child: Text(content,
                  style:
                      textStyle ?? themeData.textStyle ?? _getStyleFromType(),
                  textAlign: TextAlign.left)),
        ],
      ),
    );
  }

  Color _getColorFromType() {
    return {
      AlertType.info: DefaultColor.info,
      AlertType.success: DefaultColor.success,
      AlertType.warning: DefaultColor.warning,
      AlertType.error: DefaultColor.error,
    }[type]!;
  }

  TextStyle _getStyleFromType() {
    return {
      AlertType.info: DefaultAppStyle.info(11, FontWeight.w500),
      AlertType.success: DefaultAppStyle.success(11, FontWeight.w500),
      AlertType.warning: DefaultAppStyle.warning(11, FontWeight.w500),
      AlertType.error: DefaultAppStyle.error(11, FontWeight.w500),
    }[type]!;
  }
}
