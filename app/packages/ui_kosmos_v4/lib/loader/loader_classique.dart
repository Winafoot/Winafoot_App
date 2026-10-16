import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/loader/theme/theme.dart';
import 'dart:math' as math;

class LoaderClassique extends StatefulWidget {
  final bool? animating;
  final double? radius;
  final int? tickCount;
  final Color? activeColor;
  final Duration? animationDuration;
  final double relativeWidth;
  final double? startRatio = 0.5;
  final double? endRatio = 1.0;
  final ClassicLoaderThemeData? theme;

  /// Creates a highly customizable activity indicator.
  const LoaderClassique({
    this.animating = true,
    this.radius,
    this.tickCount = 12,
    this.activeColor,
    this.animationDuration,
    this.relativeWidth = 1,
    this.theme,
    Key? key,
  }) : super(key: key);

  @override
  NutsActivityIndicatorState createState() => NutsActivityIndicatorState();
}

class NutsActivityIndicatorState extends State<LoaderClassique>
    with SingleTickerProviderStateMixin {
  late AnimationController? _animationController;
  late final ClassicLoaderThemeData _themeData;

  @override
  void initState() {
    super.initState();
    _themeData = loadThemeData(
      widget.theme,
      "classic_loader",
      () => kDefaultLoaderTheme,
      isDark: AppTheme.isDark(),
    )!;
    _animationController = AnimationController(
      duration: widget.animationDuration ??
          _themeData.duration ??
          const Duration(milliseconds: 800),
      vsync: this,
    );
    if (widget.animating!) {
      _animationController!.repeat();
    }
  }

  @override
  void didUpdateWidget(LoaderClassique oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animating != oldWidget.animating) {
      if (widget.animating!) {
        _animationController!.repeat();
      } else {
        _animationController!.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.radius ?? _themeData.radius ?? 30 * 2,
      width: widget.radius ?? _themeData.radius ?? 30 * 2,
      child: CustomPaint(
        painter: _NutsActivityIndicatorPainter(
          animationController: _animationController!,
          radius: widget.radius ?? _themeData.radius ?? 30,
          tickCount: widget.tickCount!,
          activeColor:
              widget.activeColor ?? _themeData.activeColor ?? Colors.white,
          relativeWidth: widget.relativeWidth,
          startRatio: widget.startRatio!,
          endRatio: widget.endRatio!,
        ),
      ),
    );
  }
}

class _NutsActivityIndicatorPainter extends CustomPainter {
  final int _halfTickCount;
  final Animation<double> animationController;
  final Color activeColor;

  final double relativeWidth;
  final int tickCount;
  final double radius;
  final RRect _tickRRect;
  final double startRatio;
  final double endRatio;

  _NutsActivityIndicatorPainter({
    required this.radius,
    required this.tickCount,
    required this.animationController,
    required this.activeColor,
    required this.relativeWidth,
    required this.startRatio,
    required this.endRatio,
  })  : _halfTickCount = tickCount ~/ 2,
        _tickRRect = RRect.fromLTRBXY(
          -radius * endRatio,
          relativeWidth * radius / 10,
          -radius * startRatio,
          -relativeWidth * radius / 10,
          10,
          10,
        ),
        super(repaint: animationController);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2);
    final activeTick = (tickCount * animationController.value).floor();
    for (int i = 0; i < tickCount; ++i) {
      paint.color = Color.lerp(
        activeColor,
        activeColor.withOpacity(0.2),
        ((i + activeTick) % tickCount) / _halfTickCount,
      )!;
      canvas
        ..drawRRect(_tickRRect, paint)
        ..rotate(-math.pi * 2 / tickCount);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NutsActivityIndicatorPainter oldPainter) {
    return oldPainter.animationController != animationController;
  }
}
