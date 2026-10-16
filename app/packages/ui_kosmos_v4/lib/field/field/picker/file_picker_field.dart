// ignore_for_file: depend_on_referenced_packages

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/field/field/picker/_private/file_form_field_extend.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:dartz/dartz.dart' as dz;

import '_private/builder.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Champ de formulaire pour picker de fichier, permet la sélection d'un fichier.
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de validation de [AuthValidator] et [FieldValidator] du package Core_Kosmos.
///
/// l'objet [FormFieldPickerField] est un wrapper qui permet de récupérer une liste
/// de [PlatformFile].
/// Si vous souhaitez n'autorisé qu'un seul fichier, vous pouvez utiliser le paramètre [allowMultiple] à false.
/// Vous pouvez décidez de réstreindre à certaines extensions de fichier, via le paramètre [allowedExtensions].
///
/// Exemple:
///
/// ![form_field_item](../../images/field/file_picker_field.png)
///
/// ```dart
/// FormFilePickerField(
///   fieldName: "Field Name",
///   onChanged: ((p0) {
///   }),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
class FormFilePickerField extends ConsumerStatefulWidget {
  final List<String>? allowedExtensions;
  final bool allowMultiple;
  final FormFieldValidator<List<PlatformFile>>? validator;
  final FormFieldSetter<List<PlatformFile>>? onSaved;
  final void Function(List<PlatformFile>)? onChanged;
  final List<PlatformFile>? initialValue;
  final List<dz.Tuple2<String, String>>? initialUploadedValue;

  final bool isRequired;
  final bool isError;
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

  const FormFilePickerField({
    super.key,
    this.allowedExtensions,
    this.allowMultiple = true,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.initialValue,
    this.initialUploadedValue,
    this.isRequired = false,
    this.isError = false,
    this.showErrorTitle = false,

    /// Item
    this.fieldAction,
    this.fieldActionOnTap,
    this.fieldName,
    this.fieldSuffix,

    /// Theme
    this.theme,
    this.themeName,
    this.inputDecoration,
  });

  @override
  ConsumerState<FormFilePickerField> createState() =>
      _FormFilePickerFieldState();
}

class _FormFilePickerFieldState extends ConsumerState<FormFilePickerField> {
  List<PlatformFile> _value = [];

  final GlobalKey<FormFieldState> _key = GlobalKey<FormFieldState>();

  @override
  void initState() {
    _value = widget.initialValue ?? [];
    for (final item in widget.initialUploadedValue ?? []) {
      _value.add(PlatformFile(
        name: item.value1,
        path: item.value2,
        size: -1,
      ));
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
      isError: widget.isError,
      showErrorTitle: widget.showErrorTitle,
      theme: themeData,

      /// Field widget
      child: FileFormField<PlatformFile>(
        key: _key,
        isDark: ref.watch(isDarkModeProvider).isDarkMode,
        onPick: (context) async => await ImageFileController.pickFileFromDevice(
            context, widget.allowMultiple, widget.allowedExtensions),
        initialValue: _value,
        contentPadding: themeData.filePickerContentPadding ??
            EdgeInsets.symmetric(
                horizontal: formatWidth(26), vertical: formatHeight(13)),
        childBuilder: (context, files) {
          if (files.isEmpty) {
            return buildEmptyPickerContent(
                "package.ui-kosmos_v4.field.input.choose${widget.allowMultiple ? "-multiple" : ""}-file"
                    .tr(),
                ref.watch(isDarkModeProvider).isDarkMode,
                inputDecoration.hintStyle?.color);
          }

          return buildFileNameList(
              context,
              ref.watch(isDarkModeProvider).isDarkMode,
              files.map((e) => e.name).toList(), (index) {
            files.removeAt(index);
            _key.currentState?.didChange(files);
            widget.onChanged?.call(files);
          });
        },
        validator: widget.validator,
        onSaved: widget.onSaved,
        onChanged: (list) {
          _value = list;
          widget.onChanged?.call(list);
        },
      ),
    );
  }
}
