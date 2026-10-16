import 'package:flutter/material.dart';

class ClassicLoaderThemeData {
  final Color? activeColor;
  final Duration? duration;
  final double? radius;

  const ClassicLoaderThemeData({
    this.activeColor,
    this.duration,
    this.radius,
  });
}

class ProgressBarThemeData {
  final double? height;
  final Color? color;
  final Color? backColor;
  final Duration? duration;
  final TextStyle? style;
  final BorderRadiusGeometry? borderRadius;
  final TextStyle? percentageStyle;

  const ProgressBarThemeData({
    this.backColor,
    this.color,
    this.duration,
    this.height,
    this.style,
    this.borderRadius,
    this.percentageStyle,
  });
}
