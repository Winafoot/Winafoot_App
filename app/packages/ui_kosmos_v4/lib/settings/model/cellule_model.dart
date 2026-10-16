import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum CelluleType { action, switcher, none }

/// {@category Model}
/// {@category Settings}
///
/// Contient toutes les données nécessaires à la construction d'une liste de
/// [SettingsCellule].
///
class CelluleSection {
  final String Function(BuildContext, WidgetRef) title;
  final Widget Function(BuildContext, WidgetRef)? titleBuilder;
  final List<CelluleModel> cellules;
  final EdgeInsetsGeometry? padding;
  final bool showTitle;
  // add bottom builder to the current Page Node.
  final Widget Function(BuildContext, WidgetRef)? bottomBuilder;

  const CelluleSection({
    required this.title,
    required this.cellules,
    this.bottomBuilder,
    this.padding,
    this.titleBuilder,
    this.showTitle = true,
  });

  CelluleSection copyWith({
    String Function(BuildContext, WidgetRef)? title,
    EdgeInsetsGeometry? padding,
    List<CelluleModel>? cellules,
    bool? showTitle,
    final Widget Function(BuildContext, WidgetRef)? titleBuilder,
    Widget Function(BuildContext, WidgetRef)? bottomBuilder,
  }) =>
      CelluleSection(
        title: title ?? this.title,
        cellules: cellules ?? this.cellules,
        padding: padding ?? this.padding,
        showTitle: showTitle ?? this.showTitle,
        bottomBuilder: bottomBuilder ?? this.bottomBuilder,
        titleBuilder: titleBuilder ?? this.titleBuilder,
      );
}

/// {@category Model}
/// {@category Settings}
///
/// Contient toutes les données nécessaires à la construction d'une [SettingsCellule].
///
class CelluleModel {
  final String tag;

  final String Function(BuildContext, WidgetRef) tileBuilder;

  final String Function(BuildContext, WidgetRef)? subTitleBuilder;

  final CelluleType type;

  /// Prefix
  final String? prefixSvgPath;

  final Widget Function(BuildContext, WidgetRef)? prefixBuilder;
  final Size? prefixBuilderSize;
  final EdgeInsetsGeometry? prefixBuilderPadding;
  final BoxDecoration? prefixBuilderParentDecoration;

  final bool Function(BuildContext, WidgetRef)? showNotifAlert;

  final FutureOr<bool?> Function(BuildContext, WidgetRef)? onTap;

  final FutureOr<bool> Function(BuildContext, WidgetRef, bool)? onSwitch;

  final bool Function(BuildContext, WidgetRef)? initialSwitchValue;
  final bool Function(BuildContext, WidgetRef)? hide;

  final CelluleSection? sectionChild;

  const CelluleModel({
    required this.tag,
    required this.tileBuilder,
    this.prefixBuilderPadding,
    this.subTitleBuilder,
    this.type = CelluleType.action,
    this.prefixSvgPath,
    this.prefixBuilder,
    this.showNotifAlert,
    this.onTap,
    this.onSwitch,
    this.sectionChild,
    this.initialSwitchValue,
    this.prefixBuilderSize,
    this.prefixBuilderParentDecoration,
    this.hide,
  })  : assert(type == CelluleType.switcher ? onSwitch != null : true),
        assert(type == CelluleType.action ? onTap != null : true);

  CelluleModel copyWith({
    String? tag,
    String Function(BuildContext, WidgetRef)? tileBuilder,
    String Function(BuildContext, WidgetRef)? subTitleBuilder,
    CelluleType? type,
    String? prefixSvgPath,
    Widget Function(BuildContext, WidgetRef)? prefixBuilder,
    BoxDecoration? prefixBuilderParentDecoration,
    Size? prefixBuilderSize,
    bool Function(BuildContext, WidgetRef)? showNotifAlert,
    FutureOr<bool?> Function(BuildContext, WidgetRef)? onTap,
    bool Function(BuildContext, WidgetRef, bool)? onSwitch,
    bool Function(BuildContext, WidgetRef)? initialSwitchValue,
    CelluleSection? sectionChild,
    EdgeInsetsGeometry? prefixBuilderPadding,
  }) =>
      CelluleModel(
        tag: tag ?? this.tag,
        prefixBuilderPadding: prefixBuilderPadding ?? this.prefixBuilderPadding,
        tileBuilder: tileBuilder ?? this.tileBuilder,
        subTitleBuilder: subTitleBuilder ?? this.subTitleBuilder,
        type: type ?? this.type,
        prefixSvgPath: prefixSvgPath ?? this.prefixSvgPath,
        prefixBuilder: prefixBuilder ?? this.prefixBuilder,
        prefixBuilderParentDecoration:
            prefixBuilderParentDecoration ?? this.prefixBuilderParentDecoration,
        prefixBuilderSize: prefixBuilderSize ?? this.prefixBuilderSize,
        showNotifAlert: showNotifAlert ?? this.showNotifAlert,
        onTap: onTap ?? this.onTap,
        onSwitch: onSwitch ?? this.onSwitch,
        initialSwitchValue: initialSwitchValue ?? this.initialSwitchValue,
        sectionChild: sectionChild ?? this.sectionChild,
      );
}
