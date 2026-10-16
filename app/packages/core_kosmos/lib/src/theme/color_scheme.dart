import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';

/// {@category Config}
///
abstract class DefaultColor {
  static Color error = const Color(0xffEB5353);

  static Color success = const Color(0xff30DE8F);

  static Color warning = const Color(0xffFFC107);

  static Color info = const Color(0xff2196F3);

  static Color white = const Color(0xffffffff);

  static Color grey = const Color(0xFF9299A4);

  static Color darkSteel = const Color(0xff3F4C5E);

  static Color lightGrey = const Color(0xffCFD2D6);

  static Color simpleGrey = const Color(0xFFA7ADB5);

  static Color lowGrey = const Color(0xffF2F3F4);

  static Color lowBlue = const Color(0xffF0F3F9);

  static Color darkBlue = const Color(0xff02132B);

  static Color darkGrey = const Color(0xff5A6372);

  static Color steelGrey = const Color(0xff737D8A);
}

/// {@category Config}
///
abstract class DefaultAppStyle {
  static TextStyle error(
    double size, [
    FontWeight weight = FontWeight.w600,
    String fontFamily = 'Poppins',
  ]) =>
      TextStyle(
          color: DefaultColor.error,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle success(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.success,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle warning(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.warning,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle info(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.info,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle white(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.white,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle lightGrey(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.lightGrey,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle darkBlue(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.darkBlue,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle grey(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.grey,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle lowGrey(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.lowGrey,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle lowBlue(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.lowBlue,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle simpleGrey(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.simpleGrey,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle darkGrey(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.darkGrey,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle steelGrey(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.steelGrey,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);

  static TextStyle darkSteel(double size,
          [FontWeight weight = FontWeight.w600,
          String fontFamily = 'Poppins']) =>
      TextStyle(
          color: DefaultColor.darkSteel,
          fontSize: sp(size),
          fontWeight: weight,
          fontFamily: fontFamily);
}
