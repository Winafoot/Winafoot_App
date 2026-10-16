import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/alert/theme/alert_theme.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

enum NotifBannerPosition {
  center,
  top,
  bottom,
}

/// {@category Widget}
/// {@category PopUp}
///
/// Il existe deux types de popup :
///
/// - [PopupAlert.toast] : affiche un toast contenant un titre et/ou un message.
/// - [PopupAlert.dialogBox] : affiche une popup contenant un titre et/ou un message avec des actions.
///
/// Exemple:
///
/// [PopupAlert.toast] :
/// Il est possible de définir le type de toast [AlertType] (success, error, warning, info) et de définir la position du toast [NotifBannerPosition] (top, bottom, center).
///
/// ![toast_example_error](../../images/toast/toast_example_error.png)
/// ![toast_example_success](../../images/toast/toast_example_success.png)
///
/// ```dart
/// // How to display a toast
/// PopupAlert.toast(
///   context,
///   FToast().init(context),
///   title: "Alert",
///   subtitle: "Texte d'exemple",
///   type: AlertType.success,
/// );
///
/// // For example, you can call this function inside a [Button] :
/// Button(
///   text: "Button",
///   onTap: () {
///     // Call PopupAlert to show a toast
///     PopupAlert.toast(
///       context,
///       FToast().init(context),
///       title: "Alert",
///       subtitle: "Texte d'exemple",
///       type: AlertType.success, // By default is [AlertType.error]
///     );
///   },
/// ),
/// ```
///
/// [PopupAlert.dialogBox] :
/// ![dialog_example](../../images/popup/dialog_box.png)
///
/// ```dart
/// // How to display a dialog box
/// await PopupAlert.dialogBox<void>(
///   context,
///   title: "Alert",
///   subtitle: "Texte d'exemple",
///   actions: [
///     Button(
///       text: "Cancel",
///       onTap: () => Navigator.pop(context),
///     ),
///   ],
/// );
/// ```
///
/// Les deux objets possède leur propre theme tag :
/// - [AlertTheme] pour [PopupAlert.toast] => "toast_alert"
/// - [AlertTheme] pour [PopupAlert.dialogBox] => "dialog_alert"
///
abstract class PopupAlert {
  static void toast(
    BuildContext context,
    FToast fToast, {
    final String? title,
    final String? subtitle,
    final AlertType type = AlertType.error,

    /// Toast configuration
    final NotifBannerPosition notifBannerPosition = NotifBannerPosition.top,
    final Duration? duration,
    final Duration? fadeDuration,

    /// Theme
    final String? themeName,
    final AlertTheme? theme,
  }) {
    final themeData = loadThemeData(
      theme,
      themeName ?? "toast_alert",
      () => const AlertTheme(),
      isDark: AppTheme.darkMode ?? false,
    );

    final child = Container(
      padding: themeData.padding ??
          EdgeInsets.symmetric(
              vertical: formatHeight(17), horizontal: formatWidth(20)),
      constraints: themeData.constraints ??
          BoxConstraints(
              minWidth: formatWidth(317),
              maxWidth: formatWidth(317),
              minHeight: formatHeight(77)),
      decoration: BoxDecoration(
        borderRadius: themeData.borderRadius ?? BorderRadius.circular(r(7)),
        color: themeData.backgroundColor ?? _getColorFromType(type, themeData),
        boxShadow: themeData.shadows ??
            [
              BoxShadow(
                  blurRadius: 30,
                  offset: const Offset(0, 3),
                  color: (themeData.backgroundColor ??
                          _getColorFromType(type, themeData))
                      .withOpacity(0.21))
            ],
        border: themeData.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: themeData.textStyle ?? _getStyleFromType(15),
              textAlign: TextAlign.center,
            )
          ],
          if (title != null && subtitle != null) sh(3),
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: themeData.subtitleStyle ??
                  _getStyleFromType(12.5, FontWeight.w500),
              textAlign: TextAlign.center,
            )
          ],
        ],
      ),
    );

    fToast.showToast(
      child: child,
      fadeDuration: fadeDuration ?? const Duration(milliseconds: 300),
      toastDuration: duration ?? const Duration(seconds: 3),
      positionedToastBuilder: (context, child, gravity) => _positionedToast(
        notifBannerPosition,
        child,
      ),
    );
  }

  static FutureOr<T?> dialogBox<T>(
    BuildContext context, {
    final String? title,
    final String? subtitle,
    final List<Widget Function(BuildContext)>? actionsBuilder,

    /// Theme
    final String? themeName,
    final AlertTheme? theme,
    final double? width,

    /// dialog Box Options
    final bool barrierDismissible = true,
    final bool showCloseButton = true,
  }) async {
    final themeData = loadThemeData(
      theme,
      themeName ?? "dialog_alert",
      () => const AlertTheme(),
      isDark: AppTheme.darkMode ?? false,
    );

    return await showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierDismissible ? "dismiss_popup" : null,
      pageBuilder: (ctx, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius:
                    themeData.borderRadius ?? BorderRadius.circular(28)),
            child: Container(
              width: width ?? formatWidth(282),
              padding: themeData.padding ??
                  EdgeInsets.symmetric(horizontal: formatWidth(34)).add(
                      EdgeInsets.only(
                          top: formatHeight(28), bottom: formatHeight(10))),
              decoration: BoxDecoration(
                color: themeData.backgroundColor ?? DefaultColor.white,
                borderRadius:
                    themeData.borderRadius ?? BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showCloseButton) ...[
                    Align(
                      alignment: Alignment.bottomRight,
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, null),
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFFCFD2D6), size: 30),
                      ),
                    ),
                    sh(4),
                  ],
                  if (title != null)
                    Center(
                        child: Text(title,
                            style: themeData.textStyle ??
                                DefaultAppStyle.darkBlue(19),
                            textAlign: TextAlign.center)),
                  if (title != null && subtitle != null) sh(6),
                  if (subtitle != null)
                    Center(
                        child: Text(subtitle,
                            style: themeData.subtitleStyle ??
                                DefaultAppStyle.lightGrey(14, FontWeight.w500),
                            textAlign: TextAlign.center)),
                  if (actionsBuilder != null) ...[
                    sh(24),
                    ...actionsBuilder.map((e) => Column(
                          children: [
                            e.call(ctx),
                            actionsBuilder.last == e ? const SizedBox() : sh(12)
                          ],
                        )),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _positionedToast(NotifBannerPosition position, Widget child) {
    switch (position) {
      case NotifBannerPosition.center:
        return Positioned(top: 0, left: 0, bottom: 0, right: 0, child: child);
      case NotifBannerPosition.top:
        return Positioned(
            top: formatHeight(40), left: 0, right: 0, child: child);
      case NotifBannerPosition.bottom:
        return Positioned(
            bottom: formatHeight(30), left: 0, right: 0, child: child);
      default:
        return Positioned(
            top: formatHeight(40), left: 0, right: 0, child: child);
    }
  }

  static Color _getColorFromType(AlertType type, AlertTheme theme) {
    return {
      AlertType.info: theme.infoBackground ?? DefaultColor.info,
      AlertType.success: theme.successBackground ?? DefaultColor.success,
      AlertType.warning: theme.warningBackground ?? DefaultColor.warning,
      AlertType.error: theme.errorBackground ?? DefaultColor.error,
    }[type]!;
  }

  static TextStyle _getStyleFromType(double size,
      [FontWeight fontWeight = FontWeight.w600]) {
    return DefaultAppStyle.white(size, fontWeight);
  }
}
