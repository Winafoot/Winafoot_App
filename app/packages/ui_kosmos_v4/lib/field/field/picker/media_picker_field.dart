import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '_private/builder.dart';
import '_private/file_form_field_extend.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Ce champ de formulaire permet de choisir une image ou une vidéo
/// avec une perview.
/// Ce widget utilise le système de [ImageFileController.pickMedia]
/// pour pouvoir sélectionner les médias.
///
/// Vous pouvez définir le type de média à choisir avec [assetType].
///
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction]
/// à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la
/// forme d'un widget.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de
/// validation de [AuthValidator] et [FieldValidator] du package
/// Core_Kosmos.
///
/// ![media_field](../../images/field/media_field.png)
///
/// Exemple:
///
/// ```Dart
/// FormMediaPickerField(
///   fieldName: "Media Example",
///   onChanged: (assets) => printDebug(assets),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut
/// via le [FormFieldThemeData] : "form_field".
class FormMediaPickerField extends ConsumerStatefulWidget {
  final RequestType assetType;
  final bool allowMultiple;
  final FormFieldValidator<List<AssetEntity>>? validator;
  final FormFieldSetter<List<AssetEntity>>? onSaved;
  final bool canRemoveImage;
  final void Function(List<AssetEntity>)? onChanged;
  final List<AssetEntity>? initialValue;
  final List<MediaModel>? initialMedia;

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

  const FormMediaPickerField({
    super.key,
    this.allowMultiple = true,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.assetType = RequestType.common,
    this.isRequired = false,
    this.isError = false,
    this.showErrorTitle = false,
    this.canRemoveImage = true,
    this.initialValue,
    this.initialMedia,

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
  ConsumerState<FormMediaPickerField> createState() =>
      _FormMediaPickerFieldState();
}

class _FormMediaPickerFieldState extends ConsumerState<FormMediaPickerField> {
  bool isInitialValue = true;

  List<AssetEntity> entity = [];
  final GlobalKey<FormFieldState> _key = GlobalKey<FormFieldState>();

  @override
  void initState() {
    printError("obj");
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
      child: FileFormField<AssetEntity>(
        key: _key,
        isDark: ref.watch(isDarkModeProvider).isDarkMode,
        onPick: (context) => ImageFileController.pickMedia(
          context,
          assetType: widget.assetType,
          allowMultiple: widget.allowMultiple,
        ),
        contentPadding: themeData.filePickerContentPadding ??
            EdgeInsets.symmetric(
                horizontal: formatWidth(12), vertical: formatHeight(13)),
        validator: widget.validator,
        onSaved: widget.onSaved,
        initialValue: widget.initialValue != null && isInitialValue
            ? widget.initialValue!
            : null,
        childBuilder: (context, files) {
          if (widget.initialMedia != null &&
              widget.initialMedia!.isNotEmpty &&
              files.isEmpty &&
              isInitialValue) {
            return buildInitialMedia(
              context,
              ref.watch(isDarkModeProvider).isDarkMode,
              widget.initialMedia!,
              (widget.canRemoveImage && !isInitialValue)
                  ? (index) {
                      widget.initialMedia?.removeAt(index);
                      _key.currentState?.didChange(files);
                      widget.onChanged?.call(files);
                    }
                  : null,
              themeData.imagePickerImageHeight ?? formatHeight(96),
            );
          }

          if (files.isEmpty) {
            return buildEmptyPickerContent(
                "package.ui-kosmos_v4.field.input.choose-media".tr(),
                ref.watch(isDarkModeProvider).isDarkMode,
                inputDecoration.hintStyle?.color);
          }

          return buildMediaEntityList(
            context,
            ref.watch(isDarkModeProvider).isDarkMode,
            files,
            (widget.canRemoveImage && !isInitialValue)
                ? (index) {
                    files.removeAt(index);
                    _key.currentState?.didChange(files);
                    widget.onChanged?.call(files);
                  }
                : null,
            themeData.imagePickerImageHeight ?? formatHeight(96),
          );
        },
        onChanged: (list) {
          isInitialValue = false;
          entity = list;
          widget.onChanged?.call(list);
        },
      ),
    );
  }
}
