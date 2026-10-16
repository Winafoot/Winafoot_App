import 'package:flutter/material.dart';

class TmpSettingsCelluleThemeData {
  final MaterialStateProperty<OutlinedBorder?>? shape;

  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? activeTitleStyle;
  final TextStyle? activeSubtitleStyle;

  final double? radius;
  final double? imageWidth;
  final double? imageHeight;
  final double? verticalPadding;
  final double? horizontalPadding;

  final BoxConstraints? constraints;

  final Color? overlayColor;

  final Color? iconColor;
  final Color? backgroundColor;
  final Color? iconBackgroundColor;
  final Color? activeIconColor;
  final Color? activeBackgroundColor;
  final Color? activeIconBackgroundColor;

  final Gradient? backgroundGradient;
  final Gradient? iconBackgroundGradient;
  final Gradient? activeBackgroundGradient;
  final Gradient? activeIconBackgroundGradient;

  const TmpSettingsCelluleThemeData({
    this.shape,
    this.titleStyle,
    this.subtitleStyle,
    this.activeTitleStyle,
    this.activeSubtitleStyle,
    this.radius,
    this.imageWidth,
    this.imageHeight,
    this.verticalPadding,
    this.horizontalPadding,
    this.constraints,
    this.overlayColor,
    this.iconColor,
    this.backgroundColor,
    this.iconBackgroundColor,
    this.activeIconColor,
    this.activeBackgroundColor,
    this.activeIconBackgroundColor,
    this.backgroundGradient,
    this.iconBackgroundGradient,
    this.activeBackgroundGradient,
    this.activeIconBackgroundGradient,
  });
}
