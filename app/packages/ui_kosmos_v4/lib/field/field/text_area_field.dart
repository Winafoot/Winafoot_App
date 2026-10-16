import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Champ de formulaire pour zone de texte.
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de validation de [FieldValidator] du package Core_Kosmos.
///
/// Exemple:
///
/// ![form_field_item](../../images/field/text_area_field.png)
///
/// ```dart
/// FormTextAreaField(
///   fieldName: "Texte d'exemple",
///   maxLength: 255,
///   maxLines: 12,
///   onChanged: (_) => printDebug(_),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormTextAreaField extends StatefulHookConsumerWidget {
  final bool isEnabled;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final List<TextInputFormatter>? inputFormatters;
  final int minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final String? initialValue;
  final FormFieldSetter<String>? onSaved;
  final void Function(String)? onChanged;
  final String? hintText;
  final bool isRequired;
  final BoxConstraints? constraints;
  final bool isError;
  final bool showErrorIcon;
  final bool showErrorTitle;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;

  /// Theme
  final String? themeName;
  final FormFieldThemeData? theme;
  final InputDecoration? inputDecoration;
  final AutovalidateMode? autovalidateMode;

  const FormTextAreaField({
    super.key,
    this.isRequired = true,
    this.controller,
    this.isEnabled = true,
    this.focusNode,
    this.nextNode,
    this.inputFormatters,
    this.minLines = 8,
    this.maxLines,
    this.maxLength,
    this.textInputAction,
    this.keyboardType,
    this.onSaved,
    this.validator,
    this.constraints,
    this.initialValue,
    this.onChanged,
    this.hintText,
    this.isError = false,
    this.showErrorIcon = true,
    this.showErrorTitle = true,
    this.textCapitalization = TextCapitalization.none,

    /// Item
    this.fieldName,
    this.fieldAction,
    this.fieldSuffix,
    this.fieldActionOnTap,

    /// Theme
    this.theme,
    this.themeName,
    this.inputDecoration,
    this.autovalidateMode,
  }) : assert(fieldAction != null ? fieldActionOnTap != null : true,
            "You must provide a onTap callback for the fieldAction");

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FormTextAreaFieldState();
}

class _FormTextAreaFieldState extends ConsumerState<FormTextAreaField> {
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

      /// Field Widget
      child: ConstrainedBox(
        constraints:
            widget.constraints ?? BoxConstraints(maxHeight: formatHeight(120)),
        child: TextFormField(
          autovalidateMode: widget.autovalidateMode,
          scrollPhysics: const BouncingScrollPhysics(),
          scrollPadding: EdgeInsets.zero,
          textCapitalization: widget.textCapitalization,
          keyboardType: TextInputType.multiline,
          maxLength: widget.maxLength,
          enabled: widget.isEnabled,
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: widget.focusNode,
          inputFormatters: widget.inputFormatters,
          minLines: widget.minLines,
          maxLines: widget.maxLines ?? 4,
          textInputAction: (((widget.maxLines ?? 1) > 1)
              ? TextInputAction.newline
              : widget.textInputAction),
          validator: widget.validator,
          onSaved: widget.onSaved,
          onChanged: widget.onChanged,
          onFieldSubmitted: (val) => widget.nextNode?.requestFocus(),
          style: themeData.fieldTextStyle ??
              DefaultAppStyle.darkBlue(13, FontWeight.w400),
          decoration: inputDecoration.copyWith(hintText: widget.hintText),
        ),
      ),
    );
  }
}
