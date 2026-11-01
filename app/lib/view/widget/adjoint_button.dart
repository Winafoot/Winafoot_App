import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/page/mon_adjoint_screen.dart';

/// Bouton bien visible vers « Mon adjoint », sur les pages « Coup d'envoi » (choix de l'adversaire et page
/// finale avant le match). L'adjoint était auparavant accessible seulement depuis les paramètres.
class AdjointButton extends StatelessWidget {
  const AdjointButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.primaryColor,
      borderRadius: BorderRadius.circular(cR(999)),
      child: InkWell(
        borderRadius: BorderRadius.circular(cR(999)),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MonAdjointScreen(),
              ),
            ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhoneLayout ? 16 : cW(24),
            vertical: isPhoneLayout ? 8 : cH(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Iconsax.profile_2user, size: cIc(20), color: Colors.white),
              cSw(8),
              Text(
                'app.assistant.title'.tr(),
                style: AppThemeStyle.semiBStyle(cFs(17), Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
