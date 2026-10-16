import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ui_kosmos_v4/notifBanner/notif_banner.dart';

/// Bannière de notification standard de l'application (Kosmos `NotifBanner`).
///
/// À utiliser à la place des `SnackBar` (convention projet). Affiche une
/// bannière haute, verte en cas de succès, rouge en cas d'erreur.
///
/// NB : `NotifBanner` n'est pas exporté par le barrel `ui_kosmos_v4` ; il faut
/// l'importer directement. Aucun thème n'a besoin d'être enregistré.
void showAppNotif(
  BuildContext context, {
  required String title,
  String? subTitle,
  bool success = true,
}) {
  NotifBanner.showToast(
    context: context,
    fToast: FToast().init(context),
    title: title,
    subTitle: subTitle,
    backgroundColor: success ? DefaultColor.success : DefaultColor.error,
  );
}
