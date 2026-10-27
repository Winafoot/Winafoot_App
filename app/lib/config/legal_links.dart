import 'package:flutter/widgets.dart';
import 'package:skeleton/skeleton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wina/view/widget/app_notif.dart';

/// Pages légales publiées sur le site de l'app.
const String kSiteUrl = 'https://winafoot.fr';
final Uri kCguUri = Uri.parse('$kSiteUrl/cgu');
final Uri kPrivacyUri = Uri.parse('$kSiteUrl/confidentialite');
final Uri kLegalNoticeUri = Uri.parse('$kSiteUrl/mentions');

/// Ouvre [uri] dans le navigateur et prévient l'utilisateur si le lien ne peut pas s'ouvrir.
Future<void> openLegalLink(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Aucun navigateur disponible : on tombe sur la notification.
  }
  if (!context.mounted) return;
  showAppNotif(
    context,
    title: 'utils.error'.tr(),
    subTitle: 'utils.error-default'.tr(),
    success: false,
  );
}
