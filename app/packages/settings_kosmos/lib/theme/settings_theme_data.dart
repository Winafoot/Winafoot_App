import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_theme_data.freezed.dart';

/// {@category Theme}
/// {@category KosmosSettings}
///
/// Thème Data contenant toutes les configurations des pages de settings.
/// Par défaut, les widgets du package utilisent le thème défini dans [kDefaultSettingsTheme].
///
/// Vous pouvez le configurer via "kosmos-settings".
///
@freezed
class KosmosSettingsThemeData with _$KosmosSettingsThemeData {
  const factory KosmosSettingsThemeData({
    final TextStyle? fullNameStyle,
    final TextStyle? emailStyle,
    final TextStyle? sectionTitleStyle,
    final Color? actionIconColor,
    final Color? pageBackgroundColor,
    final double? sectionSpacing,
    final TextStyle? selectedByTextStyle,
    final TextStyle? cliquableTextStyle,
    final TextStyle? dialogBoxNoTextStyle,
    final String? formFieldThemeName,
    final String? settingsButtonThemeName,
    final Widget Function(BuildContext, WidgetRef)? settingsBackgroundPage,
    final Widget Function(BuildContext, WidgetRef)?
        settingsSubNodeBackgroundPage,
    final Widget Function(BuildContext, WidgetRef)? changeEmailBackgroundPage,
    final Widget Function(BuildContext, WidgetRef)? changePhoneBackgroundPage,
    final Widget Function(BuildContext, WidgetRef)?
        changePasswordBackgroundPage,
    final bool? settingsBackgroundPageScrollable,

    /// Style du titre des sous-pages de paramètres (fallback :
    /// [sectionTitleStyle]).
    final TextStyle? subNodeTitleStyle,

    /// Espacement sous le header des sous-pages (fallback : 62).
    final double? subNodeTitleSpacing,
  }) = _KosmosSettingsThemeData;
}

final KosmosSettingsThemeData kDefaultSettingsTheme = KosmosSettingsThemeData(
  fullNameStyle: DefaultAppStyle.darkBlue(20),
  settingsBackgroundPageScrollable: false,
  emailStyle: DefaultAppStyle.simpleGrey(13, FontWeight.w500),
  sectionTitleStyle: DefaultAppStyle.darkBlue(16),
  actionIconColor: DefaultColor.darkBlue,
  sectionSpacing: formatHeight(23),
  selectedByTextStyle: DefaultAppStyle.darkBlue(13, FontWeight.w500),
  cliquableTextStyle: DefaultAppStyle.darkBlue(13, FontWeight.w500)
      .copyWith(decoration: TextDecoration.underline),
  dialogBoxNoTextStyle: DefaultAppStyle.darkBlue(13, FontWeight.w500),
);
