import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:permissionrequest/permissons_package.dart';

/// {@category Widget}
/// {@category Permission}
///
/// Permet d'afficher les permissions.
/// Par défaut cette page est à utiliser dans les skeletons,
/// elle permet de récupérer les configurations du
/// package via la key "permission-kosmos" et un objet [PermissionConfig].
/// Ainsi que le thème par défaut via la key "permission".
///
class PermissionPage extends StatefulHookConsumerWidget {
  final List<PermissionDataModel>? permissions;

  const PermissionPage({super.key, this.permissions});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PermissionPageState();
}

class _PermissionPageState extends ConsumerState<PermissionPage> {
  
  late final PermissionConfig? config = (getAppModel()
      .dependencies
      .packages["permission-kosmos"] as PermissionConfig?);

  late List<PermissionDataModel> _pages;

  final PageController _pageController = PageController();

  @override
  void initState() {
    assert((widget.permissions ?? config?.permissions) != null,
        "Vous devez fournir des pages pour l'onboarding");
    _pages = (widget.permissions ?? config?.permissions)!;
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  
    final PermissionThemeData themeData =
      loadThemeData(null, "permission", () => kDefaultPermissionTheme, isDark:ref.watch(isDarkModeProvider).isDarkMode);
    return Scaffold(
      backgroundColor: themeData.backgroundColor,
      body: PermissionWidget(
        permissions: _pages,
        pageController: _pageController,
        themeData: themeData,
        appLogoAsset: config?.appLogoAsset,
        config: config,
      ),
    );
  }
}
