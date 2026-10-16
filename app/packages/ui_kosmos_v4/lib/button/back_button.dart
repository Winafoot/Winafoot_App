import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/button/theme/button_theme.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
/// {@category Button, CTA}
///
/// Un simple bouton pour retourner à la page précédente.
/// Par défaut, utilise le système de [AutoRouter.navigateBack] pour retourner à la page précédente.
/// Mais vous pouvez donner votre propre fonction de retour en passant par le paramètre [onTap].
///
/// Exemple:
/// ![button_example_back](../../images/button/back_button.png)
///
/// ```dart
/// ButtonBack(
///   color: Colors.red,
///   onTap: () {
///     printDebug("YOUPI");
///     AutoRouter.of(context).navigateBack();
///   },
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [KosmosButtonThemeData] : "back_button".
///
class ButtonBack extends ConsumerWidget {
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? size;
  final Color? color;
  final Widget? customIcon;
  final String? themeName;
  final KosmosButtonThemeData? theme;

  const ButtonBack({
    super.key,
    this.onTap,
    this.padding,
    this.color,
    this.size,
    this.customIcon,

    /// Theme
    this.theme,
    this.themeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = loadThemeData(
      theme,
      themeName ?? "back_button",
      () => const KosmosButtonThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        highlightColor: Colors.transparent,
        onTap: () => onTap != null
            ? onTap!.call()
            : AutoRouter.of(context).navigateBack(),
        child: Padding(
          padding: padding ?? themeData.padding ?? EdgeInsets.zero,
          child: Container(
            width: themeData.width,
            height: themeData.height,
            decoration: themeData.decoration,
            child: customIcon ??
                themeData.backButtonIcon ??
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: color ?? themeData.iconColor ?? DefaultColor.darkBlue,
                  size: size ?? themeData.iconSize ?? formatWidth(26),
                ),
          ),
        ),
      ),
    );
  }
}
