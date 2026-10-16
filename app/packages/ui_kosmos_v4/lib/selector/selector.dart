import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/checkbox/checkbox.dart';
import 'package:ui_kosmos_v4/checkbox/stateless_checkbox.dart';

import 'theme/selector_theme.dart';

/// {@category Widget}
///
/// Un selector est un widget permettant de choisir des éléments.
/// Il est composé d'une [CustomCheckBox] et d'un texte ou d'un widget.
///
/// Il est possible d'avoir plusieurs types de checkbox :
/// - [CheckboxType.square] : Checkbox carrée
/// - [CheckboxType.circle] : Checkbox circulaire
///
/// Par défaut, la checkbox est de type [CheckboxType.square].
///
/// Exemple:
///
/// ![selector](../../images/selector/selector.png)
///
/// ```dart
/// const Selector(
///   sideText: "Side text: is checked",
///   isChecked: true,
/// ),
/// sh(20),
/// Selector(
///   type: CheckboxType.circle,
///   child: Container(
///     width: 50,
///     height: 50,
///     decoration: const BoxDecoration(
///         shape: BoxShape.circle, color: Colors.red),
///   ),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [SelectorThemeData] : "selector".
///
class Selector extends ConsumerStatefulWidget {
  final dynamic Function(bool isChecked)? onChanged;

  final double? spacing;

  final bool isChecked;
  final CheckboxType type;

  final Widget? child;
  final String? sideText;

  final SelectorThemeData? theme;
  final String? themeName;

  const Selector({
    super.key,
    this.onChanged,
    this.spacing,
    this.isChecked = false,
    this.type = CheckboxType.square,
    this.child,
    this.sideText,
    this.theme,
    this.themeName,
  }) : assert(child != null || sideText != null);

  @override
  ConsumerState<Selector> createState() => _Selector();
}

class _Selector extends ConsumerState<Selector> {
  late bool isChecked = widget.isChecked;

  final GlobalKey<CustomCheckBoxState> _checkBoxKey = GlobalKey();

  void changeState() {
    final r = widget.onChanged?.call(isChecked) ?? !isChecked;
    if (r is bool) {
      _checkBoxKey.currentState?.changeState(r);
      setState(() => isChecked = r);
    } else {
      _checkBoxKey.currentState?.changeState(!isChecked);
      setState(() => isChecked = !isChecked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "selector",
      () => const SelectorThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    return InkWell(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      highlightColor: Colors.transparent,
      onTap: changeState,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IgnorePointer(
            child: CustomCgvuCeckbox(
              key: _checkBoxKey,
              type: widget.type,
              isChecked: isChecked,
              theme: themeData.checkboxTheme,
              // onChanged: (_){
              //   changeState();

              // },
            ),
          ),
          if (widget.child != null || widget.sideText != null)
            sw(widget.spacing ?? 8),
          if (widget.child != null) widget.child!,
          if (widget.sideText != null)
            Expanded(
              child: Text(
                widget.sideText!,
                style: themeData.sideTextStyle ??
                    DefaultAppStyle.darkBlue(11, FontWeight.w400),
                maxLines: themeData.maxLine,
              ),
            ),
        ],
      ),
    );
  }
}
