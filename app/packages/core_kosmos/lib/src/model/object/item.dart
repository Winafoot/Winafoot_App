import 'package:flutter/material.dart';


/// {@category Model}
/// {@subCategory Object}
class ItemModel {
  /// Unique Tag
  final String tag;

  /// Enfant, sert pour l'affichage dans un widget
  final Widget child;

  /// Événement lors du clic sur l'élément
  final VoidCallback? onTap;

  const ItemModel({
    required this.tag,
    required this.child,
    this.onTap,
  });
}