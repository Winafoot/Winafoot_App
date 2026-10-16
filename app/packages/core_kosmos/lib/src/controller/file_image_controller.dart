// ignore_for_file: unused_import, use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dartz/dartz.dart' as dz;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

/// {@category Controller}
///
/// Permet de gérer les images et fichiers.
///
/// - [pickImageFromCamera] : Permet de prendre une photo depuis la camera.
/// - [pickImageFromGallery] : Permet de prendre une photo depuis la gallerie
/// - [pickMedia] : Permet de choisir un media depuis les images ou depuis l'appareil photo en le package de WeChat.
/// - [pickFileFromDevice] : Permet de choisir un fichier depuis le device.
/// - [uploadFileToFirebaseStorage] : Upload un XFile vers Firebase Storage, avec un path donnée.
/// - [uploadPlatformFileToFirebaseStorage] : Upload un PlatformFile vers Firebase Storage, avec un path donnée.
///
abstract class ImageFileController {
  /// Permet de prendre une photo depuis la camera.
  static Future<XFile?> pickImageFromCamera(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    bool isEnabled = await permissionIsEnbled(context,
        source: ImageSource.camera, assetType: RequestType.image);
    if (!isEnabled) return null;
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;
    return image;
  }

  /// Permet de prendre une photo depuis la gallerie.
  static Future<XFile?> pickImageFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    return image;
  }

  static Future<List<XFile>> pickImages(BuildContext context,
      {int limit = 8}) async {
    final source = await pickImageSourceType(context, null);
    if (source == null) return [];
    if (source == ImageSource.gallery) {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(limit: limit);
      return images;
    } else {
      XFile? file = await pickImageFromCamera(
        context,
      );
      return file == null ? [] : [file];
    }
  }

  static Future<List<XFile>> pickMultipleMediaAndroid(BuildContext context,
      {int limit = 8}) async {
    final source = await pickImageSourceType(context, null);
    if (source == null) return [];
    if (source == ImageSource.gallery) {
      return await pickMultipleMediaFromGalleryAndroid(context, limit: limit);
    } else {
      XFile? file = await pickImageFromCamera(
        context,
      );
      return file == null ? [] : [file];
    }
  }

  static Future<List<XFile>> pickMultipleMediaFromGalleryAndroid(
      BuildContext context,
      {int limit = 8}) async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultipleMedia(limit: limit);
    return images;
  }

  /// Permet de choisir un fichier depuis le device.
  static Future<List<PlatformFile>?> pickFileFromDevice(BuildContext context,
      [bool allowMultiple = true, List<String>? allowedExtensions]) async {
    final result = await FilePicker.pickFiles(
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions,
        type: allowedExtensions != null ? FileType.custom : FileType.any);
    return result?.files;
  }

  /// Permet de choisir un media depuis les
  /// images ou depuis l'appareil photo en
  /// le package de WeChat.
  ///
  static Future<bool> permissionIsEnbled(
    BuildContext context, {
    RequestType assetType = RequestType.common,
    ImageSource? source,
    bool allowMultiple = true,
  }) async {
    if (source == null) return false;

    switch (source) {
      case ImageSource.camera:
        PermissionStatus cameraPermission = await Permission.camera.status;
        PermissionStatus microphonePermission =
            await Permission.microphone.status;
        if (cameraPermission.isGranted) {
          if (microphonePermission.isGranted) {
            return true;
          } else {
            if (microphonePermission.isPermanentlyDenied) {
              await SettingsController.permissionToRedirectToSettings(
                  context, "microphone");
              return false;
            }
            microphonePermission = await Permission.microphone.request();
            if (microphonePermission.isGranted) {
              return true;
            } else {
              return false;
            }
          }
        } else {
          if (cameraPermission.isPermanentlyDenied) {
            await SettingsController.permissionToRedirectToSettings(
                context, "camera");
            return false;
          }
          cameraPermission = await Permission.camera.request();
          if (cameraPermission.isGranted) {
            if (microphonePermission.isGranted) {
              return true;
            } else {
              if (microphonePermission.isPermanentlyDenied) {
                await SettingsController.permissionToRedirectToSettings(
                    context, "microphone");
                return false;
              }
              microphonePermission = await Permission.microphone.request();
              if (microphonePermission.isGranted) {
                return true;
              } else {
                return false;
              }
            }
          } else {
            return false;
          }
        }

      case ImageSource.gallery:
        if (Platform.isIOS) {
          return await checkElementPermission(context, 0, 1);
        } else if (Platform.isAndroid) {
          AndroidDeviceInfo androidDeviceInfo =
              await DeviceInfoPlugin().androidInfo;
          bool sdkInt = (androidDeviceInfo.version.sdkInt) >= 33;

          if (sdkInt) {
            PermissionStatus photosPerm = await Permission.photos.status;
            if (photosPerm.isGranted) return true;

            if (photosPerm.isPermanentlyDenied) {
              await SettingsController.permissionToRedirectToSettings(
                  context, "photos");
              return false;
            }
            photosPerm = await Permission.photos.request();
            if (photosPerm.isGranted) return true;
            return false;
          } else {
            PermissionStatus storagePermission =
                await Permission.storage.status;
            if (storagePermission.isGranted) return true;

            if (storagePermission.isPermanentlyDenied) {
              await SettingsController.permissionToRedirectToSettings(
                  context, "storage");
              return false;
            }
            storagePermission = await Permission.storage.request();
            if (storagePermission.isGranted) return true;
          }
        }
        return false;
    }
  }

  static List<Permission> permissions = [
    Permission.photos,
    //Permission.mediaLibrary,
    Permission.storage
  ];

  static FutureOr<bool> checkElementPermission(
      BuildContext context, int index, int? nextIndex) async {
    PermissionStatus status = await permissions[index].status;
    if (status.isGranted) {
      if (nextIndex == null) {
        return true;
      }
      return await checkElementPermission(context, nextIndex,
          nextIndex == permissions.length - 1 ? null : nextIndex + 1);
    } else if (status.isPermanentlyDenied) {
      await SettingsController.permissionToRedirectToSettings(
          context, permissions[index].toString().split('.').last);
      return false;
    }
    status = await permissions[index].request();
    if (status.isGranted || status.isLimited) {
      if (nextIndex == null) {
        return true;
      }
      return await checkElementPermission(context, nextIndex,
          nextIndex == permissions.length - 1 ? null : nextIndex + 1);
    }
    return false;
  }

  static Future<List<AssetEntity>?> pickMedia(BuildContext context,
      {RequestType assetType = RequestType.common,
      ImageSource? source,
      DeviceOrientation? lockCaptureOrientation,
      bool allowMultiple = true,
      int maxAssets = 8}) async {
    final CustomWechatPicker? config = getAppModel()
        .getDependenciesFromName<CustomWechatPicker>("wechat_picker");

    source = source ?? await pickImageSourceType(context, null);
    if (source == null) return [];

    bool isEnabled =
        await permissionIsEnbled(context, source: source, assetType: assetType);
    if (!isEnabled) return null;
    if (source == ImageSource.camera) {
      final AssetEntity? entity = await CameraPicker.pickFromCamera(
        context,
        createPickerState: config?.customWechatPicketState == null
            ? null
            : () => config!.customWechatPicketState!,
        pickerConfig: CameraPickerConfig(
          enableRecording: assetType.containsVideo(),
          enableAudio: assetType.containsVideo(),
          theme: ThemeData.dark().copyWith(
            colorScheme: GetIt.instance<AppTheme>().themeData?.colorScheme ??
                ColorScheme.dark(),
          ),
          lockCaptureOrientation: DeviceOrientation.portraitUp,
          maximumRecordingDuration: const Duration(seconds: 120),
          textDelegate: const KosmosCameraDelegate(),
        ),
      );
      return entity != null ? [entity] : [];
    } else {
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
            pickerTheme: ThemeData.dark().copyWith(
              colorScheme: GetIt.instance<AppTheme>().themeData?.colorScheme ??
                  ColorScheme.dark(),
            ),
            maxAssets: allowMultiple ? maxAssets : 1,
            requestType: assetType),
      );
      return result ?? [];
    }
  }

  /// Upload un XFile vers Firebase Storage, avec un path donnée.
  static Future<String?> uploadFileToFirebaseStorage(XFile file, String path,
      [FirebaseStorage? instance]) async {
    final Reference ref = (instance ?? FirebaseStorage.instance).ref(path);
    final UploadTask uploadTask = ref.putFile(File(file.path));
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Upload un platform file vers Firebase Storage, avec un path donnée.
  static Future<String?> uploadPlatformFileToFirebaseStorage(
      PlatformFile file, String path,
      [FirebaseStorage? instance]) async {
    if (file.path == null) {
      printError('Le fichier n\'a pas de path');
      return null;
    }
    final Reference ref = (instance ?? FirebaseStorage.instance).ref(path);
    final UploadTask uploadTask = ref.putFile(File(file.path ?? ''));
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Upload un file vers Firebase Storage, avec un path donnée.
  static Future<String?> uploadStandartFileToFirebaseStorage(
      File file, String path,
      [FirebaseStorage? instance]) async {
    String? mimeType = lookupMimeType(file.path);
    final Reference ref = (instance ?? FirebaseStorage.instance).ref(path);
    final UploadTask uploadTask =
        ref.putFile(file, SettableMetadata(contentType: mimeType));
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Uploads a Uint8List file to Firebase Storage at the given path and returns the download URL.
  /// Returns null if the upload fails.
  static Future<String?> uploadUint8ListToFirebaseStorage(
      Uint8List file, String path) {
    final Reference ref = FirebaseStorage.instance.ref(path);
    final UploadTask uploadTask = ref.putData(file);
    return uploadTask
        .then((TaskSnapshot snapshot) => snapshot.ref.getDownloadURL());
  }

  /// Permet de sauvegarder un fichier sur le device.
  /// dans le dossier de l'application.
  ///
  /// - [file] : Le fichier à sauvegarder.
  /// - [fileName] : Le nom du fichier.
  /// - [path] : Le chemin du fichier.
  ///
  /// En cas d'erreur, retourne une valeur null.
  /// En cas de succès, retourne le chemin du fichier.
  static Future<String?> saveFileLocaly(
      File file, String fileName, String path) async {
    try {
      final String appPath = (await getApplicationDocumentsDirectory()).path;
      final String filePath = '$appPath/$path/$fileName';

      await file.copy(filePath);
      return filePath;
    } catch (e) {
      printExcept(e);
      return null;
    }
  }

  static Future<bool> saveMediaInGalery(
      File file, AssetType type, String filename) async {
    try {
      if (type == AssetType.video) {
        // Enregistrement dans la galerie désactivé.
        // await GallerySaver.saveVideo(file.path, albumName: filename);
      } else {
        // await GallerySaver.saveImage(file.path, albumName: filename);
      }
      return true;
    } catch (e) {
      printExcept(e);
      return false;
    }
  }

  static Future<String?> downloadFileAndSaveLocally(
      Uri uri, String path) async {
    try {
      final String appPath = (await getApplicationDocumentsDirectory()).path;
      final String filePath = '$appPath/$path';
      final File file = File(filePath);

      try {
        if (file.existsSync()) return filePath;
      } catch (_) {}

      final http.Response response = await http.get(uri);
      await file.create(recursive: true);

      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      printExcept(e);
      return null;
    }
  }

  static Future<dz.Tuple2<String, bool>?>
      downloadFileAndSaveLocallyAndCheckIfExists(Uri uri, String path) async {
    try {
      final String appPath = (await getApplicationDocumentsDirectory()).path;
      final String filePath = '$appPath/$path';
      final File file = File(filePath);

      try {
        if (file.existsSync()) return dz.Tuple2(filePath, true);
      } catch (_) {}

      final http.Response response = await http.get(uri);
      await file.create(recursive: true);

      await file.writeAsBytes(response.bodyBytes);
      return dz.Tuple2(filePath, false);
    } catch (e) {
      printExcept(e);
      return null;
    }
  }
}
