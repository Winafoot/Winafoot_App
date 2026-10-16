import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// Curseur à une poignée.
class CustomSlider extends ConsumerStatefulWidget {
  /// Core
  final void Function(double)? onChanged;
  final double? initialValue;
  final double min;
  final double max;
  final String Function(double value, double min, double max)? valueToString;
  final bool showTextUnder;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;
  final bool isRequired;

  /// Theme
  final String? themeName;
  final FormFieldThemeData? theme;
  final CustomSliderThumbShape? thumbShape;
  final int divisions;

  const CustomSlider({
    super.key,

    /// Core
    this.onChanged,
    this.initialValue,
    this.min = 0,
    this.max = 200,
    this.divisions = 200,
    this.valueToString,
    this.showTextUnder = false,

    /// Item
    this.fieldAction,
    this.fieldActionOnTap,
    this.fieldName,
    this.fieldSuffix,
    this.isRequired = false,

    /// Theme
    this.themeName,
    this.theme,
    this.thumbShape,
  });

  @override
  ConsumerState<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends ConsumerState<CustomSlider> {
  late double _value = widget.initialValue ?? 0;

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "form_field",
      () => const FormFieldThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    final sliderThemeData = loadThemeData(
        null, widget.themeName ?? "slider", () => kDefaultSliderTheme,
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    return FormFieldItem(
      /// Theme configuration
      fieldName: (widget.fieldName == null && !widget.isRequired)
          ? null
          : "${widget.fieldName?.trim() ?? ""}${widget.isRequired ? "*" : ""}",
      fieldAction: widget.fieldAction,
      fieldActionOnTap: widget.fieldActionOnTap,
      fieldSuffix: widget.fieldSuffix,
      theme: themeData,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: sliderThemeData?.trackHeight,
          thumbColor: sliderThemeData?.thumbColor,
          activeTrackColor: sliderThemeData?.activeTrackColor,
          inactiveTrackColor: sliderThemeData?.inactiveTrackColor,
          overlayShape: sliderThemeData?.overlayShape,
          overlayColor: Colors.transparent,
          trackShape: CustomTrackShape(),
          thumbShape: CustomSliderThumbShape(
            showValueUnder: widget.showTextUnder,
            min: widget.min,
            max: widget.max,
            enabledThumbRadius: widget.thumbShape?.enabledThumbRadius ?? 10,
            disabledThumbRadius: widget.thumbShape?.disabledThumbRadius,
            elevation: widget.thumbShape?.elevation ?? 0,
            pressedElevation: widget.thumbShape?.pressedElevation ?? 6,
            insideColor: widget.thumbShape?.insideColor ?? Colors.white,
            insideRadius: widget.thumbShape?.insideRadius,
            ajustString: widget.thumbShape?.ajustString ?? 1.8,
          ),
        ),
        child: Slider(
          divisions: widget.divisions,
          min: widget.min,
          max: widget.max,
          value: _value,
          onChanged: (value) {
            setState(() => _value = value);
            widget.onChanged?.call(value);
          },
        ),
      ),
    );
  }
}
