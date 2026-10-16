import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/custom_back_button.dart';

/// Ossature commune des écrans de bilan (« Bilan collectif » / « Bilan
/// individuel ») : entête (retour + icône + titre + wordmark Wina + filet) puis
/// contenu. Reproduit l'entête du design tablette (1194 x 834).
class BilanScaffold extends StatelessWidget {
  const BilanScaffold({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const AppBackground(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  sh(16),
                  _Header(title: title),
                  sh(12),
                  Container(height: 1, color: AppColor.divider),
                  sh(16),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CustomBackButton(onTap: () => Navigator.of(context).maybePop()),
        sw(14),
        Container(width: 1, height: formatHeight(28), color: AppColor.divider),
        sw(14),
        SizedBox(
          width: sp(34),
          height: sp(34),
          child: Icon(
            Iconsax.chart_21,
            size: sp(34),
            color: AppColor.primaryColor,
          ),
        ),
        sw(12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(28, AppColor.primaryLabels),
          ),
        ),
        sw(12),
        const WinaWordmark(size: 30),
      ],
    );
  }
}

/// Bouton « Exporter en PDF » (icône + libellé) — déclenche la feuille de
/// partage / impression native.
class BilanExportButton extends StatelessWidget {
  const BilanExportButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r(8)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: formatWidth(6),
          vertical: formatHeight(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Iconsax.import_3, size: sp(20), color: AppColor.primaryLabels),
            sw(8),
            Text(
              'app.bilan-scaffold.exporter-pdf'.tr(),
              style: AppThemeStyle.semiBStyle(14, AppColor.primaryLabels),
            ),
          ],
        ),
      ),
    );
  }
}
