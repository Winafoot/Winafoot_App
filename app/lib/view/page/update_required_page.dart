import 'dart:developer' as developer;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/check_profil_form.dart';

/// Page plein écran affichée quand le build installé est inférieur au build
/// minimal exigé (`app_config/metadata.minBuild`). Bascule pilotée en temps
/// réel par [MaintenanceGate] ; la page ne se ferme pas, seul le bouton
/// ouvre la fiche du store ([storeUrl]).
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key, this.storeUrl});

  /// Lien vers la fiche du store, lu dans `app_config/metadata.storeUrl`.
  /// Sans lien, la page s'affiche sans bouton.
  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    final String? url = storeUrl;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColor.fieldsBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Iconsax.refresh_circle,
                  size: 72,
                  color: AppColor.primaryColor,
                ),
                sh(24),
                Text(
                  'app.update-required-page.titre'.tr(),
                  textAlign: TextAlign.center,
                  style: AppThemeStyle.boldStyle(22, AppColor.primaryLabels),
                ),
                sh(12),
                Text(
                  'app.update-required-page.message'.tr(),
                  textAlign: TextAlign.center,
                  style: AppThemeStyle.regularStyle(
                    15,
                    AppColor.secondaryLabels,
                  ),
                ),
                if (url != null) ...[
                  sh(32),
                  SizedBox(
                    width: 320,
                    child: CpButton(
                      label: 'app.update-required-page.bouton'.tr(),
                      onTap: () => _openStore(url),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      developer.log(
        'Ouverture du store impossible',
        name: 'UpdateRequired',
        error: e,
        stackTrace: st,
      );
    }
  }
}
