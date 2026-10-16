import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';

import 'theme/toggle_switch_theme.dart';

/// {@category Widget}
///
/// Affichage d'un Toggle Switch avec animation.
///
/// - [suggestionsCallback] vous permet d'ajouter votre propre liste de suggestions
/// - [itemBuilder] vous permet de mettre en forme le vos suggestions
/// - [onSuggestionSelected] vous permet de récuperer la suggestion. Par défaut, retourne la suggestion sous forme de string
///
/// Exemple:
///
/// ![toggle_switch](../../images/toggle_switch/toggle_switch.png)
///
/// ```dart
/// KosmosToggleSwitchDefault(
///   listItems: [
///     ItemModel(tag: "1", child: const Text("1"), onTap: () => printInDebug("1")),
///     const ItemModel(tag: "2", child: Text("2")),
///     const ItemModel(tag: "3", child: Text("3")),
///   ],
///   onChanged: (item) => printInDebug(item.tag),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par
/// défaut via le [KosmosToggleSwitchThemeData] : "toggle_switch".
///
class KosmosToggleSwitchDefault extends ConsumerStatefulWidget {
  final List<String> listItems;
  final void Function(String)? onChanged;

  final double? height;
  final double width;

  /// Theme
  final KosmosToggleSwitchThemeData? theme;
  final String? themeName;
  final Duration? animationDuration;
  final Curve? animationCurve;

  const KosmosToggleSwitchDefault({
    Key? key,
    required this.listItems,
    this.onChanged,
    this.width = double.infinity,
    this.height,

    /// Theme
    this.theme,
    this.animationCurve,
    this.animationDuration,
    this.themeName,
  }) : super(key: key);

  @override
  ConsumerState<KosmosToggleSwitchDefault> createState() =>
      KosmosToggleSwitchState();
}

class KosmosToggleSwitchState extends ConsumerState<KosmosToggleSwitchDefault> {
  late int indexSelected = 0;

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "toggle_switch",
      () => const KosmosToggleSwitchThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return SizedBox(
      width: widget.width,
      height: widget.height ?? formatHeight(45),
      child: LayoutBuilder(builder: (_, c) {
        final maxWidth = c.maxWidth;
        final itemWidth = maxWidth / widget.listItems.length;

        return Container(
          width: c.maxWidth,
          height: c.maxHeight,
          decoration: themeData.backBoxDecoration ??
              BoxDecoration(
                  color: DefaultColor.lowBlue,
                  borderRadius: BorderRadius.circular(10)),
          child: Stack(
            children: [
              AnimatedPositioned(
                top: 0,
                left: indexSelected * itemWidth,
                // ignore: sort_child_properties_last
                child: Container(
                  width: itemWidth,
                  height: c.maxHeight,
                  decoration: themeData.selectedDecoration ??
                      BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                ),
                duration: widget.animationDuration ??
                    themeData.animationDuration ??
                    kDefaultToggleDuration,
                curve: widget.animationCurve ??
                    themeData.animationCurve ??
                    kDefaultToggleCurves,
              ),
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ...widget.listItems.map((e) => InkWell(
                          onTap: () {
                            setState(() =>
                                indexSelected = widget.listItems.indexOf(e));
                            widget.onChanged?.call(e);
                          },
                          child: SizedBox(
                            width: itemWidth,
                            child: Center(
                                child: Text(
                              e,
                              style: e == widget.listItems[indexSelected]
                                  ? themeData.selectedStyle ??
                                      DefaultAppStyle.white(13)
                                  : themeData.unselectedStyle ??
                                      DefaultAppStyle.grey(13),
                            )
                                // Text(
                                //   e.tag,
                                //   style: e == widget.listItems[indexSelected] ? themeData.selectedStyle ?? DefaultAppStyle.white(13) : themeData.unselectedStyle ?? DefaultAppStyle.grey(13),
                                // ),
                                ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void updateSelectedIndex(int index) {
    setState(() => indexSelected = index);
  }
}
