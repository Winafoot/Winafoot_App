import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'multi_image_picker_theme_data.freezed.dart';

@freezed
class MultiImagePickerThemeData with _$MultiImagePickerThemeData {
  const factory MultiImagePickerThemeData({
    final Color? deleteButtonColor,
    final double? itemSpacing,
    final double? itemRunSpacing,
    final EdgeInsetsGeometry? imageBoxPadding,
    final BorderRadiusGeometry? imageBoxBorderRadius,
    final Color? imageBoxColor,
    final double? imageBoxWidth,
    final double? imageBoxHeight,
  }) = _MultiImagePickerThemeData;
}

MultiImagePickerThemeData kDefaultMultiImagePickerTheme = MultiImagePickerThemeData(
  imageBoxWidth: formatWidth(142),
  imageBoxHeight: formatWidth(183),
  imageBoxPadding: EdgeInsets.all(formatWidth(6)),
  imageBoxBorderRadius: BorderRadius.circular(formatWidth(7)),
  imageBoxColor: const Color(0xFFF7F7F8),
  itemSpacing: formatWidth(25),
  deleteButtonColor: const Color(0xFFEB5353),
  itemRunSpacing: formatHeight(15),
);
