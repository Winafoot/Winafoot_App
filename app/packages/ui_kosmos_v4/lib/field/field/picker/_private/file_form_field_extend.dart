// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

class FileFormField<T> extends FormField<List<T>> {
  FileFormField({
    Key? key,
    final List<T>? initialValue,
    final FormFieldValidator<List<T>>? validator,
    final FormFieldSetter<List<T>>? onSaved,
    final void Function(List<T>)? onChanged,
    final FutureOr<List<T>?> Function(BuildContext context)? onPick,
    final Widget? Function(BuildContext, List<T>)? childBuilder,
    required bool isDark,

    /// Theme
    final String? themeName,
    final FormFieldThemeData? theme,
    final EdgeInsetsGeometry? contentPadding,
  }) : super(
          key: key,
          initialValue: initialValue,
          validator: validator,
          onSaved: onSaved,
          builder: (FormFieldState<List<T>> field) {
            void onChangedHandler(List<T> value) {
              field.didChange(value);
              if (onChanged != null) {
                onChanged(value);
              }
            }

            List<T> files = field.value ?? [];
            final themeData = loadThemeData(
                theme,
                themeName ?? "form_field",
                () => FormFieldThemeData(
                    inputDecoration: kDefaultInputDecoration),
                isDark: isDark);
            final inputDecoration =
                themeData.inputDecoration ?? kDefaultInputDecoration;

            final isError = field.hasError;

            BorderRadius? radius;
            if (isError) {
              if (inputDecoration.errorBorder is OutlineInputBorder) {
                radius = (inputDecoration.errorBorder as OutlineInputBorder)
                    .borderRadius;
              } else if (inputDecoration.errorBorder is UnderlineInputBorder) {
                radius = (inputDecoration.errorBorder as UnderlineInputBorder)
                    .borderRadius;
              }
            } else {
              if (inputDecoration.border is OutlineInputBorder) {
                radius =
                    (inputDecoration.border as OutlineInputBorder).borderRadius;
              } else if (inputDecoration.border is UnderlineInputBorder) {
                radius = (inputDecoration.border as UnderlineInputBorder)
                    .borderRadius;
              }
            }

            BoxBorder? border;

            if (isError &&
                inputDecoration.errorBorder != null &&
                inputDecoration.errorBorder?.borderSide != BorderSide.none) {
              border = Border.all(
                width: inputDecoration.errorBorder?.borderSide.width ?? 1,
                color: inputDecoration.errorBorder?.borderSide.color ??
                    DefaultColor.error,
              );
            } else if (inputDecoration.border != null &&
                inputDecoration.border?.borderSide != BorderSide.none) {
              border = Border.all(
                width: inputDecoration.border?.borderSide.width ?? 0,
                color: inputDecoration.border?.borderSide.color ??
                    Colors.transparent,
              );
            }

            double leftErrorPadding = formatWidth(13);
            if (inputDecoration.contentPadding is EdgeInsets) {
              leftErrorPadding =
                  (inputDecoration.contentPadding as EdgeInsets).left;
            } else if (inputDecoration.contentPadding
                is EdgeInsetsDirectional) {
              leftErrorPadding =
                  (inputDecoration.contentPadding as EdgeInsetsDirectional)
                      .start;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final v = await onPick?.call(field.context);
                    if (v != null && v.isNotEmpty) onChangedHandler(v);
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: formatHeight(110)),
                    padding: contentPadding,
                    decoration: BoxDecoration(
                        color:
                            inputDecoration.fillColor ?? DefaultColor.lowGrey,
                        border: border,
                        borderRadius: radius),
                    child: childBuilder?.call(field.context, files),
                  ),
                ),
                if (isError) ...[
                  sh(3),
                  Padding(
                    padding: EdgeInsets.only(left: leftErrorPadding),
                    child: Text(
                      field.errorText ?? "",
                      style: inputDecoration.errorStyle ??
                          TextStyle(color: DefaultColor.error, fontSize: 12),
                    ),
                  ),
                ],
              ],
            );
          },
        );
}
