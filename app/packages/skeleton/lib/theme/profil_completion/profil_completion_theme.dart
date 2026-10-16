import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:skeleton/skeleton.dart';

part 'profil_completion_theme.freezed.dart';

@freezed
class ProfilCompletionThemeData with _$ProfilCompletionThemeData {
  const factory ProfilCompletionThemeData({
    final TextStyle? titleTextStyle,
    final TextStyle? subtitleTextStyle,
    final TextStyle? loaderTextStyle,
    final TextStyle? contentTextStyle,
  }) = _ProfilCompletionThemeData;
}

final ProfilCompletionThemeData kDefaultProfilCompletionThemeData =
    ProfilCompletionThemeData(
  titleTextStyle: DefaultAppStyle.darkBlue(23),
  subtitleTextStyle: DefaultAppStyle.darkBlue(16),
  contentTextStyle: DefaultAppStyle.darkGrey(12, FontWeight.w500),
  loaderTextStyle: DefaultAppStyle.darkGrey(16),
);
