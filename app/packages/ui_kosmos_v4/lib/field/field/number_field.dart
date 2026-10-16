import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_kosmos_v4/field/utils/formatter.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Champ de formulaire pour un nombre.
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de validation de [AuthValidator] et [FieldValidator] du package Core_Kosmos.
///
/// Exemple:
///
/// ![form_field_item](../../images/field/number_field.png)
///
/// ```dart
/// FormNumberField(
///   fieldName: "Exemple de nombre",
///   hintText: "1 232.34",
///   validator: (val) => (val?.isEmpty ?? true) ? "Champ vide" : null, // val as double
///   onChanged: (val) => printInfo(val), // val as double
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormNumberField extends ConsumerStatefulWidget {
  final bool isEnabled;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final TextInputAction? textInputAction;
  final String? initialValue;
  final FormFieldSetter<double>? onSaved;
  final void Function(double)? onChanged;
  final String? hintText;
  final double? minValue;
  final double? maxValue;
  final bool isRequired;
  final bool isError;
  final bool showErrorIcon;
  final bool showErrorTitle;
  final FormFieldValidator<String>? validator;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;

  /// Theme
  final FormFieldThemeData? theme;
  final String? themeName;
  final InputDecoration? inputDecoration;
  final AutovalidateMode? autovalidateMode;

  const FormNumberField({
    super.key,
    this.isRequired = false,
    this.controller,
    this.isEnabled = true,
    this.focusNode,
    this.nextNode,
    this.textInputAction,
    this.onSaved,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.hintText,
    this.minValue,
    this.maxValue,
    this.isError = false,
    this.showErrorIcon = true,
    this.showErrorTitle = true,

    /// Item
    this.fieldAction,
    this.fieldActionOnTap,
    this.fieldName,
    this.fieldSuffix,

    /// Theme
    this.theme,
    this.themeName,
    this.inputDecoration,
    this.autovalidateMode,
  }) : assert(fieldAction != null ? fieldActionOnTap != null : true,
            "You must provide a onTap callback for the fieldAction");

  @override
  ConsumerState<FormNumberField> createState() => _FormNumberFieldState();
}

class _FormNumberFieldState extends ConsumerState<FormNumberField> {
  late final controller = widget.controller ??
      (widget.initialValue != null ? null : TextEditingController());

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(widget.theme,
        widget.themeName ?? "form_field", () => const FormFieldThemeData(),
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    final inputDecoration = (widget.inputDecoration ??
        themeData.inputDecoration ??
        kDefaultInputDecoration);

    return FormFieldItem(
      /// Theme configuration
      fieldName: (widget.fieldName == null && !widget.isRequired)
          ? null
          : "${widget.fieldName?.trim() ?? ""}${widget.isRequired ? "*" : ""}",
      fieldAction: widget.fieldAction,
      fieldActionOnTap: widget.fieldActionOnTap,
      fieldSuffix: widget.fieldSuffix,
      isError: widget.isError,
      showErrorTitle: widget.showErrorTitle,
      theme: themeData,

      /// Field widget
      child: TextFormField(
        autovalidateMode: widget.autovalidateMode,
        enabled: widget.isEnabled,
        controller: widget.initialValue != null ? null : controller,
        focusNode: widget.focusNode,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9 ,.]')),
          NumericTextFormatter(),
        ],
        minLines: 1,
        maxLines: 1,
        keyboardType:
            const TextInputType.numberWithOptions(signed: true, decimal: true),
        textInputAction: widget.textInputAction,
        validator: (value) {
          if (widget.validator != null) {
            return widget.validator?.call(value);
          }
          if (widget.maxValue != null && widget.minValue != null) {
            return FieldValidator.validNumericValueWithRange(
                value, widget.minValue!, widget.maxValue!);
          } else if (widget.maxValue != null) {
            return FieldValidator.validNumericValueWithMax(
                value, widget.maxValue!);
          } else if (widget.minValue != null) {
            return FieldValidator.validNumericValueWithMin(
                value, widget.minValue!);
          }
          return FieldValidator.validNumericValue(value);
        },
        onSaved: (val) =>
            widget.onSaved?.call(DoubleUtils.trimAndParse(val ?? "")),
        initialValue: widget.initialValue,
        onChanged: (val) =>
            widget.onChanged?.call(DoubleUtils.trimAndParse(val) ?? 0),
        onFieldSubmitted: (val) => widget.nextNode?.requestFocus(),
        style: themeData.fieldTextStyle ??
            DefaultAppStyle.darkBlue(13, FontWeight.w400),
        decoration: inputDecoration.copyWith(
            hintText: widget.hintText,
            suffixIcon: widget.isError && widget.showErrorIcon
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      inputDecoration.suffixIcon ??
                          SvgPicture.asset(
                            "assets/svg/ic_warning.svg",
                            package: "ui_kosmos_v4",
                            color: DefaultColor.error,
                            width: formatWidth(21),
                          ),
                    ],
                  )
                : null),
      ),
    );
  }
}
