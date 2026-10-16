import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/checkbox/checkbox.dart';
import 'package:ui_kosmos_v4/checkbox/theme/checkbox_theme.dart';

/// {@category Widget}
///
/// Une checkbox est un widget permettant de cocher ou décocher une case (valider).
///
/// Il est possible d'avoir plusieurs types de checkbox :
/// - [CheckboxType.square] : Checkbox carrée
/// - [CheckboxType.circle] : Checkbox circulaire
///
/// Par défaut, la checkbox est de type [CheckboxType.square].
///
/// Exemple:
///
/// ![checkbox](../../images/checkbox/checkbox.png)
///
/// ```dart
/// Row(
///   children: [
///     const CustomCgvuCeckbox(),
///     sw(20),
///     const CustomCgvuCeckbox(
///       isChecked: true,
///     ),
///   ],
/// ),
/// sh(20),
/// Row(
///   children: [
///     const CustomCgvuCeckbox(
///       type: CheckboxType.circle,
///     ),
///     sw(20),
///     const CustomCgvuCeckbox(
///       type: CheckboxType.circle,
///       isChecked: true,
///     ),
///   ],
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [CustomCheckBoxThemeData] : "checkbox".
///
///
///
class CustomCgvuCeckbox extends ConsumerWidget {
  final Function(bool isChecked)? onChanged;
  final bool isChecked;
  final double? size;
  final double? borderWidth;
  final double? borderRadius;
  final IconData? iconData;
  final CheckboxType type;

  /// Theme
  final CustomCheckBoxThemeData? theme;
  final Color? borderColor;
  final Color? checkedColor;
  final Color? uncheckedColor;
  final Color? iconColor;
  final BoxBorder? border;
  final Duration? animationDuration;
  final Curve? animationCurve;
  final String? themeName;
  const CustomCgvuCeckbox({
    Key? key,
    this.onChanged,
    this.isChecked = false,
    this.size,
    this.borderWidth,
    this.borderRadius,
    this.iconData,
    this.type = CheckboxType.square,

    /// Theme
    this.theme,
    this.borderColor,
    this.checkedColor,
    this.uncheckedColor,
    this.iconColor,
    this.border,
    this.animationDuration,
    this.animationCurve,
    this.themeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = loadThemeData(
      theme,
      themeName ?? "checkbox",
      () => const CustomCheckBoxThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return {
      CheckboxType.square: _buildDefault(context, themeData),
      CheckboxType.circle: _buildRounded(context, themeData),
    }[type]!;
  }

  Widget _buildDefault(
      BuildContext context, CustomCheckBoxThemeData themeData) {
    return InkWell(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      highlightColor: Colors.transparent,
      onTap: onChanged == null ? null : () => onChanged!(!isChecked),
      child: AnimatedContainer(
        duration: animationDuration ??
            themeData.animationDuration ??
            kDefaultCheckDuration,
        curve:
            animationCurve ?? themeData.animationCurve ?? kDefaultCheckCurves,
        decoration: BoxDecoration(
            gradient: isChecked ? themeData.gradient : null,
            color: themeData.gradient != null && isChecked
                ? null
                : isChecked
                    ? checkedColor ??
                        themeData.checkedColor ??
                        DefaultColor.darkBlue
                    : uncheckedColor ??
                        themeData.uncheckedColor ??
                        DefaultColor.lowGrey,
            borderRadius: BorderRadius.circular(borderRadius ?? r(5)),
            border: isChecked
                ? null
                : borderWidth == 0
                    ? null
                    : themeData.border ??
                        Border.all(
                          color: borderColor ??
                              themeData.borderColor ??
                              DefaultColor.grey,
                          width: borderWidth ?? formatWidth(0.5),
                        )),
        width: size ?? formatWidth(26),
        height: size ?? formatHeight(26),
        child: isChecked
            ? Center(
                child: Icon(
                  iconData ?? Icons.done_rounded,
                  color: iconColor ?? themeData.iconColor ?? DefaultColor.white,
                  size: (size ?? formatWidth(26)) - 8,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildRounded(
      BuildContext context, CustomCheckBoxThemeData themeData) {
    return InkWell(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      highlightColor: Colors.transparent,
      onTap: onChanged == null ? null : () => onChanged!(!isChecked),
      child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: uncheckedColor ??
                  themeData.uncheckedColor ??
                  DefaultColor.lowGrey,
              border: Border.all(
                color: checkedColor ??
                    themeData.checkedColor ??
                    DefaultColor.darkBlue,
                width: borderWidth ?? formatWidth(2),
              )),
          width: size ?? formatWidth(26),
          height: size ?? formatHeight(26),
          child: Center(
            child: AnimatedContainer(
              duration: animationDuration ??
                  themeData.animationDuration ??
                  kDefaultCheckDuration,
              curve: animationCurve ??
                  themeData.animationCurve ??
                  kDefaultCheckCurves,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked
                    ? checkedColor ??
                        themeData.checkedColor ??
                        DefaultColor.darkBlue
                    : uncheckedColor ??
                        themeData.uncheckedColor ??
                        DefaultColor.lowGrey,
              ),
              width: ((size ?? formatWidth(26)) - (4 * (borderWidth ?? 2))),
              height: ((size ?? formatHeight(26)) - (4 * (borderWidth ?? 2))),
            ),
          )),
    );
  }
}
