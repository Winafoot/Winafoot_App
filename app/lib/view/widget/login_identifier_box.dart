import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/app_notif.dart';

/// Identifiant de connexion d'un compte créé par le coach (équipe liée, adjoint) : mis en avant dans un encadré,
/// avec une explication et un bouton « Copier », pour que le coach comprenne qu'il le communique à son équipe et
/// que celle-ci le saisit à la place de l'adresse e-mail sur l'écran de connexion.
class LoginIdentifierBox extends StatelessWidget {
  const LoginIdentifierBox({
    super.key,
    required this.identifier,
    required this.help,
  });

  final String identifier;

  /// Phrase d'explication affichée sous l'identifiant.
  final String help;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColor.chipBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'app.teams.login-id-label'.tr().toUpperCase(),
            style: AppThemeStyle.semiBStyle(11, AppColor.primaryColor),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: SelectableText(
                  identifier,
                  maxLines: 1,
                  style: AppThemeStyle.semiBStyle(20, AppColor.primaryLabels),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: identifier));
                  if (!context.mounted) return;
                  showAppNotif(context, title: 'app.teams.login-id-copied'.tr());
                },
                icon: Icon(
                  Iconsax.copy,
                  size: 18,
                  color: AppColor.primaryColor,
                ),
                label: Text(
                  'app.teams.login-id-copy'.tr(),
                  style: AppThemeStyle.semiBStyle(14, AppColor.primaryColor),
                ),
              ),
            ],
          ),
          Text(
            help,
            style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
          ),
        ],
      ),
    );
  }
}
