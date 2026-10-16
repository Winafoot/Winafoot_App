import 'dart:math' as math;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/_deprecated/micro_element/theme.dart';

class ProgressBar extends StatelessWidget {
  final double max;
  final double current;
  final double? height;
  final Color? color;
  final Color? backColor;
  final Duration? duration;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final String? customSmallTitle;
  final String? customBigTitle;
  final ProgressBarThemeData? theme;
  final bool? showPercentage;
  final TextStyle? percentageStyle;
  final List<String>? items;

  const ProgressBar({
    Key? key,
    required this.max,
    required this.current,
    this.backColor,
    this.color,
    this.duration,
    this.borderRadius,
    this.height,
    this.customBigTitle,
    this.customSmallTitle,
    this.textStyle,
    this.theme,
    this.showPercentage,
    this.percentageStyle,
    this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, "progress_bar", () => const ProgressBarThemeData())!;

    return Column(
      crossAxisAlignment: customSmallTitle != null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          customSmallTitle ??
              customBigTitle ??
              '${(current / max * 100).toInt()}%',
          style: textStyle ??
              themeData.style ??
              const TextStyle(
                color: Color(0xFF02132B),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
        ),
        sh(7),
        LayoutBuilder(
          builder: (_, boxConstraints) {
            var x = boxConstraints.maxWidth;
            var percent = (current / max) * x;
            return Stack(
              children: [
                Container(
                  width: x,
                  height: height ?? themeData.height ?? 10,
                  decoration: BoxDecoration(
                    color: backColor ??
                        themeData.backColor ??
                        const Color(0xFFE2E4E7),
                    borderRadius: borderRadius ??
                        themeData.borderRadius ??
                        BorderRadius.circular(8),
                  ),
                ),
                AnimatedContainer(
                  duration: duration ?? themeData.duration ?? Duration.zero,
                  width: percent,
                  height: height ?? themeData.height ?? 10,
                  decoration: BoxDecoration(
                    color: color ?? themeData.color ?? const Color(0xFF02132B),
                    borderRadius: borderRadius ??
                        themeData.borderRadius ??
                        BorderRadius.circular(8),
                  ),
                ),
                if (showPercentage ?? false)
                  Positioned(
                    child: Text(
                      "${(current / max * 100).toInt()}%",
                      style: percentageStyle ??
                          themeData.percentageStyle ??
                          TextStyle(
                              color: Colors.white,
                              fontSize: sp(14),
                              fontWeight: FontWeight.w600),
                    ),
                    left: formatWidth(11),
                    top: 0,
                    bottom: 0,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  factory ProgressBar.separated({
    required double max,
    required double current,
    double? height,
    Color? color,
    Color? backColor,
    Duration? duration,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    String? customSmallTitle,
    String? customBigTitle,
    ProgressBarThemeData? theme,
    bool? showPercentage,
    TextStyle? percentageStyle,
    List<String>? items,
  }) = _ProgressSeparated;
}

class _ProgressSeparated extends ProgressBar {
  _ProgressSeparated({
    required double max,
    required double current,
    double? height,
    Color? color,
    Color? backColor,
    Duration? duration,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    String? customSmallTitle,
    String? customBigTitle,
    ProgressBarThemeData? theme,
    bool? showPercentage,
    TextStyle? percentageStyle,
    List<String>? items,
  }) : super(
          max: max,
          current: current,
          height: height,
          color: color,
          backColor: backColor,
          duration: duration,
          borderRadius: borderRadius,
          textStyle: textStyle,
          customSmallTitle: customSmallTitle,
          customBigTitle: customBigTitle,
          theme: theme,
          showPercentage: showPercentage,
          percentageStyle: percentageStyle,
          items: items,
        ) {
    assert(items != null ? items.length == max : true);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, "progress_bar", () => const ProgressBarThemeData());

    return Column(
      crossAxisAlignment: customSmallTitle != null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          customSmallTitle ??
              customBigTitle ??
              '${(current / max * 100).toInt()}%',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle ??
              themeData.style ??
              const TextStyle(
                color: Color(0xFF02132B),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
        ),
        sh(7),
        LayoutBuilder(
          builder: (_, boxConstraints) {
            return Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < max; i++) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: height ?? themeData.height ?? 10,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: height ?? themeData.height ?? 10,
                                      decoration: BoxDecoration(
                                        color: backColor ??
                                            themeData.backColor ??
                                            const Color(0xFFE2E4E7),
                                        borderRadius: borderRadius ??
                                            themeData.borderRadius ??
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: duration ??
                                          themeData.duration ??
                                          Duration.zero,
                                      width: current >= i ? double.infinity : 0,
                                      height: height ?? themeData.height ?? 10,
                                      decoration: BoxDecoration(
                                        color: color ??
                                            themeData.color ??
                                            const Color(0xFF02132B),
                                        borderRadius: borderRadius ??
                                            themeData.borderRadius ??
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    if ((showPercentage ?? false) &&
                                        current == i)
                                      Positioned.fill(
                                        child: Center(
                                            child: Row(
                                          children: [
                                            Text("en cours",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: sp(10),
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ],
                                        )),
                                        // Icon(Icons.check_rounded, color: Colors.white, size: sp(14)),
                                        left: formatWidth(8),
                                        top: 0,
                                        bottom: 0,
                                      ),
                                    if (current > i)
                                      Positioned.fill(
                                        child: Center(
                                            child: Row(
                                          children: [
                                            Icon(Icons.check_rounded,
                                                color: Colors.white,
                                                size: sp(14))
                                          ],
                                        )),
                                        // Icon(Icons.check_rounded, color: Colors.white, size: sp(14)),
                                        left: formatWidth(8),
                                        top: 0,
                                        bottom: 0,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (items != null) ...[
                          sh(5),
                          Text(
                            items![i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                themeData.style?.copyWith(fontSize: sp(12)) ??
                                    TextStyle(
                                      color: const Color(0xFF02132B),
                                      fontSize: sp(12),
                                      fontWeight: FontWeight.w400,
                                    ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  sw(8),
                ]
              ],
            );
          },
        ),
      ],
    );
  }
}

/// SPINKIT CODE
class ThreeBounce extends StatefulWidget {
  const ThreeBounce({
    Key? key,
    this.color,
    this.size = 50.0,
    this.itemBuilder,
    this.duration,
    this.controller,
    this.theme,
  })  : assert(
            !(itemBuilder is IndexedWidgetBuilder && color is Color) &&
                !(itemBuilder == null && color == null),
            'You should specify either a itemBuilder or a color'),
        super(key: key);

  final Color? color;
  final double size;
  final IndexedWidgetBuilder? itemBuilder;
  final Duration? duration;
  final AnimationController? controller;
  final ClassicLoaderThemeData? theme;

  @override
  ThreeBounceState createState() => ThreeBounceState();
}

class ThreeBounceState extends State<ThreeBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final ClassicLoaderThemeData themeData;
  @override
  void initState() {
    super.initState();
    themeData = loadThemeData(
        widget.theme, "classic_loader", () => const ClassicLoaderThemeData())!;

    _controller = (widget.controller ??
        AnimationController(
            vsync: this,
            duration: widget.duration ??
                themeData.duration ??
                const Duration(milliseconds: 1400)))
      ..repeat();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.fromSize(
        size: Size(widget.size * 2, widget.size),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) {
            return ScaleTransition(
              scale: DelayTween(begin: 0.0, end: 1.0, delay: i * .2)
                  .animate(_controller),
              child: SizedBox.fromSize(
                  size: Size.square(widget.size * 0.5), child: _itemBuilder(i)),
            );
          }),
        ),
      ),
    );
  }

  Widget _itemBuilder(int index) => widget.itemBuilder != null
      ? widget.itemBuilder!(context, index)
      : DecoratedBox(
          decoration: BoxDecoration(
              color: widget.color ?? themeData.activeColor,
              shape: BoxShape.circle));
}

class DelayTween extends Tween<double> {
  DelayTween({double? begin, double? end, required this.delay})
      : super(begin: begin, end: end);

  final double delay;

  @override
  double lerp(double t) =>
      super.lerp((math.sin((t - delay) * 2 * math.pi) + 1) / 2);

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}
