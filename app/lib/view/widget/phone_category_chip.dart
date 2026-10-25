import 'package:flutter/material.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';

/// Pastille de catégorie du sous-flux « Gérer mon équipe » sur téléphone
/// (« Gardiens · 2 ») : pleine quand elle est choisie, 36 dp de haut.
class PhoneCategoryChip extends StatelessWidget {
  const PhoneCategoryChip({
    super.key,
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// Effectif affiché après le libellé ; `null` pour une simple pastille d'onglet.
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColor.primaryColor : AppColor.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColor.primaryColor : AppColor.divider,
            ),
          ),
          child: Text(
            count == null ? label : '$label · $count',
            maxLines: 1,
            style: AppThemeStyle.semiBStyle(
              cFs(16),
              selected ? AppColor.textLight : AppColor.primaryLabels,
            ),
          ),
        ),
      ),
    );
  }
}
