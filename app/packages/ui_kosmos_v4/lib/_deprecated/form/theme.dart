import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

class CustomFormFieldThemeData {
  final CrossAxisAlignment fieldNameAlignment;

  ///Text
  final TextStyle? fieldNameStyle;
  final TextStyle? fieldPostRedirectionStyle;

  ///input config
  final String? obscuringCharacter;
  final TextStyle? fieldStyle;
  final TextStyle? hintStyle;
  final Color? cursorColor;
  final BoxConstraints? prefixChildBoxConstraint;
  final BoxConstraints? suffixChildBoxConstraint;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? focusedErrorBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedBorder;
  final InputBorder? border;

  final PhoneNumber? initialPhoneValue;

  final double? selectRadius;
  final double? selectRadiusDropDown;
  final double? selectIconSize;

  final BoxDecoration? pickerDecoration;
  final BoxConstraints? pickerConstraints;
  final double? pickerHeight;
  final double? pickerImageWidth;
  final double? pickerImageRadius;
  final Color? pickerIconColor;
  final TextStyle? subFieldTextStyle;

  final int? minLine;
  final int? maxLine;

  const CustomFormFieldThemeData({
    this.fieldNameAlignment = CrossAxisAlignment.start,
    this.fieldNameStyle,
    this.fieldPostRedirectionStyle,
    this.obscuringCharacter,
    this.fieldStyle,
    this.cursorColor,
    this.prefixChildBoxConstraint,
    this.suffixChildBoxConstraint,
    this.backgroundColor,
    this.contentPadding,
    this.errorBorder,
    this.focusedBorder,
    this.focusedErrorBorder,
    this.border,
    this.hintStyle,
    this.initialPhoneValue,
    this.selectRadius,
    this.selectRadiusDropDown,
    this.selectIconSize,
    this.pickerDecoration,
    this.pickerConstraints,
    this.pickerHeight,
    this.pickerImageWidth,
    this.pickerImageRadius,
    this.pickerIconColor,
    this.maxLine,
    this.minLine,
    this.subFieldTextStyle,
  });
}
