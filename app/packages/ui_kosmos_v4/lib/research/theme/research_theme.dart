import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'research_theme.freezed.dart';

/// {@category Theme}
/// {@subCategory Research}
@freezed
class KosmosRechercheThemeData with _$KosmosRechercheThemeData {
  const factory KosmosRechercheThemeData({
    /// SearchBar
    final String? searchBarThemeName,
    final InputDecoration? searchBarDecoration,
    final Color? suffixIconColor,
    final double? horizontalPadding,
    final double? itemsHorizontalPadding,

    /// Item Builder
    final TextStyle? noItemTilteTexStyle,
    final TextStyle? noItemContentTexStyle,
    final Color? noItemBackgroundIconColor,
    final Color? noItemIconColor,

    /// Filter
    final double? filterHeight,
  }) = _KosmosRechercheThemeData;
}

final KosmosRechercheThemeData kDefaultKosmosRechercheTheme =
    KosmosRechercheThemeData(
  horizontalPadding: formatWidth(27.5),
  noItemTilteTexStyle: DefaultAppStyle.darkBlue(22),
  noItemContentTexStyle: DefaultAppStyle.darkGrey(13, FontWeight.w400),
  noItemBackgroundIconColor: DefaultColor.darkBlue,
  filterHeight: formatHeight(35),
);
