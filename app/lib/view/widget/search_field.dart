import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';

/// Barre de recherche en pilule (loupe, saisie, croix d'effacement), au style de
/// celle de « Test équipe ».
///
/// Pas d'autofocus : la barre est affichée en permanence dans l'entête d'un
/// onglet, un focus automatique ferait remonter le clavier à chaque bascule.
/// Valider la recherche referme le clavier. La temporisation de la saisie est à
/// la charge de l'appelant ([onChanged] est appelé à chaque frappe).
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cW(240),
      padding: EdgeInsets.symmetric(horizontal: cW(14)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(999)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Iconsax.search_normal_1_copy,
            size: cIc(16),
            color: AppColor.secondaryLabels,
          ),
          cSw(8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: AppThemeStyle.regularStyle(
                cFs(13),
                AppColor.primaryLabels,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AppThemeStyle.regularStyle(
                  cFs(13),
                  AppColor.secondaryLabels,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkResponse(
              onTap: onClear,
              radius: cIc(18),
              child: Icon(
                Iconsax.close_circle,
                size: cIc(16),
                color: AppColor.secondaryLabels,
              ),
            ),
        ],
      ),
    );
  }
}
