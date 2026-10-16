// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'slider_style.dart';

abstract class CustomSlider extends HookWidget {
  final SliderThemeData theme;
  final double min;
  final double max;
  final Function(dynamic)? onChanged;
  final String? fieldPostRedirection;
  final TextStyle? fieldPostRedirectionStyle;
  final VoidCallback? postFieldOnClick;
  final String? fieldName;
  final TextStyle? fieldNameStyle;
  final double? value;
  final RangeValues? rangeValue;
  final CustomSliderThumbShape? customSliderThumbShape;

  const CustomSlider({
    Key? key,
    this.min = 0,
    this.max = 100,
    this.theme = const SliderThemeData(
      trackHeight: 2,
      trackShape: RectangularSliderTrackShape(),
      activeTrackColor: Color(0xFF02132B),
      inactiveTrackColor: Color(0xFFBFC3C9),
      thumbColor: Color(0xFF02132B),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
      thumbShape: CustomSliderThumbShape(elevation: 0, pressedElevation: 0),
    ),
    this.onChanged,
    this.fieldPostRedirection,
    this.fieldPostRedirectionStyle,
    this.postFieldOnClick,
    this.fieldName,
    this.fieldNameStyle,
    this.value,
    this.rangeValue,
    this.customSliderThumbShape = const CustomSliderThumbShape(elevation: 0, pressedElevation: 0),
  }) : super(key: key);

  const factory CustomSlider.slider({
    final SliderThemeData theme,
    final double min,
    final double max,
    final Function(dynamic)? onChanged,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final double? value,
    final CustomSliderThumbShape? customSliderThumbShape,
  }) = _Slider;

  const factory CustomSlider.range({
    final SliderThemeData theme,
    final double min,
    final double max,
    final Function(dynamic)? onChanged,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final RangeValues? rangeValue,
    final CustomSliderThumbShape? customSliderThumbShape,
  }) = _Range;

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Slider extends CustomSlider {
  const _Slider({
    final CustomSliderThumbShape? customSliderThumbShape,
    final SliderThemeData theme = const SliderThemeData(
      trackHeight: 2,
      trackShape: RectangularSliderTrackShape(),
      activeTrackColor: Color(0xFF02132B),
      inactiveTrackColor: Color(0xFFBFC3C9),
      thumbColor: Color(0xFF02132B),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
    ),
    final double min = 0,
    final double max = 100,
    final Function(dynamic)? onChanged,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final double? value,
  }) : super(
          theme: theme,
          min: min,
          max: max,
          onChanged: onChanged,
          fieldName: fieldName,
          fieldNameStyle: fieldNameStyle,
          fieldPostRedirection: fieldPostRedirection,
          fieldPostRedirectionStyle: fieldPostRedirectionStyle,
          postFieldOnClick: postFieldOnClick,
          value: value,
          customSliderThumbShape: customSliderThumbShape,
        );

  @override
  Widget build(BuildContext context) {
    var state = useState<double>(value ?? 0);

    return Column(
      
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              fieldName ?? "",
              style: fieldNameStyle ?? const TextStyle(color: Color(0xFF02132B), fontSize: 12, fontWeight: FontWeight.w500),
            ),
            fieldPostRedirection == null ? const SizedBox() : const Spacer(),
            fieldPostRedirection == null
                ? const SizedBox()
                : InkWell(
                    onTap: postFieldOnClick,
                    child: Text(
                      fieldPostRedirection ?? "",
                      style: fieldPostRedirectionStyle ?? const TextStyle(color: Color(0xFF02132B), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 7),
        SliderTheme(
          data: theme.copyWith(thumbShape: customSliderThumbShape),
          child: SizedBox(
            width: double.infinity,
            child: Slider(
              min: min,
              max: max,
              value: state.value,
              onChanged: (double? value) {
                state.value = value ?? 0;
                if (onChanged != null) onChanged!(value ?? 0);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Range extends CustomSlider {
  const _Range({
    final SliderThemeData theme = const SliderThemeData(
      trackHeight: 2,
      trackShape: RectangularSliderTrackShape(),
      activeTrackColor: Color(0xFF02132B),
      inactiveTrackColor: Color(0xFFBFC3C9),
      thumbColor: Color(0xFF02132B),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
    ),
    final double min = 0,
    final double max = 100,
    final Function(dynamic)? onChanged,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final RangeValues? rangeValue,
    final CustomSliderThumbShape? customSliderThumbShape,
  }) : super(
          theme: theme,
          min: min,
          max: max,
          onChanged: onChanged,
          fieldName: fieldName,
          fieldNameStyle: fieldNameStyle,
          fieldPostRedirection: fieldPostRedirection,
          fieldPostRedirectionStyle: fieldPostRedirectionStyle,
          postFieldOnClick: postFieldOnClick,
          rangeValue: rangeValue,
          customSliderThumbShape: customSliderThumbShape,
        );

  @override
  Widget build(BuildContext context) {
    var state = useState<RangeValues>(rangeValue ?? RangeValues(min, max));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              fieldName ?? "",
              style: fieldNameStyle ?? const TextStyle(color: Color(0xFF02132B), fontSize: 12, fontWeight: FontWeight.w500),
            ),
            fieldPostRedirection == null ? const SizedBox() : const Spacer(),
            fieldPostRedirection == null
                ? const SizedBox()
                : InkWell(
                    onTap: postFieldOnClick,
                    child: Text(
                      fieldPostRedirection ?? "",
                      style: fieldPostRedirectionStyle ?? const TextStyle(color: Color(0xFF02132B), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 7),
        SliderTheme(
          data: theme.copyWith(trackHeight: 2, rangeThumbShape: CustomRangeShape(rangeValues: state.value), thumbShape: customSliderThumbShape),
          child: SizedBox(
            width: double.infinity,
            child: RangeSlider(
              min: min,
              max: max,
              values: state.value,
              onChanged: (RangeValues? value) {
                state.value = value ?? RangeValues(min, max);
                if (onChanged != null) onChanged!(value ?? RangeValues(min, max));
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
