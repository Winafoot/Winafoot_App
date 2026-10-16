// ignore_for_file: use_build_context_synchronously

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:settings_kosmos/model/settings_config.dart';
import 'package:settings_kosmos/theme/settings_theme_data.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

class SubNodePage extends StatefulHookConsumerWidget {
  // final CelluleSection section;
  final String parentCelluleTag;

  final KosmosSettingsConfig? settingsConfig;

  /// Theme
  final String? themeName;
  final KosmosSettingsThemeData? theme;

  const SubNodePage({
    super.key,

    // required this.section,
    @PathParam("nodeTag") required this.parentCelluleTag,
    this.settingsConfig,

    /// Theme
    this.themeName,
    this.theme,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SubNodePageState();
}

class _SubNodePageState extends ConsumerState<SubNodePage> {
  late CelluleModel? celulle;
  late final KosmosSettingsConfig? config;

  @override
  void initState() {
    config = widget.settingsConfig ??
        (getAppModel().dependencies.packages["kosmos-settings"]
            as KosmosSettingsConfig?);
    assert(config != null, "kosmos-settings package is not found");
    celulle = null;

    for (final section in config!.settingsSection.call(ref)) {
      final tmp = _getCellule(section.cellules);
      if (tmp != null) {
        celulle = tmp;
      }
    }

    assert(celulle != null, "Cellule not found");

    if (celulle!.sectionChild != null) {
      celulle = celulle!.copyWith(
          sectionChild: _updateOnTapWithRedirect(celulle!.sectionChild!));
    }

    super.initState();
  }

  CelluleSection _updateOnTapWithRedirect(CelluleSection node) {
    for (var cellule in node.cellules) {
      if (cellule.type == CelluleType.action && cellule.sectionChild != null) {
        final index = node.cellules.indexOf(cellule);
        node.cellules[index] = cellule.copyWith(onTap: (_, __) async {
          if (await cellule.onTap?.call(context, ref) == false) {
            return null;
          }
          return await AutoRouter.of(context)
              .pushNamed<bool?>("app/profile/settings/${cellule.tag}");
        });
      }
      if (cellule.sectionChild != null) {
        _updateOnTapWithRedirect(cellule.sectionChild!);
      }
    }
    return node;
  }

  @override
  Widget build(BuildContext context) {
    final KosmosSettingsThemeData themeData = loadThemeData(
        null, "kosmos-settings", () => kDefaultSettingsTheme,
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    final SettingsCelluleThemeData settingsCelluleThemeData = loadThemeData(
        null, "settings_cellule", () => kDefaultCellule,
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    return Scaffold(
      backgroundColor: themeData.pageBackgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          children: [
            if (themeData.settingsSubNodeBackgroundPage != null)
              Positioned.fill(
                child: themeData.settingsSubNodeBackgroundPage!(context, ref),
              ),
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                primary: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).padding.top +
                            formatHeight(20)),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ButtonBack(
                          onTap: () => AutoRouter.of(context).canPop()
                              ? AutoRouter.of(context).pop()
                              : AutoRouter.of(context).navigateBack(),
                          color: themeData.actionIconColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: formatWidth(27.5)),
                        ),
                        sw(12),
                        Expanded(
                            child: Center(
                                child: Text(
                                    celulle!.sectionChild!.title
                                        .call(context, ref),
                                    style: themeData.subNodeTitleStyle ??
                                        themeData.sectionTitleStyle,
                                    textAlign: TextAlign.center))),
                        sw(12),
                        Opacity(
                            opacity: 0,
                            child: ButtonBack(
                              onTap: () {},
                              padding: EdgeInsets.symmetric(
                                  horizontal: formatWidth(27.5)),
                            )),
                      ],
                    ),
                    sh(themeData.subNodeTitleSpacing ?? 62),
                    ...celulle!.sectionChild!.cellules.map((cell) {
                      final isLast =
                          celulle!.sectionChild!.cellules.last == cell;
                      return Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: formatWidth(27.5)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SettingsCellule(model: cell),
                            if (!isLast)
                              SizedBox(
                                height: settingsCelluleThemeData
                                    .spaceBetweenCellules,
                              ),
                          ],
                        ),
                      );
                    }),
                    if (celulle?.sectionChild?.bottomBuilder != null)
                      Padding(
                        padding: EdgeInsets.only(top: formatHeight(21)),
                        child:
                            celulle!.sectionChild!.bottomBuilder!(context, ref),
                      ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom +
                            formatHeight(12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CelluleModel? _getCellule(List<CelluleModel> cellules) {
    for (var cellule in cellules) {
      if (cellule.tag == widget.parentCelluleTag) {
        return cellule;
      } else if (cellule.sectionChild != null) {
        final t = _getCellule(cellule.sectionChild!.cellules);
        if (t != null) return t;
      }
    }
    return null;
  }
}
