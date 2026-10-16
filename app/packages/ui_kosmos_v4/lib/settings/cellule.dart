import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Widget}
///
/// Les [SettingsCellule] sont des cellules de paramètres. Elles sont majoritairement utilisées dans la page settings des Skeleton Kosmos.
///
/// Afin de configurer la cellule, il faut passer un [CelluleModel] en paramètre.
/// Vous pouvez configurer le type de settings via [CelluleModel.type] avec un enum [CelluleType].
/// - [CelluleType.action] : Une cellule qui possède une right_arrow et qui est cliquable (vous devez fournir un [CelluleModel.onTap] obligatoirement).
/// - [CelluleType.switcher] : Une cellule qui possède un [KosmosSwicth] et qui est cliquable (vous devez fournir un [CelluleModel.onSwitch] obligatoirement).
/// - [CelluleType.none] : Une cellule qui n'est pas cliquable.
///
/// Vous pouvez configurer le style de la Cellule via le thème [SettingsCelluleThemeData] avec la [themeName] "settings_cellule", vous pouvez aussi fournir votre propre [themeName].
///
/// Exemple:
///
/// ![settings_cellule_example](../images/cellule/settings_cellule_example.png)
///
/// ```Dart
/// SettingsCellule(
///   model: CelluleModel(
///     tag: "example",
///     tileBuilder: (_, __) => "Sécurité",
///     subTitleBuilder: (_, __) => "Mot de passe, Email, ..",
///     showNotifAlert: (_, __)=>true,
///     prefixSvgPath: "assets/svg/ic_security.svg",
///     type: CelluleType.switcher,
///     onSwitch: (_, __, newState) => newState,
///   ),
/// ),
/// ```
class SettingsCellule extends StatefulHookConsumerWidget {
  final CelluleModel model;

  /// Theme
  final String? themeName;
  final SettingsCelluleThemeData? theme;

  const SettingsCellule({
    super.key,
    required this.model,

    /// Theme
    this.themeName,
    this.theme,
  });

  @override
  ConsumerState<SettingsCellule> createState() => SettingsCelluleState();
}

class SettingsCelluleState extends ConsumerState<SettingsCellule> {
  bool state = false;
  bool mutex = true;

  @override
  void initState() {
    execAfterBuild(() => setState(() =>
        state = widget.model.initialSwitchValue?.call(context, ref) ?? false));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsCelluleThemeData themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "settings_cellule",
      () => kDefaultCellule,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius:
              themeData.decoration?.borderRadius ?? BorderRadius.zero),
      child: InkWell(
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        onTap: () async {
          if (mutex == false) return;
          if (widget.model.type == CelluleType.switcher) {
            if (widget.model.onSwitch != null) {
              updateState(await widget.model.onSwitch!(context, ref, !state));
            }
          } else if (widget.model.onTap != null) {
            mutex = false;
            widget.model.onTap!(context, ref);
            mutex = true;
          }
        },
        child: Container(
          padding: themeData.padding,
          decoration: themeData.decoration,
          // clipBehavior: Clip.antiAliasWithSaveLayer,
          constraints: themeData.celluleConstraints ??
              BoxConstraints(minHeight: formatHeight(62)),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.model.prefixBuilder != null ||
                  widget.model.prefixSvgPath != null) ...[
                if (widget.model.prefixSvgPath != null)
                  Container(
                    width: formatWidth(37),
                    height: formatWidth(37),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeData.prefixIconBackgroundColor,
                        gradient: themeData.prefixIconBackgroundGradient),
                    clipBehavior: Clip.antiAlias,
                    // ignore: deprecated_member_use
                    child: Center(
                        child: SvgPicture.asset(widget.model.prefixSvgPath!,
                            color: themeData.prefixIconColor)),
                  )
                else
                  Padding(
                    padding:
                        widget.model.prefixBuilderPadding ?? EdgeInsets.zero,
                    child: Container(
                      width: widget.model.prefixBuilderSize?.width ??
                          formatWidth(37),
                      height: widget.model.prefixBuilderSize?.height ??
                          formatWidth(37),
                      decoration: widget.model.prefixBuilderParentDecoration ??
                          const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                      clipBehavior: Clip.antiAlias,
                      child: widget.model.prefixBuilder!(context, ref),
                    ),
                  ),
                sw(16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      widget.model.tileBuilder(context, ref),
                      style: themeData.titleStyle,
                      maxLines: widget.model.subTitleBuilder != null ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.model.subTitleBuilder != null)
                      Text(widget.model.subTitleBuilder!.call(context, ref),
                          style: themeData.subtitleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (widget.model.showNotifAlert != null &&
                  widget.model.showNotifAlert!.call(context, ref)) ...[
                sw(4),
                Container(
                  width: formatWidth(8),
                  height: formatWidth(8),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: DefaultColor.error),
                ),
              ],
              _generateStateSuffix(context, ref, themeData),
            ],
          ),
        ),
      ),
    );
  }

  void updateState(bool newState) => setState(() => state = newState);

  Widget _generateStateSuffix(
      BuildContext context, WidgetRef ref, SettingsCelluleThemeData themeData) {
    if (widget.model.type == CelluleType.action) {
      return Row(
        children: [
          sw(8),
          Icon(Icons.arrow_forward_ios_rounded,
              color: themeData.actionIconColor, size: formatWidth(14))
        ],
      );
    } else if (widget.model.type == CelluleType.switcher) {
      return Row(
        children: [
          sw(8),
          IgnorePointer(
            child: KosmosSwicth(
              isActive: state,
              theme: themeData.switchTheme,
              onSwipe: (_) => setState(() async => state =
                  await widget.model.onSwitch!.call(context, ref, !state)),
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }
}
