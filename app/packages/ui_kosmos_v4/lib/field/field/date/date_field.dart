// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ui_kosmos_v4/field/form_item.dart';

import '../../theme/form_field_theme.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Champ de formulaire pour une date, heure ou les deux à la fois.
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de validation de [AuthValidator] et [FieldValidator] du package Core_Kosmos.
///
/// Exemple:
///
/// ![form_field_item](../../images/field/date_from_string_field.png)
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormDateField extends ConsumerStatefulWidget {
  final DateFormat? format;
  final TimePickerEntryMode? timeInitialEntryMode;
  final DatePickerEntryMode? dateInitialEntryMode;
  final TextEditingController? controller;
  final FormFieldValidator<DateTime>? validator;
  final FormFieldSetter<DateTime>? onSaved;
  final DateTime? initialValue;
  final FocusNode? focusNode;
  final void Function(DateTime?)? onChanged;
  final String? hintText;
  final bool showTimePickerToo;
  final Icon? resetIcon;

  /// Picker Config
  final DateTime? firstDate, lastDate;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;
  final bool isError;
  final bool showErrorIcon;
  final bool showErrorTitle;
  final bool isRequired;

  /// Theme
  final FormFieldThemeData? theme;
  final String? themeName;
  final InputDecoration? inputDecoration;
  final AutovalidateMode? autovalidateMode;

  const FormDateField({
    super.key,
    this.format,
    this.validator,
    this.onSaved,
    this.initialValue,
    this.timeInitialEntryMode,
    this.dateInitialEntryMode,
    this.onChanged,
    this.hintText,
    this.controller,
    this.focusNode,
    this.showTimePickerToo = false,
    this.resetIcon,

    /// Picker Config
    this.firstDate,
    this.lastDate,

    /// Item
    this.fieldName,
    this.fieldAction,
    this.fieldActionOnTap,
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
  ConsumerState<FormDateField> createState() => _FormDateFieldState();
}

class _FormDateFieldState extends ConsumerState<FormDateField> {
  @override
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
      fieldName:
          "${widget.fieldName?.trim() ?? ""}${widget.isRequired ? "*" : ""}",
      fieldAction: widget.fieldAction,
      fieldActionOnTap: widget.fieldActionOnTap,
      fieldSuffix: widget.fieldSuffix,
      isError: widget.isError,
      showErrorTitle: widget.showErrorTitle,
      theme: themeData,

      /// Item
      child: DateTimeField(
        resetIcon: widget.resetIcon,
        controller: widget.controller,
        format: widget.format ?? DateFormat("dd/MM/yyyy"),
        initialValue: widget.initialValue,
        autovalidateMode:
            widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
        focusNode: widget.focusNode,
        validator: widget.validator,
        onSaved: widget.onSaved,
        onChanged: widget.onChanged,
        decoration: inputDecoration.copyWith(
            hintText: widget.hintText,
            suffixIconColor: (widget.isError && widget.showErrorIcon)
                ? DefaultColor.error
                : (themeData.fieldTextStyle ??
                        DefaultAppStyle.darkBlue(13, FontWeight.w400))
                    .color,
            suffixIcon: (widget.isError && widget.showErrorIcon)
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
                : inputDecoration.suffixIcon),
        style: themeData.fieldTextStyle ??
            DefaultAppStyle.darkBlue(13, FontWeight.w400),
        onShowPicker: (BuildContext context, DateTime? currentValue) async {
          DateTime firstDate =
              widget.firstDate ?? DateTime(DateTime.now().year - 150);
          DateTime lastDate =
              widget.lastDate ?? DateTime(DateTime.now().year + 1);
          DateTime now = DateTime.now();
          DateTime? d = await showDatePicker(
            context: context,
            initialEntryMode:
                widget.dateInitialEntryMode ?? DatePickerEntryMode.calendar,
            initialDate: widget.initialValue ??
                (now.isAfter(firstDate) ? now : firstDate),
            initialDatePickerMode: DatePickerMode.day,
            firstDate: firstDate,
            lastDate: lastDate,
            locale: Localizations.localeOf(context),
          );
          if (!mounted) return d;

          if (widget.showTimePickerToo && d != null && context.mounted) {
            final TimeOfDay? t = await showTimePicker(
              context: context,
              initialEntryMode:
                  widget.timeInitialEntryMode ?? TimePickerEntryMode.dial,
              initialTime:
                  TimeOfDay.fromDateTime(widget.initialValue ?? DateTime.now()),
            );
            if (!mounted) return d;
            d = DateTimeField.combine(d, t);
          }

          return d;
        },
      ),
    );
  }
}
