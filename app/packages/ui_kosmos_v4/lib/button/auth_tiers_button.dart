import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/button/button.dart';
import 'package:ui_kosmos_v4/button/theme/button_theme.dart';

/// {@category Widget}
/// {@category Button, CTA}
///
/// Bouton de connexion par un fournisseur tiers (Apple, Google…).
class AuthTiersButton extends ConsumerWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;

  final String? themeName;
  final KosmosButtonThemeData? theme;

  const AuthTiersButton({
    Key? key,
    required this.child,
    required this.onTap,
    this.padding,
    this.height,
    this.width,

    /// Theme
    this.theme,
    this.themeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = loadThemeData(
      theme,
      themeName ?? "auth_tiers_button",
      () => KosmosButtonThemeData(
        decoration: BoxDecoration(
          border: Border.all(
              color: DefaultColor.darkBlue.withOpacity(.25), width: .5),
          borderRadius: BorderRadius.circular(7),
          color: Colors.transparent,
        ),
      ),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    return Button(
        height: height,
        width: width,
        onTap: onTap,
        padding: padding,
        theme: themeData,
        child: Center(child: child));
  }
}
