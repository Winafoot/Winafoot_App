import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Champ de formulaire pour dropdown, permet la sélection d'un objet dans une liste déroulante.
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Exemple:
///
/// ![form_field_item](../../images/field/dropdown_field.png)
///
/// ```dart
/// FormDropDownField<String>(
///   fieldName: "Texte d'exemple",
///   hintText: "Choisir",
///   isWarningPrefix: true, // Optional, false by default
///   items: const [
///     DropdownMenuItem(value: "1", child: Text("Item 1")),
///     DropdownMenuItem(value: "2", child: Text("Item 2")),
///     DropdownMenuItem(value: "3", child: Text("Item 3")),
///   ],
///   onChanged: (_) => printDebug(_),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormDropDownField<T> extends ConsumerStatefulWidget {
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final T? initialValue;
  final bool isRequired;
  final String? hintText;
  final Key? dropDownKey;
  final bool isExpanded;

  /// Icône de déroulement custom (par défaut [Icons.keyboard_arrow_down_rounded]).
  final Widget? icon;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;

  /// Theme
  final String? themeName;
  final FormFieldThemeData? theme;
  final InputDecoration? inputDecoration;
  final Widget? prefix;
  final bool isWarningPrefix;
  final AutovalidateMode? autovalidateMode;

  const FormDropDownField({
    super.key,
    required this.items,
    this.onChanged,
    this.dropDownKey,
    this.validator,
    this.selectedItemBuilder,
    this.initialValue,
    this.isRequired = false,
    this.hintText,
    this.isExpanded = false,
    this.icon,

    /// Item
    this.fieldName,
    this.fieldAction,
    this.fieldSuffix,
    this.fieldActionOnTap,

    /// Theme
    this.themeName,
    this.theme,
    this.inputDecoration,
    this.prefix,
    this.isWarningPrefix = false,
    this.autovalidateMode,
  });

  @override
  ConsumerState<FormDropDownField<T>> createState() =>
      _FormDropDownFieldState<T>();
}

class _FormDropDownFieldState<T> extends ConsumerState<FormDropDownField<T>> {
  late T? value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(widget.theme,
        widget.themeName ?? "form_field", () => const FormFieldThemeData(),
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    final inputDecoration = (widget.inputDecoration ??
        themeData.inputDecoration ??
        kDefaultInputDecoration);

    value = widget.initialValue;

    final prefix = (widget.prefix != null || widget.isWarningPrefix)
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.prefix ??
                  (widget.isWarningPrefix
                      ? SvgPicture.asset("assets/svg/ic_warning_drop.svg",
                          package: "ui_kosmos_v4")
                      : null) ??
                  const SizedBox(),
            ],
          )
        : null;

    return FormFieldItem(
      /// Theme configuration
      fieldName: (widget.fieldName == null && !widget.isRequired)
          ? null
          : "${widget.fieldName?.trim() ?? ""}${widget.isRequired ? "*" : ""}",
      fieldAction: widget.fieldAction,
      fieldActionOnTap: widget.fieldActionOnTap,
      fieldSuffix: widget.fieldSuffix,
      theme: themeData,

      /// Field Widget
      child: DropdownButtonFormField<T>(
        key: widget.dropDownKey,
        autovalidateMode: widget.autovalidateMode,
        items: widget.items,
        hint: widget.hintText != null
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.hintText!,
                  style: inputDecoration.hintStyle ??
                      kDefaultInputDecoration.hintStyle,
                ),
              )
            : null,
        isExpanded: widget.isExpanded,
        onChanged: (val) {
          setState(() => value = val);
          widget.onChanged?.call(val);
        },
        icon: widget.icon ?? const Icon(Icons.keyboard_arrow_down_rounded),
        dropdownColor: themeData.dropdownColor,
        validator: widget.validator,
        selectedItemBuilder: widget.selectedItemBuilder,
        value: value,
        borderRadius: themeData.dropdownBorderRadius,
        decoration: inputDecoration.copyWith(
          // hintText: widget.hintText,
          prefixIcon: prefix,
          suffixIcon: prefix != null ? const SizedBox.shrink() : null,
          suffixIconConstraints: prefix != null ? const BoxConstraints() : null,
        ),
      ),
    );
  }
}
