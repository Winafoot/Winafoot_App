import 'dart:async';
import 'dart:io';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class MainPage extends StatefulHookConsumerWidget {
  final RootStackRouter appRouter;
  final AppModel config;
  final FutureOr<void> Function(BuildContext, WidgetRef)? onInitWithContext;

  const MainPage({
    super.key,
    required this.appRouter,
    required this.config,
    this.onInitWithContext,
  });

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late final AppTheme appTheme;

  @override
  void initState() {
    if (GetIt.I.isRegistered<AppTheme>()) appTheme = GetIt.instance<AppTheme>();
    execAfterBuild(() async {
      if (context.mounted) {
        await widget.onInitWithContext?.call(context, ref);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider).isDarkMode;
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: MaterialApp.router(
        title: widget.config.appTitle,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: [
          ...context.localizationDelegates,
          ...widget.config.localization.delegates ?? [],
        ],
        routerDelegate: widget.appRouter.delegate(
          navigatorObservers: kIsWeb
              ? () => [AutoRouteObserver()]
              : AutoRouterDelegate.defaultNavigatorObserversBuilder,
        ),
        routeInformationParser: widget.appRouter.defaultRouteParser(),
        debugShowCheckedModeBanner: false,
        builder: EasyLoading.init(
          builder: (context, child) => kIsWeb
              ? child!
              : MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      accessibleNavigation: Platform.isIOS ? null : false,
                      textScaler: kIsWeb ? null : TextScaler.linear(1)),
                  child: child!),
        ),
        theme: appTheme.themeData,
        darkTheme: appTheme.themeDataDark,
        themeMode: () {
          switch (widget.config.forceThemeMode) {
            case ThemeModeType.system:
              return ThemeMode.system;
            case ThemeModeType.light:
              return ThemeMode.light;
            case ThemeModeType.dark:
              return ThemeMode.dark;
            case ThemeModeType.useProvider:
              return isDark ? ThemeMode.dark : ThemeMode.light;
          }
        }.call(),
      ),
    );
  }
}

bool isVersionGreaterThanOrEqual(String versionToCompare) {
  String fullVersion = Platform.version;

  // Regular expression to capture the version part (e.g., 2.14.1)
  RegExp versionPattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)');
  Match? currentVersionMatch = versionPattern.firstMatch(fullVersion);
  Match? compareVersionMatch = versionPattern.firstMatch(versionToCompare);

  if (currentVersionMatch != null && compareVersionMatch != null) {
    int currentMajor = int.parse(currentVersionMatch.group(1)!);
    int currentMinor = int.parse(currentVersionMatch.group(2)!);
    int currentPatch = int.parse(currentVersionMatch.group(3)!);

    int compareMajor = int.parse(compareVersionMatch.group(1)!);
    int compareMinor = int.parse(compareVersionMatch.group(2)!);
    int comparePatch = int.parse(compareVersionMatch.group(3)!);

    // Check if the current version is >= versionToCompare
    if ((currentMajor > compareMajor) ||
        (currentMajor == compareMajor && currentMinor > compareMinor) ||
        (currentMajor == compareMajor &&
            currentMinor == compareMinor &&
            currentPatch >= comparePatch)) {
      return true;
    }
  }

  return false;
}
