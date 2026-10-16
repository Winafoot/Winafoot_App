import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/_deprecated/settings_cellule/theme.dart';

class TmpSettingsCellule extends ConsumerWidget {
  final String? title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? activeTitleStyle;
  final TextStyle? activeSubtitleStyle;
  final VoidCallback onClick;
  final Widget? switchNotif;
  final bool Function(WidgetRef)? haveNotif;

  final ImageProvider? image;

  final Widget? icon;
  final Widget? activeIcon;
  final Color? iconColor;
  final Color? activeIconColor;

  final Color? backgroundColor;
  final Color? iconBackgroundColor;
  final Color? activeBackgroundColor;
  final Color? activeIconBackgroundColor;
  final Gradient? backgroundGradient;
  final Gradient? iconBackgroundGradient;
  final Gradient? activeBackgroundGradient;
  final Gradient? activeIconBackgroundGradient;
  final Color? overlayColor;
  final double? radius;

  final String? themeName;
  final TmpSettingsCelluleThemeData? theme;

  final bool isActive;

  const TmpSettingsCellule({
    this.radius,
    this.switchNotif,
    this.title,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    required this.onClick,
    this.iconColor,
    this.backgroundColor,
    this.iconBackgroundColor,
    this.activeIconColor,
    this.activeBackgroundColor,
    this.activeIconBackgroundColor,
    this.backgroundGradient,
    this.iconBackgroundGradient,
    this.activeBackgroundGradient,
    this.activeIconBackgroundGradient,
    this.activeTitleStyle,
    this.activeSubtitleStyle,
    this.image,
    this.icon,
    this.activeIcon,
    this.overlayColor,
    this.theme,
    this.themeName,
    this.isActive = false,
    this.haveNotif,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = loadThemeData(
        theme,
        themeName ?? "settings_cellule",
        () => const TmpSettingsCelluleThemeData(
              activeBackgroundGradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
              activeIconBackgroundColor: Colors.white,
              iconBackgroundGradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
            ))!;

    return InkWell(
      onTap: onClick,
      child: Container(
        constraints: themeData.constraints ??
            BoxConstraints(
              minHeight: 60,
              maxWidth: double.infinity,
              minWidth: formatWidth(293),
            ),
        decoration: BoxDecoration(
          gradient: isActive
              ? (activeBackgroundColor == null && themeData.activeBackgroundColor == null
                  ? activeBackgroundGradient ?? themeData.activeBackgroundGradient
                  : null)
              : (backgroundColor == null && themeData.backgroundColor == null ? backgroundGradient ?? themeData.backgroundGradient : null),
          color: isActive
              ? activeBackgroundColor ??
                  themeData.activeBackgroundColor ??
                  (activeBackgroundGradient == null && themeData.activeBackgroundGradient == null ? const Color(0xFF02132B).withOpacity(0.03) : null)
              : backgroundColor ??
                  themeData.backgroundColor ??
                  (backgroundGradient == null && themeData.backgroundGradient == null ? const Color(0xFF02132B).withOpacity(0.03) : null),
          borderRadius: BorderRadius.circular((radius ?? 7)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: themeData.horizontalPadding ?? 10, vertical: themeData.verticalPadding ?? 0),
              child: (icon != null || image != null)
                  ? Container(
                      height: formatHeight(themeData.imageHeight ?? 37),
                      width: formatWidth(themeData.imageWidth ?? 37),
                      clipBehavior: Clip.hardEdge,
                      decoration: image != null
                          ? BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: image!, fit: BoxFit.cover))
                          : BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isActive
                                  ? (activeIconBackgroundColor == null && themeData.activeIconBackgroundColor == null
                                      ? activeIconBackgroundGradient ?? themeData.activeIconBackgroundGradient
                                      : null)
                                  : (iconBackgroundColor == null && themeData.iconBackgroundColor == null
                                      ? iconBackgroundGradient ?? themeData.iconBackgroundGradient
                                      : null),
                              color: isActive
                                  ? activeIconBackgroundColor ??
                                      themeData.activeIconBackgroundColor ??
                                      (activeIconBackgroundGradient == null && themeData.activeIconBackgroundGradient == null
                                          ? const Color(0xFF02132B).withOpacity(0.03)
                                          : null)
                                  : iconBackgroundColor ??
                                      themeData.iconBackgroundColor ??
                                      (iconBackgroundGradient == null && themeData.iconBackgroundGradient == null
                                          ? const Color(0xFF02132B).withOpacity(0.03)
                                          : null)),
                      child: isActive ? activeIcon ?? icon : icon,
                    )
                  : const SizedBox(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title ?? 'Titre',
                          style: isActive
                              ? activeTitleStyle ??
                                  themeData.activeTitleStyle ??
                                  const TextStyle(color: Color(0xFF02132B), fontSize: 13, fontWeight: FontWeight.w500)
                              : titleStyle ?? themeData.titleStyle ?? const TextStyle(color: Color(0xFF02132B), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  subtitle != null
                      ? Text(
                          subtitle!,
                          style: isActive
                              ? activeSubtitleStyle ??
                                  themeData.activeSubtitleStyle ??
                                  TextStyle(color: const Color(0xFF02132B).withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w500)
                              : subtitleStyle ??
                                  themeData.subtitleStyle ??
                                  TextStyle(color: const Color(0xFF02132B).withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w500),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
            if (haveNotif?.call(ref) ?? false) ...[
              sw(7.5),
              Container(height: formatWidth(7), width: formatWidth(7), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE35050))),
              sw(7.5),
            ],
            switchNotif == null
                ? execInCaseOfPlatfom(
                    () => getResponsiveValue(
                      context,
                      defaultValue: const SizedBox(),
                      tablet: Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).iconTheme.color ?? const Color(0xFFA4AAB2),
                        size: (themeData.imageWidth ?? 37) - 17,
                      ),
                    ),
                    () => Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).iconTheme.color ?? const Color(0xFFA4AAB2),
                      size: (themeData.imageWidth ?? 37) - 17,
                    ),
                  )
                : switchNotif!,
            sw(14),
          ],
        ),
      ),
    );
  }
}

Color darkenOrLighten(Color color) {
  double amount = color.computeLuminance();
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  if (amount < 0.8) {
    final hslLight = hsl.withLightness(((hsl.lightness + amount) / 3).clamp(0.3, 1.0));

    return hslLight.toColor();
  } else {
    final hslDark = hsl.withLightness((hsl.lightness - amount / 4).clamp(0.0, 1.0));

    return hslDark.toColor();
  }
}
