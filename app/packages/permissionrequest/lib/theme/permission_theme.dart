import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_theme.freezed.dart';

/// {@category Theme}
/// {@category Permission}
///
/// Permet de définir le thème des permissions.
///
/// Par défaut, le package utilise la string suivante :
/// "permission"
@freezed
class PermissionThemeData with _$PermissionThemeData {
  const factory PermissionThemeData({
    final TextStyle? skipButtonStyle,
    final String? backButtonThemeName,
    final TextStyle? titleStyle,
    final TextStyle? descriptionStyle,
    final Size? childSize,
    final Size? logoSize,
    final Color? backgroundColor,
    final Gradient? backgroundGradient,
  }) = _PermissionThemeData;
}

final PermissionThemeData kDefaultPermissionTheme = PermissionThemeData(
  titleStyle: DefaultAppStyle.darkBlue(24),
  skipButtonStyle: DefaultAppStyle.darkBlue(14),
  descriptionStyle: DefaultAppStyle.steelGrey(13, FontWeight.w400),
);
