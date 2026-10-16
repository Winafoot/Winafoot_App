import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// {@category Utils}
///
/// Permet d'executer une fonction en fonction de la plateforme.
T execInCaseOfPlatfom<T>(Function fnWeb, Function fnMobile) {
  if (!isTablet() && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    return fnMobile();
  } else {
    return fnWeb();
  }
}

/// {@category Utils}
///
/// Permet de récupérer la valeur en fonction de la plateforme.
T? getValueForPlatform<T>(T? val1, T? val2) =>
    execInCaseOfPlatfom(() => val1, () => val2);

bool isTablet() {
  final size = WidgetsBinding
          .instance.platformDispatcher.views.first.physicalSize /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  final shortestSide = size.shortestSide;

  return shortestSide >= 600;
}
