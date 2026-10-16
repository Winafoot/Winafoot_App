import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ui_kosmos_v4/field/utils/formatter.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

enum DateType {
  /// Affichage de la date et de l'heure (ex: DD/MM/YYYY HH:MM)
  full,

  /// Affichage de la date (ex: DD/MM/YYYY)
  date,

  /// Affichage de l'heure (ex: HH:MM)
  time,
}

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
/// ```dart
/// // Field uniquement pour la date
/// FormDateFromStringField(
///   fieldName: "Date de naissance",
///   type: DateType.date,
///   onChanged: (val) => printDebug(val),
///   initialValue: DateTime(2021, 1, 1),
///   controller: TextEditingController(),
/// ),
///
/// // Field uniquement pour l'heure
/// FormDateFromStringField(
///   fieldName: "Heure de naissance",
///   type: DateType.time,
///   onChanged: (val) => printDebug(val),
/// ),
///
/// // Field pour la date et l'heure
/// FormDateFromStringField(
///   fieldName: "Full de naissance",
///   type: DateType.full,
///   onChanged: (val) => printDebug(val),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormDateFromStringField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final bool isEnabled;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final TextInputAction? textInputAction;
  final FormFieldValidator<DateTime>? validator;
  final DateTime? initialValue;
  final FormFieldSetter<DateTime>? onSaved;
  final void Function(DateTime?)? onChanged;
  final String? hintText;
  final bool isRequired;
  final DateType type;
  final bool isError;
  final bool showErrorIcon;
  final bool showErrorTitle;

  final String dateSeparator;
  final String timeSeparator;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;

  /// Theme
  final FormFieldThemeData? theme;
  final String? themeName;
  final InputDecoration? inputDecoration;

  const FormDateFromStringField({
    Key? key,
    this.type = DateType.full,
    this.controller,
    this.isEnabled = true,
    this.focusNode,
    this.nextNode,
    this.textInputAction,
    this.onSaved,
    this.validator,
    this.initialValue,
    this.onChanged,
    this.hintText,
    this.isRequired = true,
    this.dateSeparator = "/",
    this.timeSeparator = ":",
    this.isError = false,
    this.showErrorIcon = true,
    this.showErrorTitle = true,

    /// Item
    this.fieldName,
    this.fieldAction,
    this.fieldActionOnTap,
    this.fieldSuffix,

    /// Theme
    this.theme,
    this.themeName,
    this.inputDecoration,
  }) : super(key: key);

  @override
  ConsumerState<FormDateFromStringField> createState() =>
      FormDateFromStringFieldState();
}

class FormDateFromStringFieldState
    extends ConsumerState<FormDateFromStringField> {
  late final TextEditingController? _controller;

  @override
  void initState() {
    if (widget.initialValue != null) {
      _controller = null;
    } else {
      _controller = widget.controller ?? TextEditingController();
      if (widget.initialValue != null) {
        _controller!.text =
            "${widget.initialValue!.day.toString().padLeft(2, '0')}/${widget.initialValue!.month.toString().padLeft(2, '0')}/${widget.initialValue!.year}";
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
      fieldName:
          "${widget.fieldName?.trim() ?? ""}${widget.isRequired ? "*" : ""}",
      fieldAction: widget.fieldAction,
      fieldActionOnTap: widget.fieldActionOnTap,
      fieldSuffix: widget.fieldSuffix,
      isError: widget.isError,
      showErrorTitle: widget.showErrorTitle,

      /// Field widget
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        enabled: widget.isEnabled,
        controller: widget.initialValue != null ? null : _controller,
        focusNode: widget.focusNode,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9 /:]')),
          DateTextFormatter(
              widget.type, widget.dateSeparator, widget.timeSeparator),
        ],
        minLines: 1,
        maxLines: 1,
        keyboardType: TextInputType.datetime,
        textInputAction: widget.textInputAction,
        validator: (val) {
          if (!widget.isRequired && (val?.isEmpty ?? true)) return null;
          return widget.validator
              ?.call(transformStringToDate(val, widget.type));
        },
        onSaved: (val) {
          widget.onSaved?.call(transformStringToDate(val, widget.type));
        },
        initialValue: _getInitialValue(),
        onChanged: (val) =>
            widget.onChanged?.call(transformStringToDate(val, widget.type)),
        onFieldSubmitted: (val) => widget.nextNode?.requestFocus(),
        style: themeData.fieldTextStyle ??
            DefaultAppStyle.darkBlue(13, FontWeight.w400),
        decoration: inputDecoration.copyWith(
          hintText: widget.hintText ?? _getDefaultHint(),
          suffixIcon: widget.isError && widget.showErrorIcon
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
              : null,
        ),
      ),
    );
  }

  static DateTime? transformStringToDate(String? val, DateType type) {
    try {
      if (val == null || val.isEmpty) return null;
      final formater = DateFormat(
        type == DateType.full
            ? "dd/MM/yyyy HH:mm"
            : type == DateType.date
                ? "dd/MM/yyyy"
                : "HH:mm",
      );
      return formater.parse(val);
    } catch (e) {
      return null;
    }
  }

  String? _getInitialValue() {
    if (widget.initialValue == null || widget.controller != null) return null;

    if (widget.type == DateType.date) {
      return '${widget.initialValue?.day.toString().padLeft(2, '0')}/${widget.initialValue?.month.toString().padLeft(2, '0')}/${widget.initialValue?.year}';
    } else if (widget.type == DateType.time) {
      return '${widget.initialValue?.hour.toString().padLeft(2, '0')}:${widget.initialValue?.minute.toString().padLeft(2, '0')}';
    } else {
      return '${widget.initialValue?.day.toString().padLeft(2, '0')}/${widget.initialValue?.month.toString().padLeft(2, '0')}/${widget.initialValue?.year} ${widget.initialValue?.hour.toString().padLeft(2, '0')}:${widget.initialValue?.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getDefaultHint() {
    return {
      DateType.date: "Ex: 25/12/2021",
      DateType.time: "Ex: 13:45",
      DateType.full: "Ex: 25/12/2021 13:45",
    }[widget.type]!;
  }
}
