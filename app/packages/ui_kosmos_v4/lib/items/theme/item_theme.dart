import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_theme.freezed.dart';

@freezed
class ItemThemeData with _$ItemThemeData {
  const factory ItemThemeData({
    final TextStyle? titleStyle,
    final TextStyle? contentStyle,
    final BoxDecoration? suffixDecoration,
    final Color? suffixIconColor,
    final TextStyle? sectionTitleStyle,
    final TextStyle? headTitleStyle,
  }) = _ItemThemeData;
}

final ItemThemeData kDefaultItemTheme = ItemThemeData(
  titleStyle: DefaultAppStyle.darkGrey(12, FontWeight.w400),
  contentStyle: DefaultAppStyle.darkSteel(13, FontWeight.w500),
  suffixDecoration: BoxDecoration(color: DefaultColor.darkBlue, borderRadius: BorderRadius.circular(7)),
  suffixIconColor: Colors.white,
  sectionTitleStyle: DefaultAppStyle.darkBlue(15, FontWeight.w600),
  headTitleStyle: DefaultAppStyle.darkBlue(16, FontWeight.w500),
);
