import 'dart:math';

import 'package:flutter/material.dart';

class CustomSliderThumbShape extends SliderComponentShape {
  const CustomSliderThumbShape({
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
    this.elevation = 1.0,
    this.pressedElevation = 6.0,
    this.insideColor = Colors.white,
    this.insideRadius,
    this.stringNumber,
    this.ajustString = 1.8,
    this.indicatorTextStyle,
  });

  final double enabledThumbRadius;
  final TextStyle? indicatorTextStyle;
  final double? disabledThumbRadius;
  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;
  final double elevation;
  final double pressedElevation;

  final Color insideColor;
  final double? insideRadius;

  final String? stringNumber;
  final double ajustString;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
        isEnabled == true ? enabledThumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    assert(sliderTheme.disabledThumbColor != null);
    assert(sliderTheme.thumbColor != null);

    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: _disabledThumbRadius,
      end: enabledThumbRadius,
    );
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );

    final Color color = colorTween.evaluate(enableAnimation)!;
    final double radius = radiusTween.evaluate(enableAnimation);

    final Tween<double> elevationTween = Tween<double>(
      begin: elevation,
      end: pressedElevation,
    );

    TextSpan span = TextSpan(
      style: indicatorTextStyle ??
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: sliderTheme.thumbColor,
          ),
      text: stringNumber ?? "${(value * 100).toInt()}",
    );

    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();

    tp.paint(
        canvas, Offset(center.dx - tp.width / ajustString, center.dy / 2 + 16));

    final double evaluatedElevation =
        elevationTween.evaluate(activationAnimation);
    final Path path = Path()
      ..addArc(
          Rect.fromCenter(
              center: center, width: 2 * radius, height: 2 * radius),
          0,
          pi * 2);
    canvas.drawShadow(path, Colors.black, evaluatedElevation, true);

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color,
    );

    canvas.drawCircle(
      center,
      insideRadius ?? radius / 1.2,
      Paint()..color = insideColor,
    );
  }
}

class CustomRangeShape extends RangeSliderThumbShape {
  const CustomRangeShape({
    this.thumbSize = 10.0,
    this.insideColor = Colors.white,
    this.insideRadius = 8.0,
    this.rangeValues,
    this.thumbRadius = 10.0,
    this.indicatorTextStyle,
  });
  final TextStyle? indicatorTextStyle;

  final double thumbSize;
  final double thumbRadius;
  final Color insideColor;
  final double insideRadius;
  final RangeValues? rangeValues;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbSize);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool? isDiscrete,
    bool? isEnabled,
    bool? isOnTop,
    TextDirection textDirection = TextDirection.rtl,
    required SliderThemeData sliderTheme,
    Thumb thumb = Thumb.start,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;

    Path thumbPath = shape(thumbSize, center, thumbRadius);
    Path insideThumbPath = shape(thumbSize, center, insideRadius);

    if (rangeValues != null) {
      TextSpan span = TextSpan(
        style: indicatorTextStyle ??
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: sliderTheme.thumbColor,
            ),
        text: thumb == Thumb.start
            ? rangeValues!.start.toInt().toString()
            : rangeValues!.end.toInt().toString(),
      );

      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();

      thumb == Thumb.start
          ? tp.paint(
              canvas, Offset(center.dx - tp.width / 1.8, center.dy + thumbSize))
          : tp.paint(canvas,
              Offset(center.dx - tp.width / 1.9, center.dy + thumbSize));
    }

    canvas.drawPath(thumbPath, Paint()..color = sliderTheme.thumbColor!);
    canvas.drawPath(insideThumbPath, Paint()..color = insideColor);
  }
}

Path shape(double size, Offset thumbCenter, double radius,
    {bool invert = false}) {
  final Path thumbPath = Path();
  final double halfSize = size / 1.5;
  final double sign = invert ? -1.0 : 1.0;
  thumbPath.moveTo(thumbCenter.dx + halfSize * sign, thumbCenter.dy);
  thumbPath.addOval(Rect.fromCircle(
      center: Offset(thumbCenter.dx, thumbCenter.dy), radius: radius));
  thumbPath.close();
  return thumbPath;
}
