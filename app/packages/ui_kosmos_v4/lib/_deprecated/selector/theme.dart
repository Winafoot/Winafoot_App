import 'package:flutter/material.dart';
import '../checkbox/theme.dart';

class SelectorThemeData {
  final TextStyle? contentStyle;
  final CustomCheckBoxThemeData? checkboxTheme;
  final double spacing;
  final int maxLine;
  final double webMaxWidth;
  final double phoneMaxWidth;

  const SelectorThemeData({
    this.contentStyle,
    this.checkboxTheme,
    this.spacing = 14,
    this.maxLine = 3,
    this.phoneMaxWidth = 294,
    this.webMaxWidth = 500,
  });
}
