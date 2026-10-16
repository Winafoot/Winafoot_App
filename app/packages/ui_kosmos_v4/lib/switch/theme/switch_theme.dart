import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'switch_theme.freezed.dart';

/// {@category Theme}
///
/// Permet de configurer le thème du [KosmosSwitch].
@freezed
class KosmosSwitchThemeData with _$KosmosSwitchThemeData {
  const factory KosmosSwitchThemeData({
    final double? padding,
    final Color? trackColor,
    final Color? activeTrackColor,
    final Color? thumbColor,
    final Gradient? activeGradient,
  }) = _KosmosSwitchThemeData;
}

final kDefaultSwitch = KosmosSwitchThemeData(
  padding: 4,
  trackColor: const Color(0xFFBFC3C9),
  activeTrackColor: DefaultColor.darkBlue,
  thumbColor: Colors.white,
);
