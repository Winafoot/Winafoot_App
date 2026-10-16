// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i7;
import 'package:flutter/material.dart' as _i8;
import 'package:flutter/widgets.dart' as _i10;
import 'package:permissionrequest/permissons_package.dart' as _i4;
import 'package:skeleton/skeleton.dart' as _i1;

import '../config/permission_config.dart' as _i9;
import '../view/page/home_page.dart' as _i5;
import '../view/page/maintenance_page.dart' as _i2;
import '../view/page/settings/settings_page.dart' as _i6;
import '../view/page/update_required_page.dart' as _i3;

class AppRouter extends _i7.RootStackRouter {
  AppRouter({
    _i8.GlobalKey<_i8.NavigatorState>? navigatorKey,
    required this.isConnectedGuard,
    required this.permissionSeenGuard,
    required this.isNotConnectedGuard,
  }) : super(navigatorKey);

  final _i1.IsConnectedGuard isConnectedGuard;

  final _i9.PermissionSeenGuard permissionSeenGuard;

  final _i1.IsNotConnectedGuard isNotConnectedGuard;

  @override
  final Map<String, _i7.PageFactory> pagesMap = {
    LoggedUserAppCoreRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.LoggedUserAppCorePage(),
      );
    },
    AuthParentRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.AuthParentPage(),
      );
    },
    LegalInformationRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<LegalInformationRouteArgs>(
          orElse: () =>
              LegalInformationRouteArgs(info: pathParams.getString('info')));
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i1.LegalInformationPage(
          key: args.key,
          info: args.info,
        ),
      );
    },
    MaintenanceRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i2.MaintenancePage(),
      );
    },
    UpdateRequiredRoute.name: (routeData) {
      final args = routeData.argsAs<UpdateRequiredRouteArgs>(
          orElse: () => const UpdateRequiredRouteArgs());
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i3.UpdateRequiredPage(
          key: args.key,
          storeUrl: args.storeUrl,
        ),
      );
    },
    PermissionRoute.name: (routeData) {
      final args = routeData.argsAs<PermissionRouteArgs>(
          orElse: () => const PermissionRouteArgs());
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i4.PermissionPage(
          key: args.key,
          permissions: args.permissions,
        ),
      );
    },
    HomeRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i5.HomePage(),
      );
    },
    ProfileParentRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.ProfileParentPage(),
      );
    },
    SettingsWebRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i6.SettingsWebPage(),
      );
    },
    SubNodeRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<SubNodeRouteArgs>(
          orElse: () => SubNodeRouteArgs(
              parentCelluleTag: pathParams.getString('nodeTag')));
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i1.SubNodePage(
          key: args.key,
          parentCelluleTag: args.parentCelluleTag,
          settingsConfig: args.settingsConfig,
          themeName: args.themeName,
          theme: args.theme,
        ),
      );
    },
    ChangePasswordRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.ChangePasswordPage(),
      );
    },
    ChangePhoneRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.ChangePhonePage(),
      );
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i1.LoginPage(
          key: args.key,
          onLoginSuccess: args.onLoginSuccess,
        ),
      );
    },
    PhoneLoginRoute.name: (routeData) {
      return _i7.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.PhoneLoginPage(),
      );
    },
  };

  @override
  List<_i7.RouteConfig> get routes => [
        _i7.RouteConfig(
          '/#redirect',
          path: '/',
          redirectTo: 'app',
          fullMatch: true,
        ),
        _i7.RouteConfig(
          LoggedUserAppCoreRoute.name,
          path: 'app',
          guards: [
            isConnectedGuard,
            permissionSeenGuard,
          ],
          children: [
            _i7.RouteConfig(
              '#redirect',
              path: '',
              parent: LoggedUserAppCoreRoute.name,
              redirectTo: 'home',
              fullMatch: true,
            ),
            _i7.RouteConfig(
              HomeRoute.name,
              path: 'home',
              parent: LoggedUserAppCoreRoute.name,
            ),
            _i7.RouteConfig(
              ProfileParentRoute.name,
              path: 'profile',
              parent: LoggedUserAppCoreRoute.name,
              guards: [isConnectedGuard],
              children: [
                _i7.RouteConfig(
                  '#redirect',
                  path: '',
                  parent: ProfileParentRoute.name,
                  redirectTo: 'settings',
                  fullMatch: true,
                ),
                _i7.RouteConfig(
                  SettingsWebRoute.name,
                  path: 'settings',
                  parent: ProfileParentRoute.name,
                ),
                _i7.RouteConfig(
                  SubNodeRoute.name,
                  path: 'settings/:nodeTag',
                  parent: ProfileParentRoute.name,
                ),
                _i7.RouteConfig(
                  ChangePasswordRoute.name,
                  path: 'security/password',
                  parent: ProfileParentRoute.name,
                ),
                _i7.RouteConfig(
                  ChangePhoneRoute.name,
                  path: 'security/phone-number',
                  parent: ProfileParentRoute.name,
                ),
              ],
            ),
          ],
        ),
        _i7.RouteConfig(
          AuthParentRoute.name,
          path: '/auth',
          guards: [isNotConnectedGuard],
          children: [
            _i7.RouteConfig(
              LoginRoute.name,
              path: 'login',
              parent: AuthParentRoute.name,
            ),
            _i7.RouteConfig(
              PhoneLoginRoute.name,
              path: 'login-with-phone',
              parent: AuthParentRoute.name,
            ),
          ],
        ),
        _i7.RouteConfig(
          LegalInformationRoute.name,
          path: 'legal-information/:info',
        ),
        _i7.RouteConfig(
          MaintenanceRoute.name,
          path: '/maintenance',
        ),
        _i7.RouteConfig(
          UpdateRequiredRoute.name,
          path: '/update-required',
        ),
        _i7.RouteConfig(
          PermissionRoute.name,
          path: 'permission',
        ),
        _i7.RouteConfig(
          '*#redirect',
          path: '*',
          redirectTo: '/',
          fullMatch: true,
        ),
      ];
}

