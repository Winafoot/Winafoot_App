import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'picker_theme.freezed.dart';

/// {@category Theme}
///
@freezed
class KosmosDatePickerThemeData with _$KosmosDatePickerThemeData {
  const factory KosmosDatePickerThemeData({
    final BoxDecoration? boxDecoration,
    final BoxConstraints? boxConstraints,
    final EdgeInsetsGeometry? boxPadding,
    final TextStyle? dayTextStyle,
    final TextStyle? dateTextStyle,
    final TextStyle? lockedDateTextStyle,
    final TextStyle? otherMonthDateTextStyle,
    final TextStyle? activeDateTextStyle,
    final TextStyle? defaultDateTextStyle,
    final Color? dateNavigationButtonColor,
    final BoxDecoration? activeDateBackgroundDecoration,
    final BoxDecoration? activeRangeDateBackgroundDecoration,
    final BoxDecoration? inactiveDateBackgroundDecoration,
    final BoxDecoration? rangeDataInfoDecoration,
    final BoxDecoration? rangeDataInfoActiveDecoration,
    final TextStyle? rangeDataInfoActiveTextStyle,
    final TextStyle? rangeDataInfoTextStyle,
  }) = _KosmosDatePickerThemeData;
}

/// {@category Theme}
///
final kDefaultDatePickerTheme = KosmosDatePickerThemeData(
  boxConstraints: BoxConstraints(maxWidth: formatWidth(420)),
  boxPadding: EdgeInsets.all(formatWidth(16)),
  boxDecoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r(13))),
  dayTextStyle: DefaultAppStyle.darkBlue(13).copyWith(color: DefaultColor.darkBlue.withOpacity(.5)),
  dateTextStyle: DefaultAppStyle.darkBlue(14),
  dateNavigationButtonColor: DefaultColor.darkBlue.withOpacity(.5),
  activeDateBackgroundDecoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(5)),
  activeRangeDateBackgroundDecoration: BoxDecoration(color: Colors.black.withOpacity(.15), borderRadius: BorderRadius.circular(5)),
  inactiveDateBackgroundDecoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(5)),
  lockedDateTextStyle: DefaultAppStyle.darkBlue(13).copyWith(color: DefaultColor.darkBlue.withOpacity(.5)),
  otherMonthDateTextStyle: DefaultAppStyle.darkBlue(13, FontWeight.w400).copyWith(color: DefaultColor.darkBlue.withOpacity(.5)),
  activeDateTextStyle: DefaultAppStyle.white(13, FontWeight.w400),
  defaultDateTextStyle: DefaultAppStyle.darkBlue(13, FontWeight.w400),
);
