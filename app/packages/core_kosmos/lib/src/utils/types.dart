import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';

/// {@category Typedef}
///
/// CallBack with return type passed [T]
typedef TypedCallback<T> = T? Function();

/// {@category Typedef}
///
/// Future CallBack with return type passed [T]
typedef FutureTypedCallback<T> = FutureOr<T?> Function();

/// {@category Typedef}
///
/// CallBack with return of [String] type
typedef StringCallback = String? Function();

/// {@category Typedef}
///
/// CallBack with return of [String] type with
/// [BuildContext] and [WidgetRef] parameters
typedef StringCallbackWithContext = String? Function(BuildContext, WidgetRef);

/// {@category Typedef}
///
/// CallBack with return of [FutureOr<void>] type with
/// [BuildContext] and [WidgetRef] parameters
typedef FutureVoidCallbackWithContext = FutureOr<void> Function(BuildContext, WidgetRef);

/// {@category Typedef}
///
/// CallBack with return of [FutureOr<void>] type with
/// [T] parameter
typedef FutureVoidCallbackWithParam<T> = FutureOr<void> Function(T);
