import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
      width: formatWidth(240),
      padding: EdgeInsets.symmetric(horizontal: formatWidth(14)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(999)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Iconsax.search_normal_1_copy,
            size: sp(16),
            color: AppColor.secondaryLabels,
          ),
          sw(8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: AppThemeStyle.regularStyle(13, AppColor.primaryLabels),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AppThemeStyle.regularStyle(
                  13,
                  AppColor.secondaryLabels,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkResponse(
              onTap: onClear,
              radius: sp(18),
              child: Icon(
                Iconsax.close_circle,
                size: sp(16),
                color: AppColor.secondaryLabels,
              ),
            ),
        ],
      ),
    );
  }
}
