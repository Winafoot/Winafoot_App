import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

part 'button_theme.freezed.dart';

/// {@category Theme}
///
@freezed
class KosmosButtonThemeData with _$KosmosButtonThemeData {
  const factory KosmosButtonThemeData({
    final ClassicLoaderThemeData? loaderTheme,
    final Widget? backButtonIcon,

    /// This widget is placed inside a Stack before the button,
    /// so it is considered as the background of the button.
    final Widget? backgroundWidget,
    final BoxConstraints? constraints,
    final BoxDecoration? decoration,
    final EdgeInsetsGeometry? padding,
    final double? width,
    final double? height,
    final Clip? clip,
    final TextStyle? buttonTextStyle,
    final Color? iconColor,
    final double? iconSize,
  }) = _KosmosButtonThemeData;
}

final KosmosButtonThemeData kDefaultButtonThemeData = KosmosButtonThemeData(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(r(8)),
    color: DefaultColor.darkBlue,
  ),
  height: formatHeight(54),
  width: double.infinity,
  buttonTextStyle: DefaultAppStyle.white(16),
);
