import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme.freezed.dart';

@freezed
class ClassicLoaderThemeData with _$ClassicLoaderThemeData {
  const factory ClassicLoaderThemeData({
    final Color? activeColor,
    final Duration? duration,
    final double? radius,
  }) = _ClassicLoaderThemeData;
}

const ClassicLoaderThemeData kDefaultLoaderTheme = ClassicLoaderThemeData(
  activeColor: Colors.white,
  duration: Duration(milliseconds: 800),
  radius: 15,
);
