// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ui_kosmos_v4/field/field/picker/_private/file_form_field_extend.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:dartz/dartz.dart' as dz;

import '_private/builder.dart';

/// {@category Widget}
/// {@category Form, Input}
///
/// Champ de formulaire pour choisir une image + preview.
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Pour vos Validators, vous pouvez utiliser les fonctions de validation de [AuthValidator] et [FieldValidator] du package Core_Kosmos.
///
/// Exemple:
///
/// ![form_field_item](../../images/field/image_picker_field.png)
///
/// ```dart
/// FormImagePickerField(
///   fieldName: "Field Name",
///   onChanged: ((p0) {
///   }),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
class FormImagePickerField extends ConsumerStatefulWidget {
  final List<String>? allowedExtensions;
  final FormFieldValidator<List<dz.Either<PlatformFile, XFile>>>? validator;
  final FormFieldSetter<List<dz.Either<PlatformFile, XFile>>>? onSaved;
  final void Function(List<dz.Either<PlatformFile, XFile>>)? onChanged;
  final List<String>? initialValueUrl;
  final List<dz.Either<PlatformFile, XFile>>? initialValue;
  final ImageSource? onlyOneSource;
  final bool canRemoveImage;

  final bool isRequired;
  final bool isError;
  final bool showErrorTitle;
  final bool isEnabled;

  /// Item
  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;

  /// Theme
  final String? themeName;
  final FormFieldThemeData? theme;
  final InputDecoration? inputDecoration;

  const FormImagePickerField({
    super.key,
    this.allowedExtensions,
    this.validator,
    this.initialValue,
    this.canRemoveImage = true,
    this.onSaved,
    this.onChanged,
    this.initialValueUrl,
    this.isRequired = false,
    this.isError = false,
    this.showErrorTitle = false,
    this.onlyOneSource,
    this.isEnabled = true,

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
  ConsumerState<FormImagePickerField> createState() =>
      _FormImagePickerFieldState();
}

class _FormImagePickerFieldState extends ConsumerState<FormImagePickerField> {
  List<dz.Either<PlatformFile, XFile>> _value = [];
  List<String>? _initialValueUrl;

  final GlobalKey<FormFieldState> _key = GlobalKey<FormFieldState>();

  @override
  void initState() {
    _value = widget.initialValue ?? [];
    _initialValueUrl = List.from(widget.initialValueUrl ?? []);

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
      child: FileFormField<dz.Either<PlatformFile, XFile>>(
        isDark: ref.watch(isDarkModeProvider).isDarkMode,
        key: _key,
        onPick: widget.isEnabled ? _pickFile : null,
        initialValue: _value,
        contentPadding: (themeData.imagePickerContentPadding ??
                EdgeInsets.symmetric(
                    horizontal: formatWidth(7), vertical: formatHeight(6)))
            .copyWith(right: _value.isNotEmpty ? formatWidth(30) : null),
        childBuilder: (context, files) {
          if (_initialValueUrl != null &&
              _initialValueUrl!.isNotEmpty &&
              files.isEmpty) {
            return buildInitialImage(
              context,
              ref.watch(isDarkModeProvider).isDarkMode,
              _initialValueUrl!,
              widget.canRemoveImage
                  ? (index) {
                      _initialValueUrl?.removeAt(index);
                      _key.currentState?.didChange(files);
                      widget.onChanged?.call(files);
                    }
                  : null,
              themeData.imagePickerImageHeight ?? formatHeight(96),
            );
          }

          if (files.isEmpty) {
            return buildEmptyPickerContent(
                "package.ui-kosmos_v4.field.input.choose-image".tr(),
                ref.watch(isDarkModeProvider).isDarkMode,
                inputDecoration.hintStyle?.color);
          }

          return buildPickedImage(
            context,
            ref.watch(isDarkModeProvider).isDarkMode,
            files,
            widget.canRemoveImage
                ? (index) {
                    files.removeAt(index);
                    _key.currentState?.didChange(files);
                    widget.onChanged?.call(files);
                  }
                : null,
            themeData.imagePickerImageHeight ?? formatHeight(96),
          );
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

  FutureOr<List<dz.Either<PlatformFile, XFile>>?> _pickFile(
      BuildContext context) async {
    final List<dz.Either<PlatformFile, XFile>> t = [];
    if (kIsWeb) {
      final r = await ImageFileController.pickFileFromDevice(
          context, false, ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg"]);
      r?.forEach((element) => t.add(dz.Left(element)));

      if (t.isNotEmpty) _initialValueUrl?.clear();

      return t;
    }

    final source =
        widget.onlyOneSource ?? await pickImageSourceType(context, null);

    if (source == null) return null;
    if (!mounted) return null;

    if (source == ImageSource.camera &&
        (await Permission.camera.isDenied ||
            await Permission.camera.isPermanentlyDenied)) {
      if (kDebugMode) {
        print(
            'Permission.camera.isDenied || Permission.camera.isPermanentlyDenied');
      }
      final perm = await Permission.camera.request();
      if (perm.isDenied || perm.isPermanentlyDenied) {
        if (context.mounted) {
          await SettingsController.permissionToRedirectToSettings(
              context, "camera");
        }
        return null;
      }
    } else if (Platform.isIOS) {
      PermissionStatus photosPerm = await Permission.photos.request();
      PermissionStatus storagePerm = await Permission.storage.request();

      // if (source == ImageSource.gallery && !mediaLibraryPerm.isGranted) {
      //   if (kDebugMode) {
      //     print(
      //         'Permission.mediaLibrary.isDenied || Permission.mediaLibrary.isPermanentlyDenied');
      //   }
      //   final perm = await Permission.mediaLibrary.request();
      //   if (perm.isDenied || perm.isPermanentlyDenied) {
      //     await openAppSettings();
      //     return null;
      //   }
      // } else

      if (source == ImageSource.gallery && !photosPerm.isGranted) {
        if (kDebugMode) {
          print(
              'Permission.photos.isDenied || Permission.photos.isPermanentlyDenied');
        }
        final perm = await Permission.photos.request();
        if (perm.isDenied || perm.isPermanentlyDenied) {
          if (context.mounted) {
            await SettingsController.permissionToRedirectToSettings(
                context, "photos");
          }
          return null;
        } else if (source == ImageSource.gallery && !storagePerm.isGranted) {
          if (kDebugMode) {
            print(
                'Permission.storage.isDenied || Permission.storage.isPermanentlyDenied');
          }
          final perm = await Permission.storage.request();
          if (perm.isDenied || perm.isPermanentlyDenied) {
            if (context.mounted) {
              await SettingsController.permissionToRedirectToSettings(
                  context, "storage");
            }
            return null;
          }
        }
      }
    } 

    if (!mounted) return null;

    try {
      final result = await {
        ImageSource.camera: ImageFileController.pickImageFromCamera,
        ImageSource.gallery: ImageFileController.pickImageFromGallery,
      }[source]!
          .call(context);

      if (result == null) return null;

      t.add(dz.Right(result));
      if (t.isNotEmpty) _initialValueUrl?.clear();

      return t;
    } catch (e) {
      printExcept(e);
    }
    return null;
  }
}
