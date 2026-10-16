import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert_theme.freezed.dart';

/// {@category Theme}
///
@freezed
class AlertTheme with _$AlertTheme {
  const factory AlertTheme({
    final BoxConstraints? constraints,
    final EdgeInsetsGeometry? padding,
    final Color? backgroundColor,
    final Color? infoBackground,
    final Color? successBackground,
    final Color? warningBackground,
    final Color? errorBackground,
    final BorderRadiusGeometry? borderRadius,
    final Border? border,
    final List<BoxShadow>? shadows,
    final TextStyle? textStyle,
    final TextStyle? subtitleStyle,
    final double? buttonWidth,
  }) = _AlertTheme;
}
