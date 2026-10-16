import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Champ de formulaire pour texte simple (secret ou visible).
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de validation de [AuthValidator] et [FieldValidator] du package Core_Kosmos.
///
/// Exemple:
///
/// ![form_field_item](../../images/field/classic_field.png)
///
/// ```dart
/// FormClassicField(
///   fieldName: "Exemple",
///   hintText: "BlaBla",
///   isSecretField: true, // Optional, permet de définir le champ comme secret.
///   validator: (val) => (val?.isEmpty ?? true) ? "Champ vide" : null, // val as String
///   onChanged: (val) => printInfo(val), // val as String
/// ),
///
/// // Exemple de champ visible
/// const FormClassicField(
///   fieldName: "Exemple",
///   hintText: "BlaBla",
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormClassicField extends ConsumerStatefulWidget {
  final bool isEnabled;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final List<TextInputFormatter>? inputFormatters;
  final int minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final String? initialValue;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool isSecretField;
  final String secretFieldChar;
  final String? hintText;
  final bool isRequired;
  final bool isError;
  final bool showErrorIcon;
  final bool showErrorTitle;
  final bool autoFocus;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;
  final Iterable<String>? autofillHints;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;

  /// Theme
  final String? themeName;
  final FormFieldThemeData? theme;
  final InputDecoration? inputDecoration;

  const FormClassicField({
    super.key,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.isRequired = true,
    this.controller,
    this.isEnabled = true,
    this.autovalidateMode,
    this.autofillHints,
    this.focusNode,
    this.nextNode,
    this.inputFormatters,
    this.minLines = 1,
    this.maxLines,
    this.textInputAction,
    this.keyboardType,
    this.autoFocus = false,
    this.onSaved,
    this.validator,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.isSecretField = false,
    this.secretFieldChar = '*',
    this.hintText,
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
  }) : assert(fieldAction != null ? fieldActionOnTap != null : true,
            "You must provide a onTap callback for the fieldAction");

  @override
  ConsumerState<FormClassicField> createState() => _FormClassicFieldState();
}

class _FormClassicFieldState extends ConsumerState<FormClassicField> {
  late bool _isObscure = widget.isSecretField ? true : false;

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
          : "${widget.fieldName?.trim()}${widget.isRequired && (themeData.showRequiredIndicator ?? true) ? "*" : ""}",
      fieldAction: widget.fieldAction,
      theme: themeData,
      fieldActionOnTap: widget.fieldActionOnTap,
      fieldSuffix: widget.fieldSuffix,
      isError: widget.isError,
      showErrorTitle: widget.showErrorTitle,

      /// Field widget
      child: TextFormField(
        autofillHints: widget.autofillHints,
        autovalidateMode: widget.autovalidateMode,
        textAlign: widget.textAlign,
        textCapitalization: widget.textCapitalization,
        enabled: widget.isEnabled,
        controller: widget.initialValue != null ? null : widget.controller,
        focusNode: widget.focusNode,
        inputFormatters: widget.inputFormatters,
        minLines: widget.minLines,
        autofocus: widget.autoFocus,
        maxLines: widget.isSecretField ? 1 : (widget.maxLines ?? 1),
        keyboardType: widget.keyboardType,
        textInputAction: (((widget.maxLines ?? 1) > 1)
            ? TextInputAction.newline
            : (widget.textInputAction ?? TextInputAction.next)),
        validator: widget.validator,
        onSaved: widget.onSaved,
        initialValue: widget.initialValue,
        onChanged: widget.onChanged,
        onFieldSubmitted:
            widget.onSubmitted ?? (val) => widget.nextNode?.requestFocus(),
        obscuringCharacter: widget.secretFieldChar,
        obscureText: _isObscure,
        style: themeData.fieldTextStyle ??
            DefaultAppStyle.darkBlue(13, FontWeight.w400),
        decoration: inputDecoration.copyWith(
          hintText: widget.hintText,
          suffixIcon: inputDecoration.suffixIcon ??
              (widget.isSecretField
                  ? InkWell(
                      onTap: () => setState(() => _isObscure = !_isObscure),
                      child: (themeData.passwordHideIcon == null ||
                              themeData.passwordShowIcon == null)
                          ? Icon(
                              _isObscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility,
                              color: inputDecoration.hintStyle?.color ??
                                  DefaultColor.grey,
                            )
                          : _isObscure
                              ? themeData.passwordShowIcon
                              : themeData.passwordHideIcon,
                    )
                  : (widget.isError && widget.showErrorIcon
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              "assets/svg/ic_warning.svg",
                              package: "ui_kosmos_v4",
                              color: DefaultColor.error,
                              width: formatWidth(21),
                            ),
                          ],
                        )
                      : null)),
        ),
      ),
    );
  }
}
