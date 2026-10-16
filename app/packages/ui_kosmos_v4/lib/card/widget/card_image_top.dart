import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/card/theme/card_theme.dart';

class CardImageTop extends ConsumerStatefulWidget {
  final Widget image;
  final String? title;
  final Widget? child;
  final String? subtitle;
  final BoxConstraints? constraints;

  final Widget? subChild;

  /// Theme
  final KosmosCardThemeData? theme;
  final String? themeName;

  const CardImageTop({
    super.key,
    required this.image,
    this.title,
    this.child,
    this.subtitle,
    this.constraints,
    this.subChild,

    /// Theme
    this.theme,
    this.themeName,
  });

  @override
  ConsumerState<CardImageTop> createState() => _CardImageTopState();
}

class _CardImageTopState extends ConsumerState<CardImageTop> {
  late final KosmosCardThemeData themeData = loadThemeData(
    widget.theme,
    widget.themeName ?? "card-image-with-padding",
    () => kDefaultCardThemeData,
    isDark: ref.watch(isDarkModeProvider).isDarkMode,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: themeData.cardDecoration,
      constraints: widget.constraints ??
          themeData.cardConstraints ??
          BoxConstraints(maxWidth: formatWidth(135)),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.image,
          Padding(
            padding: themeData.cardPadding ?? EdgeInsets.all(formatWidth(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null)
                  Text(widget.title!, style: themeData.titleTextStyle),
                if (widget.title != null &&
                    (widget.subtitle != null || widget.child != null))
                  sh(4),
                if ((widget.subtitle != null || widget.child != null))
                  widget.child ??
                      Text(widget.subtitle!,
                          style: themeData.subtitleTextStyle),
                if (widget.subChild != null) widget.subChild!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
