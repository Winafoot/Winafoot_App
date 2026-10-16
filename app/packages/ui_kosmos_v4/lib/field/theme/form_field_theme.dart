import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_field_theme.freezed.dart';

/// {@category Theme}
///
@freezed
class FormFieldThemeData with _$FormFieldThemeData {
  const factory FormFieldThemeData({
    final TextStyle? fieldNameStyle,
    final TextStyle? fieldNameErrorStyle,
    final TextStyle? fieldActionStyle,
    final TextStyle? fieldActionHoverStyle,
    final TextStyle? fieldTextStyle,
    final TextStyle? fieldPinStyle,

    // Phone number box

    final TextStyle? searchCountryLabelStyle,
    final InputBorder? searchCountryBorder,
    // -----------
    final TextStyle? subItemFieldTextStyle,
    final InputDecoration? inputDecoration,
    final EdgeInsets? imagePickerContentPadding,
    final EdgeInsets? filePickerContentPadding,
    final double? imagePickerImageHeight,
    final Color? dropdownColor,
    final BorderRadius? dropdownBorderRadius,

    // Pin code box
    final double? fieldPinHeight,
    final double? fieldPinWidth,
    final double? fieldPinRadius,

    // passwords Icons eyes
    final Widget? passwordShowIcon,
    final Widget? passwordHideIcon,

    /// Affiche l'astérisque "*" sur les champs requis. `null` = true.
    final bool? showRequiredIndicator,

    /// Drapeau du sélecteur de pays (FormPhoneNumberField) : emoji si
    /// `true`/`null`, image rectangulaire sinon.
    final bool? phoneSelectorUseEmoji,
  }) = _FormFieldThemeData;
}

/// {@category Theme}
///
final kDefaultInputDecoration = InputDecoration(
  errorStyle: DefaultAppStyle.error(12).copyWith(height: 0),
  filled: true,
  fillColor: DefaultColor.lowGrey,
  contentPadding: EdgeInsets.symmetric(
      vertical: formatHeight(9.5), horizontal: formatWidth(17.5)),
  hintStyle: DefaultAppStyle.grey(13, FontWeight.w500),

  /// Border
  errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: DefaultColor.error, width: 1)),
  focusedErrorBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
  disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
);
