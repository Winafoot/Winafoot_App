import 'package:wina/config/permission_config.dart';
import 'package:wina/view/page/home_page.dart';
import 'package:wina/view/page/maintenance_page.dart';
import 'package:wina/view/page/register_page.dart';
import 'package:wina/view/page/update_required_page.dart';
import 'package:permissionrequest/permissons_package.dart';
import 'package:skeleton/skeleton.dart';
import 'package:wina/view/page/settings/settings_page.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(
      path: "app",
      page: LoggedUserAppCorePage,
      initial: true,
      guards: [IsConnectedGuard, PermissionSeenGuard],
      children: [
        AutoRoute(path: "home", page: HomePage, initial: true),

        /// profile route from Skeleton Package
        AutoRoute(
          path: "profile",
          page: ProfileParentPage,
          guards: [IsConnectedGuard],
          children: [
            AutoRoute(path: "settings", page: SettingsWebPage, initial: true),
            AutoRoute(path: "settings/:nodeTag", page: SubNodePage),

            /// Security update route
            AutoRoute(path: "security/password", page: ChangePasswordPage),
            AutoRoute(path: "security/phone-number", page: ChangePhonePage),
          ],
        ),
      ],
    ),

    /// Auth Route
    AutoRoute(
      path: "/auth",
      page: AuthParentPage,
      guards: [IsNotConnectedGuard],
      children: [
        AutoRoute(path: "login", page: LoginPage),
        AutoRoute(path: "login-with-phone", page: PhoneLoginPage),
        AutoRoute(path: "register", page: RegisterPage),
      ],
    ),

    /// App Legal Route
    AutoRoute(path: "legal-information/:info", page: LegalInformationPage),

    /// Maintenance (coupe-circuit budget — flag app_config/metadata.maintenance)
    AutoRoute(path: "/maintenance", page: MaintenancePage),

    /// Mise à jour exigée (app_config/metadata.minBuild), voir MaintenanceGate
    AutoRoute(path: "/update-required", page: UpdateRequiredPage),

    /// Permissions (package permissionrequest).
    /// Le chemin doit rester "permission" sans slash initial : le
    /// [PermissionSeenGuard] appelle `router.replaceNamed("permission")` et le
    /// matcher d'auto_route compare les segments tels quels.
    AutoRoute(path: "permission", page: PermissionPage),

    /// Utils route
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $AppRouter {
  $AppRouter();
}
