// ignore_for_file: use_build_context_synchronously

import 'package:core_kosmos/core_kosmos.dart';
import 'package:core_kosmos/src/controller/settings_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// {@category Controller}
///
/// Permet de gérer les permissions de géolocalisation.
/// - [requestGeoloc] : Permet de demander la permission de géolocalisation.
/// - [isGeolocGranted] : Permet de vérifier si la permission de géolocalisation est accordée.
///
abstract class GeolocController {
  /// Permet de demander la permission de géolocalisation.
  static Future<bool> requestGeoloc(BuildContext context,
      [bool alreadyRequest = false]) async {
    try {
      PermissionStatus permissionStatus = await Permission.location.status;
      switch (permissionStatus) {
        case PermissionStatus.granted:
          return true;
        case PermissionStatus.denied:
          permissionStatus = await Permission.location.request();
          return true;
        case PermissionStatus.permanentlyDenied:
          return await SettingsController.permissionToRedirectToSettings(
              context, "location");
        default:
          break;
      }
    } catch (e) {
      printExcept(e);
      return false;
    }
    return true;
  }

  /// Permet de vérifier si la permission de géolocalisation est accordée.
  static Future<bool> isGeolocGranted() async {
    try {
      final permissionStatus = await Permission.location.status;
      return permissionStatus.isGranted;
    } catch (e) {
      printExcept(e);
      return false;
    }
  }
}
