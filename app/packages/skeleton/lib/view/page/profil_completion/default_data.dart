import 'package:flutter/material.dart';
import 'package:skeleton/skeleton.dart';
import 'package:skeleton/theme/profil_completion/profil_completion_theme.dart';
import 'package:skeleton/view/widget/parent/auth_parent.dart';

class CompleteProfilDefaultDataPage extends ConsumerStatefulWidget {
  const CompleteProfilDefaultDataPage({super.key});

  @override
  ConsumerState<CompleteProfilDefaultDataPage> createState() =>
      _CompleteProfilDefaultDataPageState();
}

class _CompleteProfilDefaultDataPageState
    extends ConsumerState<CompleteProfilDefaultDataPage> {
  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData<ProfilCompletionThemeData>(
      null,
      "profil_completion",
      () => kDefaultProfilCompletionThemeData,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    return Scaffold(
      body: PopScope(
        canPop: true,
        child: AuthParent(
          showBackButton: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  "package.complete-profil.title".tr(),
                  style: themeData.titleTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
