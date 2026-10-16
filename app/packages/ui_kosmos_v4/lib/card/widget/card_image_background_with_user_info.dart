// ignore_for_file: deprecated_member_use

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_kosmos_v4/card/theme/card_theme.dart';

class CardImageBackgroundWithUserInfo extends ConsumerStatefulWidget {
  final Widget image;
  final String title;
  final Widget? imageUserProfile;
  final String? subtitle;
  final BoxConstraints? constraints;

  final bool showAction;
  final VoidCallback? onActionTap;

  /// Theme
  final KosmosCardThemeData? theme;
  final String? themeName;

  const CardImageBackgroundWithUserInfo({
    super.key,
    required this.image,
    required this.title,
    this.imageUserProfile,
    this.subtitle,
    this.constraints,
    this.onActionTap,
    this.showAction = true,

    /// Theme
    this.theme,
    this.themeName,
  });

  @override
  ConsumerState<CardImageBackgroundWithUserInfo> createState() =>
      _CardImageBackgroundWithUserInfoState();
}

class _CardImageBackgroundWithUserInfoState
    extends ConsumerState<CardImageBackgroundWithUserInfo> {
  @override
  Widget build(BuildContext context) {
    late final KosmosCardThemeData themeData = loadThemeData(
        widget.theme,
        widget.themeName ?? "card-image-with-padding",
        () => kDefaultCardThemeData,
        isDark: ref.watch(isDarkModeProvider).isDarkMode);
    return Container(
      decoration: themeData.cardDecoration,
      constraints: widget.constraints ??
          themeData.cardConstraints ??
          BoxConstraints(maxWidth: formatWidth(135)),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (_, c) {
        return Stack(
          children: [
            widget.image,
            Positioned(
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: themeData.cardDecoration?.color ?? Colors.white,
                  borderRadius: themeData.cardDecoration?.borderRadius,
                ),
                padding:
                    themeData.cardPadding ?? EdgeInsets.all(formatWidth(10)),
                width: c.maxWidth,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (widget.imageUserProfile != null) ...[
                      widget.imageUserProfile!,
                      sw(7),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.title, style: themeData.titleTextStyle),
                          if (widget.subtitle != null) sh(4),
                          if (widget.subtitle != null)
                            Text(widget.subtitle!,
                                style: themeData.subtitleTextStyle),
                        ],
                      ),
                    ),
                    if (widget.showAction) ...[
                      InkWell(
                        onTap: widget.onActionTap,
                        child: Padding(
                          padding: pwh(4, 4),
                          child: SvgPicture.asset(
                            "assets/svg/ic_more_vert.svg",
                            package: "ui_kosmos_v4",
                            width: formatWidth(4),
                            height: formatHeight(10),
                            color: themeData.iconActionColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
