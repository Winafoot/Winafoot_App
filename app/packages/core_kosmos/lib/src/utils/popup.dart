import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

/// {@category Utils}
///
/// Permet de sélectionner la source de l'uimage (uniquement
/// disponible sur iOS / Android).
Future<ImageSource?> pickImageSourceType(BuildContext context, String? title) async {
  title ??= "package.core.popup.select-picture-from";

  return await showCupertinoModalPopup<ImageSource>(
    context: context,
    builder: (context) {
      return CupertinoActionSheet(
        message: Text(title!.tr()),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: Text('package.image.from-gallery'.tr()),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: Text('package.image.from-camera'.tr()),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('utils.cancel'.tr()),
        ),
      );
    },
  );
}
