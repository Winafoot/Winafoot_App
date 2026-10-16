import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/_deprecated/checkbox/theme.dart';

abstract class CustomCheckbox extends StatelessWidget {
  const factory CustomCheckbox.square({
    final bool isChecked,
    final VoidCallback? onTap,
    final double? size,
    final double? iconSize,
    final double? borderWidth,
    final double? borderRadius,
    final Color? selectedColor,
    final Color? selectedIconColor,
    final Color? borderColor,
    final IconData? iconData,
    final String? themeName,
    final CustomCheckBoxThemeData? theme,
  }) = _Square;

  const factory CustomCheckbox.circle({
    final bool isChecked,
    final VoidCallback? onTap,
    final double? size,
    final double? borderWidth,
    final double? iconSize,
    final Color? selectedColor,
    final Color? selectedIconColor,
    final Color? borderColor,
    final IconData? iconData,
    final String? themeName,
    final CustomCheckBoxThemeData? theme,
  }) = _Circle;
}

class _Square extends StatelessWidget implements CustomCheckbox {
  final bool isChecked;
  final VoidCallback? onTap;
  final double? size;
  final double? borderWidth;
  final double? borderRadius;
  final double? iconSize;
  final Color? selectedColor;
  final Color? selectedIconColor;
  final Color? borderColor;
  final IconData? iconData;
  final CustomCheckBoxThemeData? theme;
  final String? themeName;

  const _Square({
    this.isChecked = false,
    this.size,
    this.iconSize,
    this.selectedColor,
    this.selectedIconColor,
    this.onTap,
    this.borderWidth,
    this.iconData,
    this.borderRadius,
    this.borderColor,
    this.theme,
    this.themeName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(theme, themeName ?? "checkbox_square",
        () => const CustomCheckBoxThemeData());

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            themeData.animationDuration ?? const Duration(milliseconds: 100),
        curve: Curves.easeInOutCirc,
        decoration: BoxDecoration(
            color: isChecked
                ? selectedColor ??
                    themeData.selectedColor ??
                    const Color(0xFF02132B)
                : themeData.defaultColor ?? const Color(0xFFEFF0F1),
            borderRadius: BorderRadius.circular(
                (borderRadius ?? themeData.borderRadius ?? 5)),
            border: isChecked
                ? null
                : borderWidth == 0
                    ? null
                    : themeData.border ??
                        Border.all(
                          color: borderColor ?? const Color(0xFF78808D),
                          width: borderWidth ?? (0.5),
                        )),
        width: size ?? 26,
        height: size ?? 26,
        child: isChecked
            ? Icon(
                iconData ?? Icons.done,
                color: selectedIconColor ??
                    themeData.selectedIconColor ??
                    Colors.white,
                size: iconSize ?? 12,
              )
            : null,
      ),
    );
  }
}

class _Circle extends StatelessWidget implements CustomCheckbox {
  final bool isChecked;
  final VoidCallback? onTap;
  final double? size;
  final double? borderWidth;
  final double? iconSize;
  final Color? selectedColor;
  final Color? selectedIconColor;
  final Color? borderColor;
  final IconData? iconData;
  final CustomCheckBoxThemeData? theme;
  final String? themeName;

  const _Circle({
    this.isChecked = false,
    this.size,
    this.iconSize,
    this.selectedColor,
    this.selectedIconColor,
    this.onTap,
    this.borderWidth,
    this.iconData,
    this.borderColor,
    this.theme,
    this.themeName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(theme, themeName ?? "checkbox_circle",
        () => const CustomCheckBoxThemeData());

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            themeData.animationDuration ?? const Duration(milliseconds: 100),
        curve: Curves.easeInOutCirc,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: borderWidth == 0
                ? null
                : themeData.border ??
                    Border.all(
                      color: borderColor ?? const Color(0xFF02132B),
                      width: borderWidth ?? 1.5,
                    )),
        width: size ?? 22,
        height: size ?? 22,
        child: isChecked
            ? Padding(
                padding: const EdgeInsets.all(1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedColor ??
                        themeData.selectedColor ??
                        const Color(0xFF02132B),
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
