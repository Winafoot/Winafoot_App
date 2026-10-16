import 'package:flutter/material.dart';

class NotifBannerThemeData {
  final Color? backgroundColor;
  final Duration? duration;
  final Duration? fadeDuration;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double? verticalPadding;
  final double? horizontalPadding;
  final BoxConstraints? webConstraints;
  final BoxConstraints? phoneConstraints;
  final List<BoxShadow>? shadow;
  final double? radius;

  const NotifBannerThemeData({
    this.backgroundColor,
    this.duration,
    this.subtitleStyle,
    this.titleStyle,
    this.fadeDuration,
    this.horizontalPadding,
    this.verticalPadding,
    this.phoneConstraints,
    this.webConstraints,
    this.shadow,
    this.radius,
  });
}
