import 'dart:math' as math;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/widgets.dart';
import 'package:wina/config/orientation_controller.dart';

/// Dimensions compactes pour téléphone.
///
/// Sur téléphone en paysage (~360 dp de haut), la mise à l'échelle de la
/// maquette tablette 1194x834 écrase les hauteurs et rend les textes
/// illisibles : ces helpers renvoient des dimensions réduites en dp réels, et
/// les valeurs `formatWidth` / `sp`… habituelles ailleurs (tablette, et
/// téléphone en portrait où le design 390x844 convient déjà : parcours
/// d'entrée).
bool get isPhoneLayout {
  if (!OrientationController.isPhone) return false;
  final Size size =
      WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
  return size.width > size.height;
}

const double _phoneDim = 0.65;

double cW(double v) => isPhoneLayout ? v * _phoneDim : formatWidth(v);
double cH(double v) => isPhoneLayout ? v * _phoneDim : formatHeight(v);
double cR(double v) => isPhoneLayout ? v * _phoneDim : r(v);
double cIc(double v) => isPhoneLayout ? v * 0.8 : sp(v);

/// À passer aux styles de `AppThemeStyle`, qui appliquent déjà `sp()` : on
/// pré-divise pour obtenir une taille de police réelle sur téléphone.
double cFs(double v) => isPhoneLayout ? math.max(10.0, v * 0.8) / sp(1) : v;

Widget cSw(double v) => SizedBox(width: cW(v));
Widget cSh(double v) => SizedBox(height: cH(v));
