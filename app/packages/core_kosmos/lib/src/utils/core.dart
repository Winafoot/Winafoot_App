import 'dart:io';

import 'package:core_kosmos/src/extension/list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// {@category Utils}
///
/// Permet d'executer une fonction après le build de la page.
void execAfterBuild(Function fn) => WidgetsBinding.instance.addPostFrameCallback((_) => fn());

/// {@category Utils}
///
/// Permet de récupérer la valeur d'une enum sous forme de [String].
String? enumToString<T>(T actual) {
  return actual.toString().split(".").last;
}

/// {@category Utils}
///
/// Permet de récupérer la valeur d'une [String] sous forme de l'enum [T].
T? stringToEnum<T>(List<T> values, String? value) {
  return values.firstWhereOrNull((element) => enumToString(element) == value);
}

/// {@category Utils}
///
/// Print Method
void printInDebug(dynamic obj) {
  if (kIsWeb && kDebugMode) {
    // ignore: avoid_print
    return print(obj);
  }
  if (kDebugMode) stdout.write("$obj\n");
}

/// {@category Utils}
///
void printInfo(dynamic obj) => printInDebug("\x1B[32m[Info] $obj\x1B[0m");

/// {@category Utils}
///
void printWarning(dynamic obj) => printInDebug("\x1B[33m[Warning] $obj\x1B[0m");

/// {@category Utils}
///
void printError(dynamic obj) => printInDebug("\x1B[31m[Error] $obj\x1B[0m");

/// {@category Utils}
///
void printDebug(dynamic obj) => printInDebug("\x1B[36m[Debug] $obj\x1B[0m");

/// {@category Utils}
///
void printExcept(dynamic obj) => printInDebug("\x1B[31m[Exception] $obj\x1B[0m");
