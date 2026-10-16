import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:skeleton/skeleton.dart';

part 'web_skeleton_theme.freezed.dart';

@freezed
class SkeletonWebThemeData with _$SkeletonWebThemeData {
  factory SkeletonWebThemeData({
    final BoxDecoration? footerDecoration,
    final double? footerItemSpacing,
    final TextStyle? footerItemStyle,
    final double? height,
  }) = _SkeletonWebThemeData;
}

final SkeletonWebThemeData kDefaultSkeletonWebThemeData = SkeletonWebThemeData(
  footerDecoration: BoxDecoration(color: DefaultColor.darkBlue),
  footerItemSpacing: formatWidth(50),
  footerItemStyle: DefaultAppStyle.white(18, FontWeight.w500).copyWith(decoration: TextDecoration.underline),
  height: formatHeight(70),
);
