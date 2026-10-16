import 'package:flutter/material.dart';

class CustomCheckBoxThemeData {
  final double? borderRadius;
  final Color? selectedColor;
  final Color? selectedIconColor;
  final Color? defaultColor;
  final Duration? animationDuration;
  final BoxBorder? border;

  const CustomCheckBoxThemeData({
    this.selectedColor,
    this.borderRadius,
    this.defaultColor,
    this.selectedIconColor,
    this.animationDuration,
    this.border,
  });
}
