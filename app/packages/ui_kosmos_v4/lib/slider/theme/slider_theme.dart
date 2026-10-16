import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'slider_theme.freezed.dart';

@freezed
class CustomSliderThemeData with _$CustomSliderThemeData {
  const factory CustomSliderThemeData({
    final Color? activeTrackColor,
    final Color? inactiveTrackColor,
    final Color? thumbColor,
    final double? trackHeight,
    final Color? shadowColor,
    final SliderComponentShape? overlayShape,
  }) = _CustomSliderThemeData;
}

final CustomSliderThemeData kDefaultSliderTheme = CustomSliderThemeData(
  activeTrackColor: DefaultColor.darkBlue,
  inactiveTrackColor: DefaultColor.grey,
  thumbColor: DefaultColor.darkBlue,
  shadowColor: Colors.transparent,
);
