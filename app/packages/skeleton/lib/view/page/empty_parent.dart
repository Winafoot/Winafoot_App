import 'package:flutter/material.dart';

class EmptyParent extends StatelessWidget {
  final Widget child;

  const EmptyParent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}