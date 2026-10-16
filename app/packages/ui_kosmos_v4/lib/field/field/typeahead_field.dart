import 'dart:async';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// - [suggestionsCallback] vous permet d'ajouter votre propre liste de suggestions
/// - [itemBuilder] vous permet de mettre en forme le vos suggestions
/// - [onSuggestionSelected] vous permet de récuperer la suggestion. Par défaut, retourne la suggestion sous forme de string
///
/// Exemple:
///
/// ![form_field_item](../../images/field/field_typeahead.png)
///
/// ```dart
/// FormTypeAheadField(
///   fieldName: "Exemple",
///   hintText: "BlaBla",
///   suggestionsCallback: (pattern) async {
///     return await Future.delayed(const Duration(seconds: 2), () => ["Nice", "Paris", "Marseille"]);
///   },
///   itemBuilder: (context, suggestion) {
///     return ListTile(
///       title: Text(suggestion),
///     );
///   },
///   onSuggestionSelected: (suggestion) {
///     final controller = _typeaheadKey.currentState?.getController();
///     controller?.text = suggestion.toString();
///     printWarning(controller?.text);
///   },
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormTypeAheadField<T> extends ConsumerStatefulWidget {
  final bool isEnabled;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final List<TextInputFormatter>? inputFormatters;
  final int minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final T? initialValue;
  final String? Function(T?)? initilaVisualValue;
  final void Function(String)? onChanged;
  final String? hintText;
  final bool isRequired;
  final bool hideOnLoading;
  final FutureOr<List<T>?> Function(String) suggestionsCallback;
  final ListTile Function(BuildContext context, T suggestion) itemBuilder;
  final void Function(T suggestion)? onSuggestionSelected;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext)? emptyBuilder;
  final bool autofocus;
  final Widget Function(BuildContext, Widget)? decorationBuilder;

  /// Form
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;
  final AutovalidateMode? autovalidateMode;

  /// Theme
  final FormFieldThemeData? theme;
  final String? themeName;
  final InputDecoration? inputDecoration;

  const FormTypeAheadField({
    super.key,
    required this.suggestionsCallback,
    required this.itemBuilder,
    this.onSuggestionSelected,
    this.decorationBuilder,
    this.initilaVisualValue,
    this.isRequired = true,
    this.controller,
    this.hideOnLoading = true,
    this.isEnabled = true,
    this.focusNode,
    this.nextNode,
    this.inputFormatters,
    this.minLines = 1,
    this.maxLines,
    this.textInputAction,
    this.keyboardType,
    this.initialValue,
    this.onChanged,
    this.hintText,
    this.validator,
    this.onSaved,
    this.loadingBuilder,
    this.emptyBuilder,
    this.autofocus = false,

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
  ConsumerState<FormTypeAheadField<T>> createState() =>
      FormTypeAheadFieldState<T>();
}

class FormTypeAheadFieldState<T> extends ConsumerState<FormTypeAheadField<T>> {
  late TextEditingController? controller = widget.controller ??
      (widget.initialValue != null ? null : TextEditingController());

  @override
  void initState() {
    if (widget.initialValue != null) {
      controller ??= TextEditingController();
      execAfterBuild(() => setState(() => controller!.text =
          widget.initilaVisualValue?.call(widget.initialValue) ?? ""));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "form_field",
      () => const FormFieldThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
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
      theme: themeData,

      child: FormField<T>(
        onSaved: widget.onSaved,
        validator: widget.validator,
        initialValue: widget.initialValue,
        builder: (FormFieldState<T> field) {
          controller?.text = widget.initilaVisualValue?.call(field.value) ??
              controller?.text ??
              "";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IgnorePointer(
                ignoring: !widget.isEnabled,
                child: TypeAheadField<T>(
                  hideOnLoading: widget.hideOnLoading,
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  builder: (context, controller, focusNode) {
                    return TextFormField(
                      autovalidateMode: widget.autovalidateMode,
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: widget.autofocus,
                      inputFormatters: widget.inputFormatters,
                      minLines: widget.minLines,
                      maxLines: widget.maxLines,
                      textInputAction: (((widget.maxLines ?? 1) > 1)
                          ? TextInputAction.newline
                          : widget.textInputAction),
                      onChanged: widget.onChanged ?? (val) {},
                      obscureText: false,
                      style: themeData.fieldTextStyle ??
                          DefaultAppStyle.darkBlue(13, FontWeight.w400),
                      decoration: inputDecoration.copyWith(
                        hintText: widget.hintText,
                        suffixIcon: inputDecoration.suffixIcon,
                        border: field.hasError
                            ? inputDecoration.errorBorder
                            : inputDecoration.border,
                        enabledBorder: field.hasError
                            ? inputDecoration.errorBorder
                            : inputDecoration.enabledBorder,
                        focusedBorder: field.hasError
                            ? inputDecoration.errorBorder
                            : inputDecoration.focusedBorder,
                        disabledBorder: field.hasError
                            ? inputDecoration.errorBorder
                            : inputDecoration.disabledBorder,
                      ),
                    );
                  },
                  decorationBuilder: widget.decorationBuilder,
                  suggestionsCallback: widget.suggestionsCallback,
                  itemBuilder: widget.itemBuilder,
                  loadingBuilder: widget.loadingBuilder ??
                      (context) => const Center(child: LoaderClassique()),
                  emptyBuilder: widget.emptyBuilder ??
                      (context) => const SizedBox.shrink(),
                  onSelected: widget.onSuggestionSelected ??
                      (suggestion) => controller?.text = suggestion.toString(),
                ),
              ),
              if (field.hasError && field.errorText != null) ...[
                sh(3),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(18)),
                  child: Text(
                    field.errorText!,
                    style: DefaultAppStyle.error(12, FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                )
              ],
            ],
          );
        },
      ),
    );
  }

  /// Permet de récupérer le controller du field via la state [GlobalKey]
  TextEditingController? getController() => controller;
}
