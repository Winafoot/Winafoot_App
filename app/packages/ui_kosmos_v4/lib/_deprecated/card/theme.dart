import 'package:flutter/material.dart';

class CustomCardsThemeData {
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final BoxConstraints? constraints;
  final Color? backgroundColor;
  final double? radius;
  final EdgeInsetsGeometry? paddingImage;
  final EdgeInsetsGeometry? paddingText;
  final EdgeInsetsGeometry? paddingDoublePoint;
  final EdgeInsetsGeometry? paddingTriplePoint;
  final EdgeInsetsGeometry? paddingContent;
  final Size? doublePointSize;

  final TextStyle? miniTitleStyle;
  final TextStyle? miniSubTitleStyle;
  final TextStyle? tagStyle;
  final TextStyle? descStyle;
  final TextStyle? markTextStyle;
  final TextStyle? bottomTitleStyle;
  final TextStyle? statusTextStyle;

  const CustomCardsThemeData({
    this.subTitleStyle,
    this.titleStyle,
    this.constraints,
    this.backgroundColor,
    this.radius,
    this.paddingImage,
    this.paddingText,
    this.miniSubTitleStyle,
    this.miniTitleStyle,
    this.paddingDoublePoint,
    this.doublePointSize,
    this.tagStyle,
    this.paddingTriplePoint,
    this.descStyle,
    this.markTextStyle,
    this.bottomTitleStyle,
    this.statusTextStyle,
    this.paddingContent,
  });
}
