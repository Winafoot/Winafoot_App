import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_theme.freezed.dart';

@freezed
class SkeletonSettingsThemeData with _$SkeletonSettingsThemeData {
  const factory SkeletonSettingsThemeData({
    final Color? actionIconColor,
  }) = _SkeletonSettingsThemeData;
}

final SkeletonSettingsThemeData kDefaultSkeletonSettingsThemeData = SkeletonSettingsThemeData(
  actionIconColor: DefaultColor.darkBlue,
);
