import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/card/theme/card_theme.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

class CardImageWithPadding extends ConsumerStatefulWidget {
  final Widget image;

  final String? title;
  final Widget? child;
  final String? subtitle;

  final BoxConstraints? constraints;

  /// Theme
  final KosmosCardThemeData? theme;
  final String? themeName;

  const CardImageWithPadding({
    super.key,
    required this.image,
    this.title,
    this.child,
    this.subtitle,
    this.constraints,

    /// Theme
    this.theme,
    this.themeName,
  });

  @override
  ConsumerState<CardImageWithPadding> createState() =>
      _CardImageWithPaddingState();
}

class _CardImageWithPaddingState extends ConsumerState<CardImageWithPadding> {
  @override
  Widget build(BuildContext context) {
    final KosmosCardThemeData themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "card-image-with-padding",
      () => kDefaultCardThemeData,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Container(
      decoration: themeData.cardDecoration,
      constraints: widget.constraints ??
          themeData.cardConstraints ??
          BoxConstraints(maxWidth: formatWidth(135)),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: themeData.cardPadding ?? EdgeInsets.all(formatWidth(7)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.image,
          sh(8),
          if (widget.title != null)
            Text(widget.title!, style: themeData.titleTextStyle),
          if (widget.title != null &&
              (widget.subtitle != null || widget.child != null))
            sh(4),
          if ((widget.subtitle != null || widget.child != null))
            widget.child ??
                Text(widget.subtitle!, style: themeData.subtitleTextStyle),
          sh(2),
        ],
      ),
    );
  }
}
