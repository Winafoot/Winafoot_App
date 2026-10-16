import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

enum ButtonType {
  primary,
  secondary,
  text,
  icon,
}

/// {@category Widget}
/// {@category Button, CTA}
///
/// Un bouton est un widget permettant de déclencher une action lors de plusieurs événements (onTap, onLongPress et onDoubleTap).
///
/// Il est possible d'avoir plusieurs types de boutons :
/// - [ButtonType.primary] : Bouton principal
/// - [ButtonType.secondary] : Bouton secondaire
/// - [ButtonType.text] : Bouton textuel
/// - [ButtonType.icon] : Bouton avec une icône
///
/// Vous pouvez toutefois customiser ou créer votre propre type de bouton en passant par le [KosmosButtonThemeData].
/// Par défaut, le bouton est de type [ButtonType.primary].
///
/// Exemple:
///
/// ![button_example_primary_and_secondary](../../images/button/button_example_primary_and_secondary.png)
///
/// Pour définir un bouton dans le code vous pouvez directement définir le contenu des boutons.
///
/// ```dart
/// // Primary button
/// Button(
///   text: "Button",
///   onTap: () => printDebug("YOUPI"),
/// ),
///
/// // Button with specified type (secondary for this example)
/// Button(
///   buttonType: ButtonType.secondary,
///   child: Row(
///     mainAxisSize: MainAxisSize.min,
///     children: [const Icon(Icons.add), sw(8), const Text("Button")],
///   ),
/// ),
/// ```
///
/// Pour définir les thèmes, tout se passe dans le thème initialiseur de l'application (voir [AppTheme]).
///
/// ```dart
/// theme.addTheme(
///   "button_primary",
///   KosmosButtonThemeData(
///     padding: EdgeInsets.symmetric(vertical: formatHeight(18), horizontal: formatWidth(12)),
///     decoration: BoxDecoration(
///       color: Colors.blueAccent.shade200,
///       borderRadius: BorderRadius.circular(formatWidth(8)),
///     ),
///     buttonTextStyle: TextStyle(color: Colors.white, fontSize: sp(18)),
///   ),
/// );
///
/// theme.addTheme(
///   "button_secondary",
///   KosmosButtonThemeData(
///     padding: EdgeInsets.symmetric(vertical: formatHeight(18), horizontal: formatWidth(12)),
///     decoration: BoxDecoration(
///       color: Colors.transparent,
///       border: Border.all(color: Colors.blueAccent.shade100, width: formatWidth(1)),
///       borderRadius: BorderRadius.circular(formatWidth(8)),
///     ),
///     buttonTextStyle: TextStyle(color: Colors.white, fontSize: sp(18)),
///   ),
/// );
/// ```
///
/// /!\ Attention, il est obligatoire de fournir un text ou un child pour chaque bouton.
///
/// Chaque [ButtonType] possède son propre thème par défaut ([KosmosButtonThemeData]).
/// - [ButtonType.primary] : "button_primary"
/// - [ButtonType.secondary] : "button_secondary"
/// - [ButtonType.text] : "button_text"
/// - [ButtonType.icon] : "button_icon"
///

class Button extends ConsumerStatefulWidget {
  final String? text;
  final Widget? child;
  final ButtonType buttonType;

  /// Events
  final FutureOr<void> Function()? onTap;
  final FutureOr<void> Function()? onLongPress;
  final FutureOr<void> Function()? onDoubleTap;

  /// Config
  final bool showLoader;
  final bool enabled;
  final bool? isLoading;

  /// Theme
  final KosmosButtonThemeData? theme;
  final String? themeName;

  final ClassicLoaderThemeData? loaderTheme;
  final BoxConstraints? constraints;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Clip? clip;
  final TextStyle? buttonTextStyle;

  const Button({
    super.key,
    this.child,
    this.text,
    this.buttonType = ButtonType.primary,

    /// Events
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,

    /// Config
    this.showLoader = true,
    this.enabled = true,
    this.isLoading,

    /// Theme
    this.theme,
    this.themeName,
    this.clip,
    this.constraints,
    this.decoration,
    this.padding,
    this.width,
    this.height,
    this.loaderTheme,
    this.buttonTextStyle,
  }) : assert(child != null || text != null,
            "You must provide a child or a text for the button");

  @override
  ConsumerState<Button> createState() => _ButtonState();
}

class _ButtonState extends ConsumerState<Button> {
  bool mutex = true;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "button_${enumToString(widget.buttonType)}",
      () => kDefaultButtonThemeData,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );

    if (themeData.backgroundWidget == null) return _button(themeData);
    return Stack(
      children: [
        /// Background widget
        /// Background widget
        SizedBox(
            width: widget.width ?? themeData.width,
            child: themeData.backgroundWidget!),

        /// Button
        _button(themeData),
      ],
    );
  }

  Widget _button(KosmosButtonThemeData themeData) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: (widget.decoration ?? themeData.decoration)?.boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: (widget.decoration ?? themeData.decoration)?.borderRadius,
        clipBehavior: Clip.none,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: ClipRRect(
            borderRadius:
                (widget.decoration ?? themeData.decoration)?.borderRadius ??
                    BorderRadius.zero,
            child: InkWell(
              highlightColor: Colors.transparent,
              onTap: () async {
                if (!mutex) return;
                setState(() {
                  mutex = false;
                });
                if (!widget.enabled) {
                  setState(() {
                    mutex = true;
                  });

                  return;
                }
                if (isLoading) {
                  setState(() {
                    mutex = true;
                  });
                  return;
                }
                if (widget.showLoader) {
                  setState(() {
                    isLoading = true;
                  });
                }
                if (widget.onTap != null) await widget.onTap!();

                if (!mounted) {
                  mutex = true;
                  return;
                }

                // ignore: curly_braces_in_flow_control_structures
                setState(() {
                  if (widget.showLoader) isLoading = false;
                  mutex = true;
                });
              },
              onLongPress: widget.onLongPress != null
                  ? () async {
                      if (!widget.enabled) return;
                      if (isLoading) return;
                      if (widget.showLoader) {
                        setState(() {
                          isLoading = true;
                        });
                      }
                      if (widget.onLongPress != null) {
                        await widget.onLongPress!();
                      }
                      if (!mounted) return;
                      if (widget.showLoader) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  : null,
              onDoubleTap: widget.onDoubleTap != null
                  ? () async {
                      if (!widget.enabled) return;
                      if (isLoading) return;
                      if (widget.showLoader) {
                        setState(() {
                          isLoading = true;
                        });
                      }
                      if (widget.onDoubleTap != null) {
                        await widget.onDoubleTap!();
                      }
                      if (!mounted) return;
                      if (widget.showLoader) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  : null,
              child: Container(
                constraints: widget.constraints ?? themeData.constraints,
                decoration: (widget.decoration ?? themeData.decoration)
                    ?.copyWith(boxShadow: null),
                padding: widget.padding ?? themeData.padding,
                width: widget.width ?? themeData.width,
                height: widget.height ?? themeData.height,
                clipBehavior: widget.clip ?? themeData.clip ?? Clip.none,
                child: isLoading || widget.isLoading == true
                    ? Center(
                        child: LoaderClassique(
                            theme: widget.loaderTheme ?? themeData.loaderTheme))
                    : Center(
                        child: widget.child ??
                            Text(
                              widget.text!,
                              textAlign: TextAlign.center,
                              style: widget.buttonTextStyle ??
                                  themeData.buttonTextStyle ??
                                  TextStyle(
                                      color: Colors.black, fontSize: sp(18)),
                            ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