/// generated route for
/// [_i1.LoggedUserAppCorePage]
class LoggedUserAppCoreRoute extends _i7.PageRouteInfo<void> {
  const LoggedUserAppCoreRoute({List<_i7.PageRouteInfo>? children})
      : super(
          LoggedUserAppCoreRoute.name,
          path: 'app',
          initialChildren: children,
        );

  static const String name = 'LoggedUserAppCoreRoute';
}

/// generated route for
/// [_i1.AuthParentPage]
class AuthParentRoute extends _i7.PageRouteInfo<void> {
  const AuthParentRoute({List<_i7.PageRouteInfo>? children})
      : super(
          AuthParentRoute.name,
          path: '/auth',
          initialChildren: children,
        );

  static const String name = 'AuthParentRoute';
}

/// generated route for
/// [_i1.LegalInformationPage]
class LegalInformationRoute
    extends _i7.PageRouteInfo<LegalInformationRouteArgs> {
  LegalInformationRoute({
    _i10.Key? key,
    required String info,
  }) : super(
          LegalInformationRoute.name,
          path: 'legal-information/:info',
          args: LegalInformationRouteArgs(
            key: key,
            info: info,
          ),
          rawPathParams: {'info': info},
        );

  static const String name = 'LegalInformationRoute';
}

class LegalInformationRouteArgs {
  const LegalInformationRouteArgs({
    this.key,
    required this.info,
  });

  final _i10.Key? key;

  final String info;

  @override
  String toString() {
    return 'LegalInformationRouteArgs{key: $key, info: $info}';
  }
}

/// generated route for
/// [_i2.MaintenancePage]
class MaintenanceRoute extends _i7.PageRouteInfo<void> {
  const MaintenanceRoute()
      : super(
          MaintenanceRoute.name,
          path: '/maintenance',
        );

  static const String name = 'MaintenanceRoute';
}

/// generated route for
/// [_i3.UpdateRequiredPage]
class UpdateRequiredRoute extends _i7.PageRouteInfo<UpdateRequiredRouteArgs> {
  UpdateRequiredRoute({
    _i10.Key? key,
    String? storeUrl,
  }) : super(
          UpdateRequiredRoute.name,
          path: '/update-required',
          args: UpdateRequiredRouteArgs(
            key: key,
            storeUrl: storeUrl,
          ),
        );

  static const String name = 'UpdateRequiredRoute';
}

class UpdateRequiredRouteArgs {
  const UpdateRequiredRouteArgs({
    this.key,
    this.storeUrl,
  });

  final _i10.Key? key;

  final String? storeUrl;

  @override
  String toString() {
    return 'UpdateRequiredRouteArgs{key: $key, storeUrl: $storeUrl}';
  }
}

