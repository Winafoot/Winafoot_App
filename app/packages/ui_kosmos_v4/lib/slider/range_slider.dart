import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// Curseur à deux poignées (plage de valeurs).
class CustomRangeSlider extends ConsumerStatefulWidget {
  /// Core
  final void Function(RangeValues)? onChanged;
  final RangeValues? initialValue;
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

  const CustomRangeSlider({
    super.key,

    /// Core
    this.onChanged,
    this.initialValue,
    this.min = 0,
    this.max = 200,
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
  ConsumerState<CustomRangeSlider> createState() => _CustomRangeSliderState();
}

class _CustomRangeSliderState extends ConsumerState<CustomRangeSlider> {
  late RangeValues _value =
      widget.initialValue ?? RangeValues(widget.min, widget.max);

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
          thumbColor: sliderThemeData?.thumbColor,
          activeTrackColor: sliderThemeData?.activeTrackColor,
          inactiveTrackColor: sliderThemeData?.inactiveTrackColor,
          overlayColor: Colors.transparent,
          rangeTrackShape: CustomRangeTrackShape(),
          rangeThumbShape: CustomRangeShape(
            min: widget.min,
            max: widget.max,
            rangeValues: _value,
            showValueUnder: widget.showTextUnder,
            insideColor: widget.thumbShape?.insideColor ?? Colors.white,
          ),
        ),
        child: RangeSlider(
          min: widget.min,
          max: widget.max,
          values: _value,
          onChanged: (value) {
            setState(() => _value = value);
            widget.onChanged?.call(value);
          },
        ),
      ),
    );
  }
}
