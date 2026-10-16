import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:skeleton/skeleton.dart';

class ProfileParentPage extends ConsumerWidget {
  const ProfileParentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final KosmosSettingsThemeData themeData = loadThemeData(
      null,
      "kosmos-settings",
      () => kDefaultSettingsTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Container(
      color: themeData.pageBackgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: const AutoRouter(),
    );
  }
}
