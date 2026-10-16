import 'package:flutter/widgets.dart';

const kDefaultCheckDuration = Duration(milliseconds: 100);
const kDefaultCheckCurves = Curves.easeInOutCirc;

class CustomCheckBoxThemeData {
  final Color? borderColor;
  final Color? checkedColor;
  final Color? uncheckedColor;
  final Color? iconColor;
  final BoxBorder? border;
  final Duration? animationDuration;
  final Curve? animationCurve;
  final Gradient? gradient;

  const CustomCheckBoxThemeData({
    this.borderColor,
    this.checkedColor,
    this.uncheckedColor,
    this.iconColor,
    this.border,
    this.animationDuration,
    this.animationCurve,
    this.gradient,
  });
}
