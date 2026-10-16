import 'dart:async';

import 'package:flutter/material.dart';

/// {@category PopUp}
abstract class PopUp {
  /// Show a popup with child provided by [builder].
  /// The child is centered in the page.
  ///
  /// [builder] is a function that returns a widget and take the newContext and newSetState provided by the [StatefulBuilder].
  ///
  static FutureOr<T?> showGeneralPopUp<T>({
    required BuildContext context,
    required Widget Function(BuildContext, void Function(void Function()))
        builder,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transitionBuilder,
    Duration? transitionDuration,
    bool barrierDismissible = true,
    Color? scaffoldBackgroundColor,
  }) async {
    final rep = await showGeneralDialog<T>(
      context: context,
      transitionBuilder: transitionBuilder,
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (newContext, newSetter) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                overlayColor: MaterialStateProperty.resolveWith(
                    (states) => Colors.transparent),
                onTap: () => barrierDismissible
                    ? Navigator.of(newContext).pop(null)
                    : null,
                child: Scaffold(
                  backgroundColor:
                      scaffoldBackgroundColor ?? Colors.transparent,
                  body: Center(
                    child: InkWell(
                        mouseCursor: MouseCursor.uncontrolled,
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        overlayColor: MaterialStateProperty.resolveWith(
                            (states) => Colors.transparent),
                        onTap: () {},
                        child: builder(newContext, newSetter)),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    return rep;
  }
}
