import 'package:flutter/material.dart';

class BottomBarItem {
  final String? label;
  final Widget icon;
  final String tag;
  final VoidCallback? onTap;
  final bool updateProvider;

  const BottomBarItem({
    this.label,
    required this.icon,
    required this.tag,
    this.updateProvider = true,
    this.onTap,
  }) : assert(tag.length != 0);
}
