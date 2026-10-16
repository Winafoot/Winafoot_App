import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/notification_bell.dart';
import 'package:wina/view/widget/settings_button.dart';

/// Onglet « IA Wina » (bientôt disponible) : entête + message d'attente centré.
class IaScreen extends StatelessWidget {
  const IaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [sh(18), const _IaHeader(), sh(14), VerticalDivider()],
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formatWidth(440)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: formatWidth(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ComingSoonBadge(),
                    sh(18),
                    Text(
                      'app.ia.titre'.tr(),
                      textAlign: TextAlign.center,
                      style: AppThemeStyle.semiBStyle(
                        20,
                        AppColor.primaryLabels,
                      ),
                    ),
                    sh(12),
                    Text(
                      'app.ia.description'.tr(),
                      textAlign: TextAlign.center,
                      style: AppThemeStyle.regularStyle(
                        14,
                        AppColor.secondaryLabels,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IaHeader extends StatelessWidget {
  const _IaHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Iconsax.messages_2, size: sp(24), color: AppColor.primaryColor),
        sw(10),
        Text(
          'app.ia.entete'.tr(),
          style: AppThemeStyle.semiBStyle(28, AppColor.primaryLabels),
        ),
        const Spacer(),
        const NotificationBell(),
        sw(16),
        const SettingsButton(),
        sw(18),
        const WinaWordmark(),
      ],
    );
  }
}

/// Pastille « ● Bientôt disponible » (vert pâle).
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(14),
        vertical: formatHeight(7),
      ),
      decoration: BoxDecoration(
        color: AppColor.textLight,
        borderRadius: BorderRadius.circular(r(16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: sp(19),
            height: sp(19),
            child: Icon(
              Iconsax.timer_1,
              size: sp(19),
              color: AppColor.primaryColor,
            ),
          ),
          sw(8),
          Text(
            'app.ia.bientot-disponible'.tr(),
            style: AppThemeStyle.mediumStyle(13, AppColor.primaryLabels),
          ),
        ],
      ),
    );
  }
}

/// Onglet générique « bientôt disponible » (Statistiques matchs, Test équipe).
class ComingSoonTab extends StatelessWidget {
  const ComingSoonTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sh(18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeStyle.semiBStyle(
                        30,
                        AppColor.primaryLabels,
                      ),
                    ),
                  ),
                  const NotificationBell(),
                  sw(16),
                  const SettingsButton(),
                  sw(18),
                  const WinaWordmark(),
                ],
              ),
              sh(14),
              Container(height: 1, color: AppColor.divider),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ComingSoonBadge(),
                sh(18),
                Text(
                  'app.ia.section-bientot-disponible'.tr(),
                  textAlign: TextAlign.center,
                  style: AppThemeStyle.regularStyle(
                    14,
                    AppColor.secondaryLabels,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
