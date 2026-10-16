// ignore_for_file: unused_local_variable

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_kosmos_v4/_deprecated/form/theme.dart';

class SelectForm<T> extends HookWidget {
  final CustomFormFieldThemeData? theme;
  final Widget? prefixChild;
  final Widget? suffixChild;
  final Widget? suffixChildActive;
  final BoxConstraints? prefixChildBoxConstraint;
  final BoxConstraints? suffixChildBoxConstraint;
  final InputBorder? focusedErrorBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedBorder;
  final InputBorder? border;
  final bool? obscuringText;
  final bool? filled;
  final bool? isUpdatable;
  final String? fieldName;
  final String? hintText;
  final T? value;
  final TextStyle? fieldNameStyle;
  final TextStyle? hintTextStyle;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final double? iconSize;
  final double? radius;
  final double? radiusDropDown;
  final IconData? icon;
  final EdgeInsetsGeometry? contentPadding;
  final List<DropdownMenuItem<T>>? items;
  final Function(T?)? onChangedSelect;
  final String? Function(T?)? validator;
  final String? subFieldText;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;

  const SelectForm({
    this.theme,
    this.prefixChild,
    this.suffixChild,
    this.suffixChildActive,
    this.prefixChildBoxConstraint,
    this.suffixChildBoxConstraint,
    this.focusedErrorBorder,
    this.errorBorder,
    this.focusedBorder,
    this.border,
    this.obscuringText,
    this.filled,
    this.isUpdatable,
    this.fieldName,
    this.hintText,
    this.value,
    this.fieldNameStyle,
    this.hintTextStyle,
    this.textStyle,
    this.backgroundColor,
    this.iconSize,
    this.radius,
    this.radiusDropDown,
    this.icon,
    this.selectedItemBuilder,
    this.contentPadding,
    this.items,
    this.onChangedSelect,
    this.validator,
    this.subFieldText,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, "input_field", () => const CustomFormFieldThemeData());
    final state = useState(false);
    final stateObscure = useState(obscuringText ?? false);
    return Column(
      crossAxisAlignment: themeData.fieldNameAlignment,
      children: [
        Text(
          fieldName ?? "NOM FIELD",
          style: fieldNameStyle ??
              themeData.fieldNameStyle ??
              const TextStyle(
                  color: Color(0xFF02132B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<T>(
          enableFeedback: isUpdatable ?? true,
          borderRadius: BorderRadius.circular(
              radiusDropDown ?? themeData.selectRadiusDropDown ?? 7),
          elevation: 0,
          dropdownColor: backgroundColor ?? themeData.backgroundColor,
          hint: Text(
            hintText ?? "Sélectionner",
            style: hintTextStyle ??
                themeData.hintStyle ??
                const TextStyle(
                    color: Color(0xFF9299A4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
          ),
          selectedItemBuilder: selectedItemBuilder,
          value: value,
          isExpanded: true,
          iconSize: iconSize ?? themeData.selectIconSize ?? 24.0,
          icon: Icon(icon ?? Iconsax.arrow_down_14),
          style: textStyle ??
              themeData.fieldStyle ??
              const TextStyle(
                      color: Color(0xFF02132B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)
                  .copyWith(color: const Color(0xFF02132B)),
          items: items ?? <DropdownMenuItem<T>>[],
          onChanged: onChangedSelect ?? (_) {},
          validator: validator,
          decoration: InputDecoration(
              errorStyle: const TextStyle(fontSize: 12, height: 0),
              prefixIcon: prefixChild,
              suffixIcon: isUpdatable == true
                  ? InkWell(
                      child: !stateObscure.value
                          ? (suffixChild ?? const SizedBox())
                          : suffixChildActive ??
                              suffixChild ??
                              const SizedBox(),
                      onTap: () {
                        stateObscure.value = !stateObscure.value;
                      },
                    )
                  : suffixChild,
              prefixIconConstraints: prefixChildBoxConstraint ??
                  themeData.prefixChildBoxConstraint,
              suffixIconConstraints: suffixChildBoxConstraint ??
                  themeData.suffixChildBoxConstraint,
              filled: filled ?? true,
              fillColor: backgroundColor ??
                  themeData.backgroundColor ??
                  const Color(0xFF02132B).withOpacity(0.03),
              contentPadding: contentPadding ??
                  themeData.contentPadding ??
                  const EdgeInsets.fromLTRB(9.5, 17.5, 9.5, 17.5),
              focusedErrorBorder: focusedErrorBorder ??
                  themeData.focusedErrorBorder ??
                  OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 0.5,
                      )),
              errorBorder: errorBorder ??
                  themeData.errorBorder ??
                  OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 0.5,
                      )),
              focusedBorder: focusedBorder ?? themeData.focusedBorder,
              border: border ??
                  themeData.border ??
                  UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none),
              hintText: hintText ?? "Placeholder",
              hintStyle: hintTextStyle ??
                  themeData.hintStyle ??
                  const TextStyle(
                      color: Color(0xFF9299A4),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
        ),
        if (subFieldText != null) ...[
          sh(4),
          Text(subFieldText!,
              style: themeData.subFieldTextStyle ??
                  TextStyle(
                      fontSize: sp(11),
                      color: Colors.black.withOpacity(.75),
                      fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}
