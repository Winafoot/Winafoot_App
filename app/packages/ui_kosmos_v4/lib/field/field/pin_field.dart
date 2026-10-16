import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Champ de formulaire pour un code PIN.
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de validation de [AuthValidator] et [FieldValidator] du package Core_Kosmos.
///
/// Exemple:
///
/// ![pin_code_field](../../images/field/pin_code_field.png)
///
/// ```dart
/// FormPinCodeField(
///   fieldName: "package.field.auth.code.title".tr(),
///   onChanged: (val) => code = val,
///   validator: (val) {
///     if (val?.length != 6) return "package.kosmos-auth.code-invalid".tr();
///     return null;
///   },
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormPinCodeField extends ConsumerStatefulWidget {
  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;
  final PinTheme? pinTheme;

  final FormFieldValidator<String>? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onCompleted;
  final AutovalidateMode autovalidateMode;

  /// Theme
  final FormFieldThemeData? theme;
  final String? themeName;
  final InputDecoration? inputDecoration;

  const FormPinCodeField({
    super.key,

    /// Item
    this.fieldName,
    this.fieldAction,
    this.fieldActionOnTap,
    this.fieldSuffix,
    this.onChanged,
    this.validator,
    this.pinTheme,
    this.onCompleted,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,

    /// Theme
    this.theme,
    this.themeName,
    this.inputDecoration,
  });

  @override
  ConsumerState<FormPinCodeField> createState() => _FormPinCodeFieldState();
}

class _FormPinCodeFieldState extends ConsumerState<FormPinCodeField> {
  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(widget.theme,
        widget.themeName ?? "form_field", () => const FormFieldThemeData(),
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    final inputDecoration = (widget.inputDecoration ??
        themeData.inputDecoration ??
        kDefaultInputDecoration);

    return FormFieldItem(
      fieldName:
          (widget.fieldName == null) ? null : widget.fieldName?.trim() ?? "",
      fieldAction: widget.fieldAction,
      fieldActionOnTap: widget.fieldActionOnTap,
      fieldSuffix: widget.fieldSuffix,
      theme: themeData,

      /// Field widget
      child: PinCodeTextField(
        backgroundColor: Colors.transparent,
        appContext: context,
        length: 6,
        onChanged: (val) => widget.onChanged?.call(val),
        textStyle: themeData.fieldPinStyle ??
            themeData.fieldTextStyle ??
            DefaultAppStyle.darkBlue(20, FontWeight.w500),
        hintStyle: inputDecoration.hintStyle ??
            DefaultAppStyle.lightGrey(20, FontWeight.w400),
        blinkWhenObscuring: true,
        animationType: AnimationType.fade,
        validator: widget.validator,
        autovalidateMode: widget.autovalidateMode,
        cursorColor: DefaultColor.darkBlue,
        animationDuration: const Duration(milliseconds: 300),
        enableActiveFill: true,
        keyboardType: TextInputType.number,
        beforeTextPaste: (text) => true,
        onCompleted: widget.onCompleted,
        pinTheme: widget.pinTheme ??
            PinTheme(
              borderRadius:
                  BorderRadius.circular(r(themeData.fieldPinRadius ?? 7)),
              shape: PinCodeFieldShape.box,
              fieldHeight: themeData.fieldPinHeight ?? formatWidth(44),
              fieldWidth: themeData.fieldPinWidth ?? formatWidth(44),
              inactiveFillColor: inputDecoration.fillColor,
              inactiveColor: inputDecoration.disabledBorder?.borderSide.color,
              activeColor: inputDecoration.enabledBorder?.borderSide.color,
              selectedFillColor: inputDecoration.fillColor,
              activeFillColor: inputDecoration.fillColor,
              selectedColor: inputDecoration.focusedBorder?.borderSide.color,
              disabledColor: inputDecoration.fillColor,
              errorBorderColor: DefaultColor.error,
              borderWidth: 1,
              activeBorderWidth: 1,
              selectedBorderWidth: 1,
              inactiveBorderWidth: 1,
              errorBorderWidth: 1,
              disabledBorderWidth: 1,
            ),
      ),
    );
  }
}
