import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
///
/// Permet d'afficher un titre avec un bouton de retour.
/// Vous pouvez également ajouter un suffixe à droite du titre.
///
/// Exemple:
///
/// ![title_header](../../images/header/header_title.png)
///
class TitleHeader extends StatelessWidget {
  /// Title
  final String? title;
  final Widget? titleWidget;

  final double? heightSize;

  /// Suffix (optional)
  final Widget? suffix;

  /// Back Button
  final EdgeInsetsGeometry? backButtonPadding;
  final VoidCallback? onTapBack;

  /// Theme
  final TextStyle? titleStyle;
  final BoxConstraints? titleConstraints;

  const TitleHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.suffix,
    this.titleStyle,
    this.titleConstraints,
    this.backButtonPadding,
    this.onTapBack,
    this.heightSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: heightSize ?? formatWidth(40),
      child: Stack(
        children: [
          if (titleWidget != null || title != null)
            Positioned(
              top: 0,
              bottom: 0,
              left: formatWidth(27.5),
              right: formatWidth(27.5),
              child: Center(
                child: ConstrainedBox(
                  constraints: titleConstraints ?? BoxConstraints(maxWidth: formatWidth(340)),
                  child: titleWidget ?? Text(title!, style: titleStyle ?? DefaultAppStyle.darkBlue(16)),
                ),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ButtonBack(
              padding: backButtonPadding ?? EdgeInsets.symmetric(horizontal: formatWidth(27.5), vertical: formatWidth(4)),
              onTap: onTapBack,
            ),
          ),
          if (suffix != null) Positioned(right: 0, top: 0, bottom: 0, child: suffix!),
        ],
      ),
    );
  }
}
