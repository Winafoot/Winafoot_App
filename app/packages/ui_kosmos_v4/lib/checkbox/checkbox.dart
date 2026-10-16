import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/checkbox/theme/checkbox_theme.dart';

enum CheckboxType {
  square,
  circle,
}

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
///     const CustomCheckBox(),
///     sw(20),
///     const CustomCheckBox(
///       isChecked: true,
///     ),
///   ],
/// ),
/// sh(20),
/// Row(
///   children: [
///     const CustomCheckBox(
///       type: CheckboxType.circle,
///     ),
///     sw(20),
///     const CustomCheckBox(
///       type: CheckboxType.circle,
///       isChecked: true,
///     ),
///   ],
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [CustomCheckBoxThemeData] : "checkbox".
///
class CustomCheckBox extends ConsumerStatefulWidget {
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

  const CustomCheckBox({
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
  ConsumerState<CustomCheckBox> createState() => CustomCheckBoxState();
}

class CustomCheckBoxState extends ConsumerState<CustomCheckBox> {
  late bool isChecked = widget.isChecked;

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "checkbox",
      () => const CustomCheckBoxThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return {
      CheckboxType.square: _buildDefault(context, themeData),
      CheckboxType.circle: _buildRounded(context, themeData),
    }[widget.type]!;
  }

  Widget _buildDefault(
      BuildContext context, CustomCheckBoxThemeData themeData) {
    return InkWell(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      highlightColor: Colors.transparent,
      onTap: () {
        setState(() {
          isChecked = !isChecked;
        });
        widget.onChanged?.call(isChecked);
      },
      child: AnimatedContainer(
        duration: widget.animationDuration ??
            themeData.animationDuration ??
            kDefaultCheckDuration,
        curve: widget.animationCurve ??
            themeData.animationCurve ??
            kDefaultCheckCurves,
        decoration: BoxDecoration(
            color: themeData.gradient != null
                ? isChecked
                    ? null
                    : widget.uncheckedColor ??
                        themeData.uncheckedColor ??
                        DefaultColor.lowGrey
                : isChecked
                    ? widget.checkedColor ??
                        themeData.checkedColor ??
                        DefaultColor.darkBlue
                    : widget.uncheckedColor ??
                        themeData.uncheckedColor ??
                        DefaultColor.lowGrey,
            gradient: isChecked ? themeData.gradient : null,
            borderRadius: BorderRadius.circular(widget.borderRadius ?? r(5)),
            border: isChecked
                ? null
                : widget.borderWidth == 0
                    ? null
                    : themeData.border ??
                        Border.all(
                          color: widget.borderColor ??
                              themeData.borderColor ??
                              DefaultColor.grey,
                          width: widget.borderWidth ?? formatWidth(0.5),
                        )),
        width: widget.size ?? formatWidth(26),
        height: widget.size ?? formatHeight(26),
        child: isChecked
            ? Center(
                child: Icon(
                  widget.iconData ?? Icons.done_rounded,
                  color: widget.iconColor ??
                      themeData.iconColor ??
                      DefaultColor.white,
                  size: (widget.size ?? formatWidth(26)) - 8,
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
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      highlightColor: Colors.transparent,
      onTap: () {
        setState(() {
          isChecked = !isChecked;
        });
        widget.onChanged?.call(isChecked);
      },
      child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.uncheckedColor ??
                  themeData.uncheckedColor ??
                  DefaultColor.lowGrey,
              border: Border.all(
                color: widget.checkedColor ??
                    themeData.checkedColor ??
                    DefaultColor.darkBlue,
                width: widget.borderWidth ?? formatWidth(2),
              )),
          width: widget.size ?? formatWidth(26),
          height: widget.size ?? formatHeight(26),
          child: Center(
            child: AnimatedContainer(
              duration: widget.animationDuration ??
                  themeData.animationDuration ??
                  kDefaultCheckDuration,
              curve: widget.animationCurve ??
                  themeData.animationCurve ??
                  kDefaultCheckCurves,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked
                    ? widget.checkedColor ??
                        themeData.checkedColor ??
                        DefaultColor.darkBlue
                    : widget.uncheckedColor ??
                        themeData.uncheckedColor ??
                        DefaultColor.lowGrey,
              ),
              width: ((widget.size ?? formatWidth(26)) -
                  (4 * (widget.borderWidth ?? 2))),
              height: ((widget.size ?? formatHeight(26)) -
                  (4 * (widget.borderWidth ?? 2))),
            ),
          )),
    );
  }

  void changeState(bool newState) => setState(() => isChecked = newState);
}
