import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/field/field/number_field.dart';
import 'package:ui_kosmos_v4/field/theme/form_field_theme.dart';

enum PriceCurrency {
  eur,
  usd,
  ch,
  gbp;

  String get symbol {
    switch (this) {
      case PriceCurrency.eur:
        return "€";
      case PriceCurrency.usd:
        return "\$";
      case PriceCurrency.ch:
        return "CHF";
      case PriceCurrency.gbp:
        return "£";
    }
  }
}

/// {@category Widget}
/// {@category Form, Input}
///
/// Champ de formulaire pour un prix.
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Vous pouvez définir la currency de votre prix via [currency].
/// (EUR, USD, CHF, GBP)
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de validation de [AuthValidator] et [FieldValidator] du package Core_Kosmos.
///
/// Exemple:
///
/// ```dart
/// FormPriceField(
///   fieldName: "Exemple de prix",
///   hintText: "1 232.34",
///   validator: (val) => (val?.isEmpty ?? true) ? "Champ vide" : null, // val as String
///   onChanged: (val) => printInfo(val), // val as double
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormPriceField extends ConsumerStatefulWidget {
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
  final PriceCurrency currency;
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

  const FormPriceField({
    super.key,
    this.currency = PriceCurrency.eur,
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
  });

  @override
  ConsumerState<FormPriceField> createState() => _FormPriceFieldState();
}

class _FormPriceFieldState extends ConsumerState<FormPriceField> {
  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(widget.theme,
        widget.themeName ?? "form_field", () => const FormFieldThemeData(),
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    InputDecoration iDecoration = (widget.inputDecoration ??
        themeData.inputDecoration ??
        kDefaultInputDecoration);
    iDecoration = iDecoration.copyWith(
      suffixIcon: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.currency.symbol,
              style: themeData.fieldTextStyle ?? DefaultAppStyle.darkBlue(13)),
        ],
      ),
    );

    return FormNumberField(
      isEnabled: widget.isEnabled,
      autovalidateMode: widget.autovalidateMode,
      controller: widget.controller,
      focusNode: widget.focusNode,
      nextNode: widget.nextNode,
      textInputAction: widget.textInputAction,
      onSaved: widget.onSaved,
      initialValue: widget.initialValue,
      validator: widget.validator,
      onChanged: widget.onChanged,
      hintText: widget.hintText,
      minValue: widget.minValue,
      maxValue: widget.maxValue,
      isRequired: widget.isRequired,
      isError: widget.isError,
      showErrorIcon: widget.showErrorIcon,
      showErrorTitle: widget.showErrorTitle,
      fieldName: widget.fieldName,
      fieldAction: widget.fieldAction,
      fieldSuffix: widget.fieldSuffix,
      fieldActionOnTap: widget.fieldActionOnTap,
      theme: widget.theme,
      themeName: widget.themeName,
      inputDecoration: iDecoration,
    );
  }
}
