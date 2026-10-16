import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Ce champ de formulaire permet de définir des plages horaire
/// d'ouverture / pause.
/// Les boutons du bas sont utilisés pour ajouter une plage horaire
/// ou une pause.
///
/// Les données des plages horaires sont stockés dans une liste
/// de [DisponibilityModel], vous trouverez au sein de celle-ci
/// un premier argument permettant de savoir si la jounée est de
/// statut ouverte ou fermé.
/// Vous trouverez également un listing des données de chaque plage
/// sous forme de [DisponibilityItemModel] avec les informations
/// de chaque plage horaire.
///
/// Par défaut, les inputs des horaire sont des [FormHourField].
/// Si votre [validator] retourne une erreur, le champ sera
/// automatiquement mis en erreur et donc avec les bordures
/// rouge.
///
/// Widget permettant d'ajouter un un [fieldName] à un champ de
/// formulaire.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de
/// validation de [AuthValidator] et [FieldValidator] du package
/// Core_Kosmos.
///
/// ![disponibility_field](../../images/field/disponibility_field.png)
///
/// ```Dart
/// FormDisponibilityField(
///   validator: (val) => "Error de champ",
///   fieldName: "Lundi",
///   isRequired: true,
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut
/// via le [FormFieldThemeData] : "form_field".
class FormDisponibilityField extends ConsumerStatefulWidget {
  final bool isOpened;
  final List<DisponibilityItemModel>? initialValue;
  final void Function(List<DisponibilityItemModel>, bool)? onChanged;
  final FormFieldSetter<List<DisponibilityItemModel>>? onSaved;
  final FormFieldValidator<List<DisponibilityItemModel>>? validator;
  final bool showOnlyHour;
  final bool canRemoveFirst;

  /// Item
  final String? fieldName;
  final bool isRequired;
  final bool isError;
  final bool showErrorIcon;
  final bool showErrorTitle;

  /// Theme
  final FormFieldThemeData? theme;
  final String? themeName;
  final InputDecoration? inputDecoration;
  final AutovalidateMode? autovalidateMode;

