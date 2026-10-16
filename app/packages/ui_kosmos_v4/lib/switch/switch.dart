import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/switch/theme/switch_theme.dart';

/// {@category Widget}
///
/// Le [KosmosSwicth] est un switch qui permet de switcher entre deux états (fonctionne comme le Switch du package Cupertino).
///
/// Vous devez fournir un [onSwipe] pour ctahcer le switch entre les deux états.
/// Vous devez fournir un [isActive] pour définir l'état du switch.
///
/// Exemple:
///
/// ![switch_example](../images/switch/switch_example.png)
///
/// ```Dart
/// KosmosSwicth(
///   isActive: state,
///   onSwipe: (newState) => setState(() => state = newState),
/// ),
/// ```
///
/// Vous pouvez le configurer via le thème [KosmosSwitchThemeData] avec la [themeName] "switch", vous pouvez aussi fournir votre propre [themeName].
class KosmosSwicth extends ConsumerStatefulWidget {
  final double width;
  final double height;

  final void Function(bool)? onSwipe;
  final bool isActive;

  /// Theme
  final String? themeName;
  final KosmosSwitchThemeData? theme;

  const KosmosSwicth({
    super.key,
    this.width = 48,
    this.height = 30,
    this.onSwipe,
    this.isActive = false,

    /// Theme
    this.themeName,
    this.theme,
  });

  @override
  ConsumerState<KosmosSwicth> createState() => _KosmosSwicthState();
}

class _KosmosSwicthState extends ConsumerState<KosmosSwicth> {
  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "switch",
      () => kDefaultSwitch,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return InkWell(
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      onTap: () {
        if (widget.onSwipe != null) {
          widget.onSwipe!(!widget.isActive);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: widget.isActive ? themeData.activeGradient : null,
          borderRadius: BorderRadius.circular(widget.height / 2),
          color: widget.isActive
              ? themeData.activeGradient != null
                  ? null
                  : themeData.activeTrackColor
              : themeData.trackColor,
        ),
        child: Stack(
          children: [
            const SizedBox(width: double.infinity, height: double.infinity),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: widget.isActive
                  ? (widget.width -
                      widget.height +
                      ((themeData.padding ?? 2) / 2))
                  : ((themeData.padding ?? 2) / 2),
              top: ((themeData.padding ?? 2) / 2),
              child: Container(
                width: widget.height - (themeData.padding ?? 4),
                height: widget.height - (themeData.padding ?? 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      (widget.height - (themeData.padding ?? 4)) / 2),
                  color: themeData.thumbColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
