import 'package:flutter/material.dart';
import '../../checkbox/theme/checkbox_theme.dart';

class SelectorThemeData {
  final TextStyle? sideTextStyle;
  final CustomCheckBoxThemeData? checkboxTheme;
  final int maxLine;
  final double webMaxWidth;
  final double phoneMaxWidth;

  const SelectorThemeData({
    this.sideTextStyle,
    this.checkboxTheme,
    this.maxLine = 2,
    this.phoneMaxWidth = 294,
    this.webMaxWidth = 500,
  });
}