/// generated route for
/// [_i4.PermissionPage]
class PermissionRoute extends _i7.PageRouteInfo<PermissionRouteArgs> {
  PermissionRoute({
    _i10.Key? key,
    List<_i4.PermissionDataModel>? permissions,
  }) : super(
          PermissionRoute.name,
          path: 'permission',
          args: PermissionRouteArgs(
            key: key,
            permissions: permissions,
          ),
        );

  static const String name = 'PermissionRoute';
}

class PermissionRouteArgs {
  const PermissionRouteArgs({
    this.key,
    this.permissions,
  });

  final _i10.Key? key;

  final List<_i4.PermissionDataModel>? permissions;

  @override
  String toString() {
    return 'PermissionRouteArgs{key: $key, permissions: $permissions}';
  }
}

/// generated route for
/// [_i5.HomePage]
class HomeRoute extends _i7.PageRouteInfo<void> {
  const HomeRoute()
      : super(
          HomeRoute.name,
          path: 'home',
        );

  static const String name = 'HomeRoute';
}

/// generated route for
/// [_i1.ProfileParentPage]
class ProfileParentRoute extends _i7.PageRouteInfo<void> {
  const ProfileParentRoute({List<_i7.PageRouteInfo>? children})
      : super(
          ProfileParentRoute.name,
          path: 'profile',
          initialChildren: children,
        );

  static const String name = 'ProfileParentRoute';
}

/// generated route for
/// [_i6.SettingsWebPage]
class SettingsWebRoute extends _i7.PageRouteInfo<void> {
  const SettingsWebRoute()
      : super(
          SettingsWebRoute.name,
          path: 'settings',
        );

  static const String name = 'SettingsWebRoute';
}

/// generated route for
/// [_i1.SubNodePage]
class SubNodeRoute extends _i7.PageRouteInfo<SubNodeRouteArgs> {
  SubNodeRoute({
    _i10.Key? key,
    required String parentCelluleTag,
    _i1.KosmosSettingsConfig? settingsConfig,
    String? themeName,
    _i1.KosmosSettingsThemeData? theme,
  }) : super(
          SubNodeRoute.name,
          path: 'settings/:nodeTag',
          args: SubNodeRouteArgs(
            key: key,
            parentCelluleTag: parentCelluleTag,
            settingsConfig: settingsConfig,
            themeName: themeName,
            theme: theme,
          ),
          rawPathParams: {'nodeTag': parentCelluleTag},
        );

  static const String name = 'SubNodeRoute';
}

class SubNodeRouteArgs {
  const SubNodeRouteArgs({
    this.key,
    required this.parentCelluleTag,
    this.settingsConfig,
    this.themeName,
    this.theme,
  });

  final _i10.Key? key;

  final String parentCelluleTag;

  final _i1.KosmosSettingsConfig? settingsConfig;

  final String? themeName;

  final _i1.KosmosSettingsThemeData? theme;

  @override
  String toString() {
    return 'SubNodeRouteArgs{key: $key, parentCelluleTag: $parentCelluleTag, settingsConfig: $settingsConfig, themeName: $themeName, theme: $theme}';
  }
}

/// generated route for
/// [_i1.ChangePasswordPage]
class ChangePasswordRoute extends _i7.PageRouteInfo<void> {
  const ChangePasswordRoute()
      : super(
          ChangePasswordRoute.name,
          path: 'security/password',
        );

  static const String name = 'ChangePasswordRoute';
}

/// generated route for
/// [_i1.ChangePhonePage]
class ChangePhoneRoute extends _i7.PageRouteInfo<void> {
  const ChangePhoneRoute()
      : super(
          ChangePhoneRoute.name,
          path: 'security/phone-number',
        );

  static const String name = 'ChangePhoneRoute';
}

/// generated route for
/// [_i1.LoginPage]
class LoginRoute extends _i7.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i10.Key? key,
    void Function(_i10.BuildContext)? onLoginSuccess,
  }) : super(
          LoginRoute.name,
          path: 'login',
          args: LoginRouteArgs(
            key: key,
            onLoginSuccess: onLoginSuccess,
          ),
        );

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs({
    this.key,
    this.onLoginSuccess,
  });

  final _i10.Key? key;

  final void Function(_i10.BuildContext)? onLoginSuccess;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, onLoginSuccess: $onLoginSuccess}';
  }
}

/// generated route for
/// [_i1.PhoneLoginPage]
class PhoneLoginRoute extends _i7.PageRouteInfo<void> {
  const PhoneLoginRoute()
      : super(
          PhoneLoginRoute.name,
          path: 'login-with-phone',
        );

  static const String name = 'PhoneLoginRoute';
}