  const FormDisponibilityField({
    super.key,
    this.isOpened = true,
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.showOnlyHour = false,
    this.canRemoveFirst = true,

    /// Item
    this.fieldName,
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
  ConsumerState<FormDisponibilityField> createState() =>
      _FormDisponibilityFieldState();
}

class _FormDisponibilityFieldState
    extends ConsumerState<FormDisponibilityField> {
  late List<DisponibilityItemModel> _value =
      widget.initialValue ?? [const DisponibilityItemModel(isPaused: false)];

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "form_field",
      () => const FormFieldThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    late bool isClosed = !widget.isOpened;
    final inputDecoration = (widget.inputDecoration ??
        themeData.inputDecoration ??
        kDefaultInputDecoration);

    BorderRadius? radius;
    if (inputDecoration.enabledBorder is OutlineInputBorder) {
      radius =
          (inputDecoration.enabledBorder as OutlineInputBorder).borderRadius;
    } else if (inputDecoration.enabledBorder is UnderlineInputBorder) {
      radius =
          (inputDecoration.enabledBorder as UnderlineInputBorder).borderRadius;
    }

    return FormField<List<DisponibilityItemModel>>(
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onSaved: widget.onSaved,
      initialValue: _value,
      builder: (field) {
        return FormFieldItem(
          /// Theme configuration
          fieldName: (widget.fieldName == null && !widget.isRequired)
              ? null
              : "${widget.fieldName?.trim() ?? ""}${widget.isRequired ? "*" : ""}",
          fieldAction:
              "package.ui-kosmos_v4.field.input.disponibility.set-${isClosed ? "open" : "close"}"
                  .tr(),
          theme: themeData,
          fieldActionOnTap: () {
            setState(() => isClosed = !isClosed);
            widget.onChanged?.call(_value, isClosed);
          },
          isError: widget.isError,
          showErrorTitle: widget.showErrorTitle,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isClosed) ...[
                Text(
                  "package.ui-kosmos_v4.field.input.disponibility.closed".tr(),
                  style: themeData.fieldTextStyle ??
                      DefaultAppStyle.darkSteel(12, FontWeight.w500),
                ),
              ] else ...[
                for (var i = 0; i < _value.length; i++) ...[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: FormHourField(
                          showOnlyHour: widget.showOnlyHour,
                          isError: field.hasError,
                          initialValue: _value[i].from != null
                              ? TimeOfDay(
                                  hour: _value[i].from!.hour,
                                  minute: _value[i].from!.minute)
                              : null,
                          fieldName:
                              "package.ui-kosmos_v4.field.input.disponibility.${_value[i].isPaused ? "pause" : "open"}-from"
                                  .tr(),
                          onChanged: (val) {
                            setState(() => _value[i] = _value[i].copyWith(
                                from: DateTime(
                                    1970, 1, 1, val.hour, val.minute)));
                            widget.onChanged?.call(_value, isClosed);
                            field.didChange(_value);
                          },
                        ),
                      ),
                      Padding(
                        padding: pw(17.5),
                        child: Column(
                          children: [
                            sh(17),
                            Text(
                              "package.ui-kosmos_v4.field.input.disponibility.to"
                                  .tr(),
                              style: themeData.fieldTextStyle ??
                                  DefaultAppStyle.darkBlue(13, FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FormHourField(
                          showOnlyHour: widget.showOnlyHour,
                          isError: field.hasError,
                          fieldName: "",
                          initialValue: _value[i].to != null
                              ? TimeOfDay(
                                  hour: _value[i].to!.hour,
                                  minute: _value[i].to!.minute)
                              : null,
                          fieldAction: widget.canRemoveFirst || i >= 1
                              ? "package.ui-kosmos_v4.field.input.disponibility.delete-${_value[i].isPaused ? "pause" : "disponibility"}"
                                  .tr()
                              : null,
                          fieldActionOnTap: () {
                            setState(() => _value.removeAt(i));
                            widget.onChanged?.call(_value, isClosed);
                            field.didChange(_value);
                          },
                          onChanged: (val) {
                            setState(() => _value[i] = _value[i].copyWith(
                                to: DateTime(
                                    1970, 1, 1, val.hour, val.minute)));
                            widget.onChanged?.call(_value, isClosed);
                            field.didChange(_value);
                          },
                        ),
                      ),
                    ],
                  ),
                  sh(10),
                ],
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: formatHeight(43)),
                  decoration: BoxDecoration(
                      color: inputDecoration.fillColor, borderRadius: radius),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _value = [
                                    ..._value,
                                    const DisponibilityItemModel(isPaused: true)
                                  ]);
                              widget.onChanged?.call(_value, isClosed);
                              field.didChange(_value);
                            },
                            child: Padding(
                              padding: pw(25),
                              child: Center(
                                child: Text(
                                  "package.ui-kosmos_v4.field.input.disponibility.pause"
                                      .tr(),
                                  style: themeData.subItemFieldTextStyle ??
                                      DefaultAppStyle.darkSteel(
                                          12, FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: ph(5),
                          child: Container(
                              width: 1,
                              color: themeData.fieldTextStyle?.color ??
                                  DefaultColor.grey),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _value = [
                                    ..._value,
                                    const DisponibilityItemModel(
                                        isPaused: false)
                                  ]);
                              widget.onChanged?.call(_value, isClosed);
                              field.didChange(_value);
                            },
                            child: Padding(
                              padding: pw(25),
                              child: Center(
                                child: Text(
                                  "package.ui-kosmos_v4.field.input.disponibility.add"
                                      .tr(),
                                  style: themeData.subItemFieldTextStyle ??
                                      DefaultAppStyle.darkSteel(
                                          12, FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (field.hasError) ...[
                sh(10),
                Text(
                  field.errorText ?? "",
                  style: inputDecoration.errorStyle ??
                      DefaultAppStyle.error(12, FontWeight.w500),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
