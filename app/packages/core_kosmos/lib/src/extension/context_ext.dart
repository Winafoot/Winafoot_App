import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

extension ContextExt on BuildContext {
  Future<bool> pop<T extends Object?>() {
    return AutoRouter.of(this).pop();
  }

  Future<T?> pushNamed<T extends Object?>(String routeName) {
    return AutoRouter.of(this).pushNamed<T>(routeName);
  }

  Future<T?> push<T extends Object?>(PageRouteInfo<dynamic> route) {
    return AutoRouter.of(this).push<T>(route);
  }

  Future<T?> pushAndPopUntil<T extends Object?>(
    PageRouteInfo<dynamic> route, {
    required bool Function(Route<dynamic>) predicate,
    void Function(NavigationFailure)? onFailure,
  }) {
    return AutoRouter.of(this).pushAndPopUntil<T>(
      route,
      predicate: predicate,
      onFailure: onFailure,
    );
  }

  // replace named route
  Future<T?> replaceNamed<T extends Object?>(String routeName) {
    return AutoRouter.of(this).replaceNamed<T>(routeName);
  }

  // add all navigate methods here
  Future<T?> replace<T extends Object?>(PageRouteInfo<dynamic> route) {
    return AutoRouter.of(this).replace<T>(route);
  }

  Future<T?> popAndPush<T extends Object?, TO extends Object?>(
    PageRouteInfo<TO> route,
  ) {
    return AutoRouter.of(this).popAndPush<T, TO>(route);
  }

  double get paddingTop => MediaQuery.of(this).padding.top;
  double get paddingBottom => MediaQuery.of(this).padding.bottom;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}
