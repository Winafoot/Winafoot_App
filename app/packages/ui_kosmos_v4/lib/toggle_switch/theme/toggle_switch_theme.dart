import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'toggle_switch_theme.freezed.dart';

const kDefaultToggleDuration = Duration(milliseconds: 200);
const kDefaultToggleCurves = Curves.linear;

/// {@category Theme}
/// 
@freezed
class KosmosToggleSwitchThemeData with _$KosmosToggleSwitchThemeData {
  const factory KosmosToggleSwitchThemeData({
    final TextStyle? selectedStyle,
    final TextStyle? unselectedStyle,
    final BoxDecoration? backBoxDecoration,
    final BoxDecoration? selectedDecoration,
    final Duration? animationDuration,
    final Curve? animationCurve,
  }) = _KosmosToggleSwitchThemeData;
}