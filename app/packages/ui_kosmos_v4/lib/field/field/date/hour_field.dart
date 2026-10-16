import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Cet input de formulaire permet de sélectionner une heure.
///
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de validation de [AuthValidator] et [FieldValidator] du package Core_Kosmos.
///
/// Exemple:
///
/// ```Dart
/// FormHourField(
///   fieldName: "Hour Picker",
///   onChanged: (assets) => printDebug(assets),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormHourField extends ConsumerStatefulWidget {
  final bool isEnabled;
  final TimeOfDay? initialValue;

  final FormFieldSetter<TimeOfDay>? onSaved;
  final void Function(TimeOfDay)? onChanged;
  final FormFieldValidator<TimeOfDay>? validator;
  final bool showOnlyHour;
  final String? hint;

  final Future<TimeOfDay?> Function(BuildContext context)? pickTime;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;
  final bool isRequired;
  final bool isError;
  final bool showErrorIcon;
  final bool showErrorTitle;
  final TimeOfDay? currentHour;

  /// Theme
  final FormFieldThemeData? theme;
  final String? themeName;
  final InputDecoration? inputDecoration;
  final AutovalidateMode? autovalidateMode;

  const FormHourField({
    super.key,
    this.isEnabled = true,
    this.hint,
    this.currentHour,
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.showOnlyHour = false,
    this.pickTime,

    /// Item
    this.fieldAction,
    this.fieldActionOnTap,
    this.fieldName,
    this.fieldSuffix,
    this.isError = false,
    this.showErrorIcon = true,
    this.showErrorTitle = true,
    this.isRequired = false,

    /// Theme
    this.theme,
    this.themeName,
    this.inputDecoration,
    this.autovalidateMode,
  });

  @override
  ConsumerState<FormHourField> createState() => _FormHourFieldState();
}

class _FormHourFieldState extends ConsumerState<FormHourField> {
  late final themeData = loadThemeData(
    widget.theme,
    widget.themeName ?? "form_field",
    () => const FormFieldThemeData(),
    isDark: ref.watch(isDarkModeProvider).isDarkMode,
  );

  @override
  Widget build(BuildContext context) {
    final inputDecoration = (widget.inputDecoration ??
        themeData.inputDecoration ??
        kDefaultInputDecoration);

    BorderRadius? radius;
    BoxBorder? border;
    if (inputDecoration.enabledBorder is OutlineInputBorder) {
      radius =
          (inputDecoration.enabledBorder as OutlineInputBorder).borderRadius;
      border = Border.all(
          color: inputDecoration.errorBorder?.borderSide.color ??
              DefaultColor.error,
          width: 1);
    } else if (inputDecoration.enabledBorder is UnderlineInputBorder) {
      radius =
          (inputDecoration.enabledBorder as UnderlineInputBorder).borderRadius;
      border = Border.all(
          color: inputDecoration.errorBorder?.borderSide.color ??
              DefaultColor.error,
          width: 1);
    }

    return FormField<TimeOfDay>(
      initialValue: widget.initialValue,
      autovalidateMode: widget.autovalidateMode,
      onSaved: widget.onSaved,
      validator: widget.validator,
      enabled: widget.isEnabled,
      builder: (field) {
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

          child: InkWell(
            onTap: () async {
              final timeOfDay = await pickTime(context, widget.initialValue);
              if (timeOfDay != null) {
                field.didChange(timeOfDay);
                widget.onChanged?.call(timeOfDay);
              }
            },
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: formatHeight(43)),
              decoration: BoxDecoration(
                color: inputDecoration.fillColor,
                borderRadius: radius,
                border: widget.isError || field.hasError ? border : null,
              ),
              padding: inputDecoration.contentPadding ?? pwh(12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: field.value == null || widget.currentHour == null
                        ? Text(
                            widget.hint ??
                                "package.ui-kosmos_v4.field.input.hour-picker.hint"
                                    .tr(),
                            style: inputDecoration.hintStyle,
                          )
                        : Text(
                            "package.ui-kosmos_v4.field.input.hour-picker.${widget.showOnlyHour ? "hour-field" : "full-hour-field"}"
                                .tr(
                              args: widget.currentHour != null
                                  ? [
                                      widget.currentHour?.hour.autoPadLeft(2) ??
                                          "",
                                      widget.currentHour?.minute
                                              .autoPadLeft(2) ??
                                          ""
                                    ]
                                  : [
                                      field.value?.hour.autoPadLeft(2) ?? "",
                                      field.value?.minute.autoPadLeft(2) ?? ""
                                    ],
                            ),
                            style: themeData.fieldTextStyle,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<TimeOfDay?> pickTime(
      BuildContext context, TimeOfDay? initialValue) async {
    if (widget.pickTime != null) {
      return await widget.pickTime!(context);
    }
    final time = await showTimePicker(
      context: context,
      initialTime: initialValue ?? TimeOfDay.now(),
    );
    return time;
  }
}
