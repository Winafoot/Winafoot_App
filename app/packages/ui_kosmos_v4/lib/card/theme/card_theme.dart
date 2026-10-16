import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_theme.freezed.dart';

@freezed
class KosmosCardThemeData with _$KosmosCardThemeData {
  factory KosmosCardThemeData({
    final BoxDecoration? cardDecoration,
    final EdgeInsetsGeometry? cardPadding,
    final TextStyle? titleTextStyle,
    final TextStyle? subtitleTextStyle,
    final Size? profilePictureSize,
    final BorderRadiusGeometry? imageBorderRadius,
    final BoxConstraints? cardConstraints,
    final Color? iconActionColor,
  }) = _KosmosCardThemeData;
}

final KosmosCardThemeData kDefaultCardThemeData = KosmosCardThemeData(
  titleTextStyle: DefaultAppStyle.darkBlue(12),
  subtitleTextStyle: DefaultAppStyle.grey(10, FontWeight.w400),
  cardDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        spreadRadius: 0,
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  imageBorderRadius: BorderRadius.circular(10),
  profilePictureSize: Size(formatWidth(30), formatWidth(30)),
);
