import 'package:flutter/material.dart';

class CustomSliderThumbShape extends SliderComponentShape {
  final bool showValueUnder;
  final double min;
  final double max;
  final String Function(double value, double min, double max)? valueToString;

  const CustomSliderThumbShape({
    this.showValueUnder = true,
    this.min = 0,
    this.max = 100,
    this.valueToString,

    ///
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
    this.elevation = 1.0,
    this.pressedElevation = 6.0,
    this.insideColor = Colors.white,
    this.insideRadius,
    this.ajustString = 1.8,
    this.indicatorTextStyle,
  });

  final double enabledThumbRadius;
  final double? disabledThumbRadius;
  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;
  final double elevation;
  final double pressedElevation;

  final Color insideColor;
  final double? insideRadius;

  final double ajustString;
  final TextStyle? indicatorTextStyle;

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
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );

    final Color color = colorTween.evaluate(enableAnimation)!;
    const double radius = 12;

    if (showValueUnder) {
      final val = (max - min) * value + min;

      TextSpan span = TextSpan(
        style: indicatorTextStyle ??
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: sliderTheme.thumbColor,
            ),
        text: valueToString?.call(value, min, max) ?? "${val.round()}",
      );

      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();

      tp.paint(canvas,
          Offset(center.dx - tp.width / ajustString, center.dy / 2 + 24));
    }

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
  final bool showValueUnder;
  final double min;
  final double max;
  final String Function(double value, double min, double max)? valueToString;

  const CustomRangeShape({
    this.showValueUnder = true,
    this.min = 0,
    this.max = 100,
    this.valueToString,
    this.indicatorTextStyle,

    ///

    this.thumbSize = 10.0,
    this.insideColor = Colors.white,
    this.insideRadius = 8.0,
    this.rangeValues,
    this.thumbRadius = 10.0,
  });

  final double thumbSize;
  final double thumbRadius;
  final Color insideColor;
  final double insideRadius;
  final RangeValues? rangeValues;
  final TextStyle? indicatorTextStyle;

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

    Path thumbPath = shape(thumbSize, center, 12);
    Path insideThumbPath = shape(thumbSize, center, 10);

    if (rangeValues != null && showValueUnder) {
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

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class CustomRangeTrackShape extends RoundedRectRangeSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
