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

import 'package:auto_route/auto_route.dart' as _i8;
import 'package:flutter/material.dart' as _i9;
import 'package:flutter/widgets.dart' as _i11;
import 'package:permissionrequest/permissons_package.dart' as _i4;
import 'package:skeleton/skeleton.dart' as _i1;

import '../config/permission_config.dart' as _i10;
import '../view/page/home_page.dart' as _i5;
import '../view/page/maintenance_page.dart' as _i2;
import '../view/page/register_page.dart' as _i7;
import '../view/page/settings/settings_page.dart' as _i6;
import '../view/page/update_required_page.dart' as _i3;

class AppRouter extends _i8.RootStackRouter {
  AppRouter({
    _i9.GlobalKey<_i9.NavigatorState>? navigatorKey,
    required this.isConnectedGuard,
    required this.permissionSeenGuard,
    required this.isNotConnectedGuard,
  }) : super(navigatorKey);

  final _i1.IsConnectedGuard isConnectedGuard;

  final _i10.PermissionSeenGuard permissionSeenGuard;

  final _i1.IsNotConnectedGuard isNotConnectedGuard;

  @override
  final Map<String, _i8.PageFactory> pagesMap = {
    LoggedUserAppCoreRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.LoggedUserAppCorePage(),
      );
    },
    AuthParentRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.AuthParentPage(),
      );
    },
    LegalInformationRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<LegalInformationRouteArgs>(
          orElse: () =>
              LegalInformationRouteArgs(info: pathParams.getString('info')));
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i1.LegalInformationPage(
          key: args.key,
          info: args.info,
        ),
      );
    },
    MaintenanceRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i2.MaintenancePage(),
      );
    },
    UpdateRequiredRoute.name: (routeData) {
      final args = routeData.argsAs<UpdateRequiredRouteArgs>(
          orElse: () => const UpdateRequiredRouteArgs());
      return _i8.MaterialPageX<dynamic>(
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
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i4.PermissionPage(
          key: args.key,
          permissions: args.permissions,
        ),
      );
    },
    HomeRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i5.HomePage(),
      );
    },
    ProfileParentRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.ProfileParentPage(),
      );
    },
    SettingsWebRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i6.SettingsWebPage(),
      );
    },
    SubNodeRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<SubNodeRouteArgs>(
          orElse: () => SubNodeRouteArgs(
              parentCelluleTag: pathParams.getString('nodeTag')));
      return _i8.MaterialPageX<dynamic>(
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
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.ChangePasswordPage(),
      );
    },
    ChangePhoneRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.ChangePhonePage(),
      );
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i1.LoginPage(
          key: args.key,
          onLoginSuccess: args.onLoginSuccess,
        ),
      );
    },
    PhoneLoginRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i1.PhoneLoginPage(),
      );
    },
    RegisterRoute.name: (routeData) {
      return _i8.MaterialPageX<dynamic>(
        routeData: routeData,
        child: const _i7.RegisterPage(),
      );
    },
  };

  @override
  List<_i8.RouteConfig> get routes => [
        _i8.RouteConfig(
          '/#redirect',
          path: '/',
          redirectTo: 'app',
          fullMatch: true,
        ),
        _i8.RouteConfig(
          LoggedUserAppCoreRoute.name,
          path: 'app',
          guards: [
            isConnectedGuard,
            permissionSeenGuard,
          ],
          children: [
            _i8.RouteConfig(
              '#redirect',
              path: '',
              parent: LoggedUserAppCoreRoute.name,
              redirectTo: 'home',
              fullMatch: true,
            ),
            _i8.RouteConfig(
              HomeRoute.name,
              path: 'home',
              parent: LoggedUserAppCoreRoute.name,
            ),
            _i8.RouteConfig(
              ProfileParentRoute.name,
              path: 'profile',
              parent: LoggedUserAppCoreRoute.name,
              guards: [isConnectedGuard],
              children: [
                _i8.RouteConfig(
                  '#redirect',
                  path: '',
                  parent: ProfileParentRoute.name,
                  redirectTo: 'settings',
                  fullMatch: true,
                ),
                _i8.RouteConfig(
                  SettingsWebRoute.name,
                  path: 'settings',
                  parent: ProfileParentRoute.name,
                ),
                _i8.RouteConfig(
                  SubNodeRoute.name,
                  path: 'settings/:nodeTag',
                  parent: ProfileParentRoute.name,
                ),
                _i8.RouteConfig(
                  ChangePasswordRoute.name,
                  path: 'security/password',
                  parent: ProfileParentRoute.name,
                ),
                _i8.RouteConfig(
                  ChangePhoneRoute.name,
                  path: 'security/phone-number',
                  parent: ProfileParentRoute.name,
                ),
              ],
            ),
          ],
        ),
        _i8.RouteConfig(
          AuthParentRoute.name,
          path: '/auth',
          guards: [isNotConnectedGuard],
          children: [
            _i8.RouteConfig(
              LoginRoute.name,
              path: 'login',
              parent: AuthParentRoute.name,
            ),
            _i8.RouteConfig(
              PhoneLoginRoute.name,
              path: 'login-with-phone',
              parent: AuthParentRoute.name,
            ),
            _i8.RouteConfig(
              RegisterRoute.name,
              path: 'register',
              parent: AuthParentRoute.name,
            ),
          ],
        ),
        _i8.RouteConfig(
          LegalInformationRoute.name,
          path: 'legal-information/:info',
        ),
        _i8.RouteConfig(
          MaintenanceRoute.name,
          path: '/maintenance',
        ),
        _i8.RouteConfig(
          UpdateRequiredRoute.name,
          path: '/update-required',
        ),
        _i8.RouteConfig(
          PermissionRoute.name,
          path: 'permission',
        ),
        _i8.RouteConfig(
          '*#redirect',
          path: '*',
          redirectTo: '/',
          fullMatch: true,
        ),
      ];
}

