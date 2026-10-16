import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class SettingsController {
  static Future<bool> permissionToRedirectToSettings(
      BuildContext context, String permission) async {
    return (await showCupertinoDialog<bool?>(
          context: context,
          builder: (BuildContext ctx) {
            return CupertinoAlertDialog(
              title: Text('package.permission.$permission.title'.tr()),
              content: Text(
                  "package.permission.$permission.redirect-to-settings".tr()),
              actions: [
                TextButton(
                  child: Text(
                    'package.permission.$permission.button'.tr(),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop(true);
                    await openAppSettings();
                  },
                ),
                TextButton(
                  child: Text(
                    'package.permission.skip'.tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                  },
                ),
              ],
            );
          },
        )) ??
        false;
  }
}
