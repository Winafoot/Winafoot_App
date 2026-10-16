import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';

/// Page plein écran affichée quand `app_config/metadata.maintenance == true`.
/// Bascule pilotée en temps réel par [MaintenanceGate].
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.fieldsBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Iconsax.setting_2,
                size: 72,
                color: AppColor.primaryColor,
              ),
              sh(24),
              Text(
                'app.maintenance-page.titre'.tr(),
                textAlign: TextAlign.center,
                style: AppThemeStyle.boldStyle(22, AppColor.primaryLabels),
              ),
              sh(12),
              Text(
                'app.maintenance-page.message'.tr(),
                textAlign: TextAlign.center,
                style: AppThemeStyle.regularStyle(15, AppColor.secondaryLabels),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
