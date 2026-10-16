import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';

class AuthParentPage extends ConsumerStatefulWidget {
  const AuthParentPage({super.key});

  @override
  ConsumerState<AuthParentPage> createState() => _AuthParentPageState();
}

class _AuthParentPageState extends ConsumerState<AuthParentPage> {
  late ThemeData? lightTheme;
  late ThemeData? darkTheme;

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() {
    if (GetIt.instance.isRegistered<AppTheme>()) {
      lightTheme = GetIt.instance<AppTheme>().themeData;
      darkTheme = GetIt.instance<AppTheme>().themeDataDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(isDarkModeProvider).isDarkMode ? darkTheme?.scaffoldBackgroundColor: lightTheme?.scaffoldBackgroundColor ,
      body: AutoRouter());
  }
}