/// generated route for
/// [_i1.LoggedUserAppCorePage]
class LoggedUserAppCoreRoute extends _i8.PageRouteInfo<void> {
  const LoggedUserAppCoreRoute({List<_i8.PageRouteInfo>? children})
      : super(
          LoggedUserAppCoreRoute.name,
          path: 'app',
          initialChildren: children,
        );

  static const String name = 'LoggedUserAppCoreRoute';
}

/// generated route for
/// [_i1.AuthParentPage]
class AuthParentRoute extends _i8.PageRouteInfo<void> {
  const AuthParentRoute({List<_i8.PageRouteInfo>? children})
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
    extends _i8.PageRouteInfo<LegalInformationRouteArgs> {
  LegalInformationRoute({
    _i11.Key? key,
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

  final _i11.Key? key;

  final String info;

  @override
  String toString() {
    return 'LegalInformationRouteArgs{key: $key, info: $info}';
  }
}

/// generated route for
/// [_i2.MaintenancePage]
class MaintenanceRoute extends _i8.PageRouteInfo<void> {
  const MaintenanceRoute()
      : super(
          MaintenanceRoute.name,
          path: '/maintenance',
        );

  static const String name = 'MaintenanceRoute';
}

/// generated route for
/// [_i3.UpdateRequiredPage]
class UpdateRequiredRoute extends _i8.PageRouteInfo<UpdateRequiredRouteArgs> {
  UpdateRequiredRoute({
    _i11.Key? key,
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

  final _i11.Key? key;

  final String? storeUrl;

  @override
  String toString() {
    return 'UpdateRequiredRouteArgs{key: $key, storeUrl: $storeUrl}';
  }
}

/// generated route for
/// [_i4.PermissionPage]
class PermissionRoute extends _i8.PageRouteInfo<PermissionRouteArgs> {
  PermissionRoute({
    _i11.Key? key,
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

  final _i11.Key? key;

  final List<_i4.PermissionDataModel>? permissions;

  @override
  String toString() {
    return 'PermissionRouteArgs{key: $key, permissions: $permissions}';
  }
}

/// generated route for
/// [_i5.HomePage]
class HomeRoute extends _i8.PageRouteInfo<void> {
  const HomeRoute()
      : super(
          HomeRoute.name,
          path: 'home',
        );

  static const String name = 'HomeRoute';
}

/// generated route for
/// [_i1.ProfileParentPage]
class ProfileParentRoute extends _i8.PageRouteInfo<void> {
  const ProfileParentRoute({List<_i8.PageRouteInfo>? children})
      : super(
          ProfileParentRoute.name,
          path: 'profile',
          initialChildren: children,
        );

  static const String name = 'ProfileParentRoute';
}

/// generated route for
/// [_i6.SettingsWebPage]
class SettingsWebRoute extends _i8.PageRouteInfo<void> {
  const SettingsWebRoute()
      : super(
          SettingsWebRoute.name,
          path: 'settings',
        );

  static const String name = 'SettingsWebRoute';
}

/// generated route for
/// [_i1.SubNodePage]
class SubNodeRoute extends _i8.PageRouteInfo<SubNodeRouteArgs> {
  SubNodeRoute({
    _i11.Key? key,
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

  final _i11.Key? key;

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
class ChangePasswordRoute extends _i8.PageRouteInfo<void> {
  const ChangePasswordRoute()
      : super(
          ChangePasswordRoute.name,
          path: 'security/password',
        );

  static const String name = 'ChangePasswordRoute';
}

/// generated route for
/// [_i1.ChangePhonePage]
class ChangePhoneRoute extends _i8.PageRouteInfo<void> {
  const ChangePhoneRoute()
      : super(
          ChangePhoneRoute.name,
          path: 'security/phone-number',
        );

  static const String name = 'ChangePhoneRoute';
}

/// generated route for
/// [_i1.LoginPage]
class LoginRoute extends _i8.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i11.Key? key,
    void Function(_i11.BuildContext)? onLoginSuccess,
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

  final _i11.Key? key;

  final void Function(_i11.BuildContext)? onLoginSuccess;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, onLoginSuccess: $onLoginSuccess}';
  }
}

/// generated route for
/// [_i1.PhoneLoginPage]
class PhoneLoginRoute extends _i8.PageRouteInfo<void> {
  const PhoneLoginRoute()
      : super(
          PhoneLoginRoute.name,
          path: 'login-with-phone',
        );

  static const String name = 'PhoneLoginRoute';
}

/// generated route for
/// [_i7.RegisterPage]
class RegisterRoute extends _i8.PageRouteInfo<void> {
  const RegisterRoute()
      : super(
          RegisterRoute.name,
          path: 'register',
        );

  static const String name = 'RegisterRoute';
}
