import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ui_kosmos_v4/_deprecated/card/theme.dart';

abstract class Cards extends StatelessWidget {
  const factory Cards.one({
    final String title,
    final String subTitle,
    final TextStyle titleStyle,
    final TextStyle subTitleStyle,
    final int subtitleMaxLine,
    final bool center,
    final BoxConstraints boxConstraints,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final double radius,
    final Color backgroundColor,
    final EdgeInsets paddingImage,
    final EdgeInsets? paddingText,
    final ImageProvider? imageProvider,
    final Widget? imageWidget,
    final CustomCardsThemeData? theme,
    final String? themeName,
  }) = _One;

  const factory Cards.two({
    final String title,
    final String subTitle,
    final TextStyle titleStyle,
    final TextStyle subTitleStyle,
    final bool horizontal,
    final BoxConstraints? boxConstraints,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final double radius,
    final Color backgroundColor,
    final EdgeInsets paddingImage,
    final EdgeInsets paddingText,
    final String miniTitle,
    final String miniSubtitle,
    final TextStyle miniTitleStyle,
    final TextStyle miniSubtitleStyle,
    final ImageProvider? miniImageProvider,
    final Widget? miniImageWidget,
    final Widget? doublePointWidget,
    final EdgeInsets doublePointPadding,
    final Size doublePointSize,
    final VoidCallback? doublePointonTap,
    final VoidCallback? doublePointonDoubleTap,
    final ImageProvider? imageProvider,
    final Widget? imageWidget,
    final CustomCardsThemeData? theme,
    final String? themeName,
  }) = _Two;

  const factory Cards.three({
    final String title,
    final String subTitle,
    final TextStyle titleStyle,
    final TextStyle subTitleStyle,
    final BoxConstraints boxConstraints,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final double radius,
    final Color? backgroundColor,
    final EdgeInsets paddingImage,
    final EdgeInsets paddingText,
    final ImageProvider<Object>? imageProvider,
    final String? imageUrl,
    final ImageProvider? miniImageProvider,
    final Widget? miniImageWidget,
    final Widget? doublePointWidget,
    final EdgeInsets doublePointPadding,
    final Size doublePointSize,
    final VoidCallback? doublePointonTap,
    final VoidCallback? doublePointonDoubleTap,
    final CustomCardsThemeData? theme,
    final String? themeName,
  }) = _Three;

  const factory Cards.fourth({
    final String title,
    final String subTitle,
    final TextStyle titleStyle,
    final TextStyle subTitleStyle,
    final BoxConstraints? boxConstraints,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final double radius,
    final Color backgroundColor,
    final EdgeInsets paddingText,
    final ImageProvider<Object>? imageProvider,
    final Widget? imageWidget,
    final bool horizontal,
    final CustomCardsThemeData? theme,
    final String? themeName,
    final String? tagContent,
    final TextStyle? tagStyle,
    final Widget? tagWidget,
  }) = _Fourth;

  const factory Cards.five({
    final String title,
    final String subTitle,
    final TextStyle titleStyle,
    final TextStyle subTitleStyle,
    final int descMaxLine,
    final String desc,
    final TextStyle descStyle,
    final String mark,
    final TextStyle markTextStyle,
    final String bottomTitle,
    final TextStyle bottomTitleStyle,
    final bool bigImage,
    final BoxConstraints boxConstraints,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final double radius,
    final Color backgroundColor,
    final EdgeInsets paddingImage,
    final ImageProvider? imageProvider,
    final Widget? imageWidget,
    final CustomCardsThemeData? theme,
    final String? themeName,
    final Color? starColor,
  }) = _Five;

  const factory Cards.six({
    final String title,
    final String subTitle,
    final TextStyle titleStyle,
    final TextStyle subTitleStyle,
    final String miniTitle,
    final TextStyle miniTitleStyle,
    final String miniSubtitle,
    final TextStyle miniSubtitleStyle,
    final String statusText,
    final TextStyle? statusTextStyle,
    final Color? statusColor,
    final bool withIconButton,
    final bool withStatus,
    final bool boxShadow,
    final bool threeDots,
    final Widget? iconButton,
    final BoxConstraints boxConstraints,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final VoidCallback? onTapIconButton,
    final VoidCallback? onTapThreePoint,
    final double radius,
    final Color backgroundColor,
    final ImageProvider? imageProvider,
    final Widget? imageWidget,
    final Widget? threePointWidget,
    final Icon? iconMiniSubTitle,
    final EdgeInsetsGeometry contentPadding,
    final EdgeInsetsGeometry threePointWidgetPadding,
    final CustomCardsThemeData? theme,
    final String? themeName,
  }) = _Six;

  const factory Cards.seven({
    final String title,
    final String subTitle,
    final TextStyle titleStyle,
    final TextStyle subTitleStyle,
    final BoxConstraints boxConstraints,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final double radius,
    final Color? backgroundColor,
    final ImageProvider? imageProvider,
    final String? imageUrl,
    final Widget? doublePointWidget,
    final Size doublePointSize,
    final VoidCallback? doublePointonTap,
    final VoidCallback? doublePointonDoubleTap,
    final EdgeInsets? contentPadding,
    final bool variant,
    final CustomCardsThemeData? theme,
    final String? themeName,
  }) = _Seven;

  const factory Cards.nine({
    final String title,
    final String subTitle,
    final String desc,
    final TextStyle titleStyle,
    final TextStyle subTitleStyle,
    final TextStyle descStyle,
    final BoxConstraints? boxConstraints,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final double radius,
    final Color backgroundColor,
    final EdgeInsets paddingImage,
    final EdgeInsets paddingText,
    final Widget? doublePointWidget,
    final EdgeInsets doublePointPadding,
    final Size doublePointSize,
    final VoidCallback? doublePointonTap,
    final VoidCallback? doublePointonDoubleTap,
    final ImageProvider? imageProvider,
    final Widget? imageWidget,
    final CustomCardsThemeData? theme,
    final String? themeName,
  }) = _Nine;
}

class _One extends StatelessWidget implements Cards {
  final String title;
  final String subTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final int subtitleMaxLine;
  final bool center;
  final BoxConstraints? boxConstraints;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double? radius;
  final Color? backgroundColor;
  final EdgeInsets? paddingImage;
  final EdgeInsets? paddingText;
  final ImageProvider<Object>? imageProvider;
  final Widget? imageWidget;
  final CustomCardsThemeData? theme;
  final String? themeName;

  const _One({
    this.title = 'Titre',
    this.subTitle = 'Sous-titre',
    this.titleStyle,
    this.subTitleStyle,
    this.subtitleMaxLine = 2,
    this.center = false,
    this.boxConstraints,
    this.onTap,
    this.onDoubleTap,
    this.radius,
    this.backgroundColor,
    this.paddingImage,
    this.paddingText,
    this.imageProvider,
    this.imageWidget,
    this.theme,
    this.themeName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, themeName ?? "cards_one", () => const CustomCardsThemeData());

    return Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: boxConstraints ??
              themeData.constraints ??
              BoxConstraints(
                  minHeight: formatHeight(125),
                  minWidth: formatWidth(135),
                  maxHeight: formatHeight(125),
                  maxWidth: formatWidth(135)),
          decoration: BoxDecoration(
            color: backgroundColor ?? themeData.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(
                radius ?? themeData.radius ?? formatWidth(10)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                borderRadius: BorderRadius.circular(
                    radius ?? themeData.radius ?? formatWidth(10)),
                child: Stack(
                  children: [
                    Padding(
                      padding: paddingImage ??
                          themeData.paddingImage ??
                          EdgeInsets.all(formatWidth(8.0)),
                      child: imageWidget ??
                          Container(
                            height: formatHeight(68),
                            width: formatWidth(122),
                            decoration: imageProvider != null
                                ? BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(formatWidth(7)),
                                    image: DecorationImage(
                                        image: imageProvider!,
                                        fit: BoxFit.cover),
                                  )
                                : BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(formatWidth(7)),
                                    color: const Color(0xFF02132B)),
                          ),
                    ),
                    Padding(
                      padding: paddingText ??
                          themeData.paddingText ??
                          (center
                              ? EdgeInsets.only(bottom: formatHeight(9))
                              : EdgeInsets.only(
                                  left: formatWidth(14),
                                  bottom: formatHeight(9))),
                      child: center
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(title,
                                      style: titleStyle ??
                                          themeData.titleStyle ??
                                          TextStyle(
                                              fontSize: sp(13),
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF02132B))),
                                  Text(subTitle,
                                      style: subTitleStyle ??
                                          themeData.subTitleStyle ??
                                          TextStyle(
                                              fontSize: sp(10),
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF5A6575))),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: titleStyle ??
                                        themeData.titleStyle ??
                                        TextStyle(
                                            fontSize: sp(13),
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF02132B))),
                                Text(subTitle,
                                    style: subTitleStyle ??
                                        themeData.subTitleStyle ??
                                        TextStyle(
                                            fontSize: sp(10),
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF5A6575))),
                              ],
                            ),
                    )
                  ],
                )),
          ),
        ));
  }
}

class _Two extends StatelessWidget implements Cards {
  final String title;
  final String subTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final bool horizontal;
  final BoxConstraints? boxConstraints;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double? radius;
  final Color? backgroundColor;
  final EdgeInsets? paddingImage;
  final EdgeInsets? paddingText;
  final String miniTitle;
  final String miniSubtitle;
  final TextStyle? miniTitleStyle;
  final TextStyle? miniSubtitleStyle;
  final ImageProvider? miniImageProvider;
  final Widget? miniImageWidget;
  final Widget? doublePointWidget;
  final EdgeInsets? doublePointPadding;
  final Size? doublePointSize;
  final VoidCallback? doublePointonTap;
  final VoidCallback? doublePointonDoubleTap;
  final ImageProvider? imageProvider;
  final Widget? imageWidget;
  final CustomCardsThemeData? theme;
  final String? themeName;

  const _Two({
    this.title = 'Titre',
    this.subTitle = 'Sous-titre',
    this.titleStyle,
    this.subTitleStyle,
    this.horizontal = false,
    this.boxConstraints,
    this.onTap,
    this.onDoubleTap,
    this.radius,
    this.backgroundColor,
    this.paddingImage,
    this.paddingText,
    this.miniTitle = 'Titre',
    this.miniSubtitle = 'Sous-titre',
    this.miniTitleStyle,
    this.miniSubtitleStyle,
    this.miniImageProvider,
    this.miniImageWidget,
    this.doublePointWidget,
    this.doublePointPadding,
    this.doublePointSize,
    this.doublePointonTap,
    this.doublePointonDoubleTap,
    this.imageProvider,
    this.imageWidget,
    this.theme,
    this.themeName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, themeName ?? "cards_two", () => const CustomCardsThemeData());
    return Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: boxConstraints ??
              themeData.constraints ??
              (horizontal
                  ? BoxConstraints(
                      minHeight: formatHeight(125),
                      minWidth: formatWidth(315),
                      maxHeight: formatHeight(125),
                      maxWidth: formatWidth(315))
                  : BoxConstraints(
                      minHeight: formatHeight(176),
                      minWidth: formatWidth(139),
                      maxHeight: formatHeight(176),
                      maxWidth: formatWidth(139))),
          decoration: BoxDecoration(
              color:
                  backgroundColor ?? themeData.backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(
                  radius ?? themeData.radius ?? formatWidth(10))),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                borderRadius: BorderRadius.circular(
                    radius ?? themeData.radius ?? formatWidth(10)),
                child: Stack(
                  children: !horizontal
                      ? [
                          Padding(
                            padding: paddingImage ??
                                themeData.paddingImage ??
                                EdgeInsets.zero,
                            child: imageWidget ??
                                Container(
                                  height: formatHeight(101),
                                  decoration: imageProvider != null
                                      ? BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              radius ??
                                                  themeData.radius ??
                                                  formatWidth(10)),
                                          image: DecorationImage(
                                              image: imageProvider!,
                                              fit: BoxFit.cover),
                                        )
                                      : BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              radius ??
                                                  themeData.radius ??
                                                  formatWidth(10)),
                                          color: const Color(0xFF02132B)),
                                ),
                          ),
                          Padding(
                            padding: paddingText ??
                                themeData.paddingText ??
                                EdgeInsets.only(
                                    left: formatWidth(14),
                                    bottom: formatHeight(9)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: titleStyle ??
                                      themeData.titleStyle ??
                                      TextStyle(
                                          fontSize: sp(13),
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF02132B)),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  subTitle,
                                  style: subTitleStyle ??
                                      themeData.subTitleStyle ??
                                      TextStyle(
                                          fontSize: sp(10),
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF5A6575)),
                                  textAlign: TextAlign.left,
                                ),
                                sh(7),
                                Row(
                                  children: [
                                    miniImageWidget ??
                                        Container(
                                          height: formatHeight(19),
                                          width: formatWidth(19),
                                          decoration: miniImageProvider != null
                                              ? BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                      image: miniImageProvider!,
                                                      fit: BoxFit.cover),
                                                )
                                              : const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF02132B),
                                                ),
                                        ),
                                    sw(6),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(miniTitle,
                                            style: miniTitleStyle ??
                                                themeData.miniTitleStyle ??
                                                TextStyle(
                                                    fontSize: sp(9),
                                                    fontWeight: FontWeight.w400,
                                                    color: const Color(
                                                        0xFF02132B)),
                                            textAlign: TextAlign.left),
                                        Text(miniSubtitle,
                                            style: miniSubtitleStyle ??
                                                themeData.miniSubTitleStyle ??
                                                TextStyle(
                                                    fontSize: sp(7),
                                                    fontWeight: FontWeight.w400,
                                                    color: const Color(
                                                        0xFF5A6575)),
                                            textAlign: TextAlign.left),
                                      ],
                                    ),
                                    const Spacer(),
                                  ],
                                )
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: doublePointPadding ??
                                  themeData.paddingDoublePoint ??
                                  EdgeInsets.only(bottom: formatHeight(7)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(radius ??
                                    themeData.radius ??
                                    formatWidth(10)),
                                onTap: doublePointonTap,
                                onDoubleTap: doublePointonDoubleTap,
                                child: SizedBox(
                                  height: (doublePointSize ??
                                          themeData.doublePointSize ??
                                          Size(formatWidth(23),
                                              formatHeight(23)))
                                      .height,
                                  width: (doublePointSize ??
                                          themeData.doublePointSize ??
                                          Size(formatWidth(23),
                                              formatHeight(23)))
                                      .width,
                                  child: doublePointWidget ??
                                      Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: 3,
                                              width: 3,
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF9199A7)),
                                            ),
                                            SizedBox(height: formatHeight(3)),
                                            Container(
                                              height: formatHeight(3),
                                              width: formatWidth(3),
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF9199A7)),
                                            ),
                                          ]),
                                ),
                              ),
                            ),
                          )
                        ]
                      : [
                          Row(
                            children: [
                              Container(
                                width: formatWidth(134),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(radius ??
                                      themeData.radius ??
                                      formatWidth(10)),
                                  color: const Color(0xFF02132B),
                                ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(left: formatWidth(13.0)),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: titleStyle,
                                          textAlign: TextAlign.left),
                                      Text(subTitle,
                                          style: subTitleStyle,
                                          textAlign: TextAlign.left),
                                      SizedBox(height: formatHeight(10)),
                                      Row(
                                        children: [
                                          miniImageWidget ??
                                              Container(
                                                height: formatHeight(19),
                                                width: formatWidth(19),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF02132B),
                                                ),
                                              ),
                                          SizedBox(width: formatWidth(6)),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(miniTitle,
                                                  style: miniTitleStyle,
                                                  textAlign: TextAlign.left),
                                              Text(miniSubtitle,
                                                  style: miniSubtitleStyle,
                                                  textAlign: TextAlign.left),
                                            ],
                                          ),
                                        ],
                                      )
                                    ]),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: doublePointPadding ??
                                  themeData.paddingDoublePoint ??
                                  EdgeInsets.only(bottom: formatHeight(7)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(radius ??
                                    themeData.radius ??
                                    formatWidth(10)),
                                onTap: doublePointonTap,
                                onDoubleTap: doublePointonDoubleTap,
                                child: SizedBox(
                                  height: (doublePointSize ??
                                          themeData.doublePointSize ??
                                          Size(formatWidth(23),
                                              formatHeight(23)))
                                      .height,
                                  width: (doublePointSize ??
                                          themeData.doublePointSize ??
                                          Size(formatWidth(23),
                                              formatHeight(23)))
                                      .width,
                                  child: doublePointWidget ??
                                      Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: formatHeight(3),
                                              width: formatWidth(3),
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF9199A7)),
                                            ),
                                            SizedBox(height: formatHeight(3)),
                                            Container(
                                              height: formatHeight(3),
                                              width: formatWidth(3),
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF9199A7)),
                                            ),
                                          ]),
                                ),
                              ),
                            ),
                          )
                        ],
                )),
          ),
        ));
  }
}

class _Three extends StatelessWidget implements Cards {
  final String title;
  final String subTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final BoxConstraints? boxConstraints;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double? radius;
  final Color? backgroundColor;
  final EdgeInsets? paddingImage;
  final EdgeInsets? paddingText;
  final ImageProvider? imageProvider;
  final String? imageUrl;
  final ImageProvider? miniImageProvider;
  final Widget? miniImageWidget;
  final Widget? doublePointWidget;
  final EdgeInsets? doublePointPadding;
  final Size? doublePointSize;
  final VoidCallback? doublePointonTap;
  final VoidCallback? doublePointonDoubleTap;
  final CustomCardsThemeData? theme;
  final String? themeName;

  const _Three({
    this.title = 'Titre',
    this.subTitle = 'Sous-titre',
    this.titleStyle,
    this.subTitleStyle,
    this.boxConstraints,
    this.onTap,
    this.onDoubleTap,
    this.radius,
    this.backgroundColor,
    this.paddingImage,
    this.paddingText,
    this.imageProvider,
    this.imageUrl,
    this.miniImageProvider,
    this.miniImageWidget,
    this.doublePointWidget,
    this.doublePointPadding,
    this.doublePointSize,
    this.doublePointonDoubleTap,
    this.doublePointonTap,
    this.theme,
    this.themeName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        type: MaterialType.transparency,
        child: imageProvider == null && imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                imageBuilder: (context, image) {
                  return card(image);
                },
              )
            : imageUrl == null
                ? card(imageProvider!)
                : card(null));
  }

  Widget card(ImageProvider<Object>? image) {
    final themeData = loadThemeData(
        theme, themeName ?? "cards_third", () => const CustomCardsThemeData());

    return Container(
      constraints: boxConstraints ??
          themeData.constraints ??
          BoxConstraints(
              minHeight: formatHeight(186),
              minWidth: formatWidth(146),
              maxHeight: formatHeight(186),
              maxWidth: formatWidth(146)),
      decoration: image != null
          ? BoxDecoration(
              image: DecorationImage(image: image, fit: BoxFit.cover),
              borderRadius: BorderRadius.circular(
                  radius ?? themeData.radius ?? formatWidth(10)))
          : BoxDecoration(
              color: backgroundColor ?? const Color(0xFF02132B),
              borderRadius: BorderRadius.circular(
                  radius ?? themeData.radius ?? formatWidth(10))),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            borderRadius: BorderRadius.circular(
                radius ?? themeData.radius ?? formatWidth(10)),
            child: Stack(children: [
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: formatHeight(50),
                    decoration: BoxDecoration(
                      color: themeData.backgroundColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(
                          radius ?? themeData.radius ?? formatWidth(10)),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: formatWidth(8)),
                            child: Row(
                              children: [
                                miniImageWidget ??
                                    Container(
                                      height: formatHeight(30),
                                      width: formatWidth(30),
                                      decoration: miniImageProvider != null
                                          ? BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                  image: miniImageProvider!,
                                                  fit: BoxFit.cover))
                                          : const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF02132B),
                                            ),
                                    ),
                                SizedBox(width: formatWidth(7)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: titleStyle ??
                                            themeData.titleStyle ??
                                            TextStyle(
                                                fontSize: sp(12),
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF02132B)),
                                        textAlign: TextAlign.left),
                                    Text(subTitle,
                                        style: subTitleStyle ??
                                            themeData.subTitleStyle ??
                                            TextStyle(
                                                fontSize: sp(10),
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF5A6575)),
                                        textAlign: TextAlign.left),
                                  ],
                                ),
                                const Spacer(),
                                InkWell(
                                  borderRadius: BorderRadius.circular(radius ??
                                      themeData.radius ??
                                      formatWidth(10)),
                                  onTap: doublePointonTap,
                                  onDoubleTap: doublePointonDoubleTap,
                                  child: SizedBox(
                                    height: (doublePointSize ??
                                            themeData.doublePointSize ??
                                            Size(formatWidth(23),
                                                formatHeight(23)))
                                        .height,
                                    width: (doublePointSize ??
                                            themeData.doublePointSize ??
                                            Size(formatWidth(23),
                                                formatHeight(23)))
                                        .width,
                                    child: doublePointWidget ??
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: formatHeight(3),
                                              width: formatWidth(3),
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF9199A7)),
                                            ),
                                            SizedBox(height: formatHeight(3)),
                                            Container(
                                              height: formatHeight(3),
                                              width: formatWidth(3),
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF9199A7)),
                                            ),
                                          ],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                  )),
            ])),
      ),
    );
  }
}

class _Fourth extends StatelessWidget implements Cards {
  final String title;
  final String subTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final BoxConstraints? boxConstraints;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double? radius;
  final Color? backgroundColor;
  final EdgeInsets? paddingText;
  final ImageProvider<Object>? imageProvider;
  final Widget? imageWidget;
  final bool horizontal;
  final CustomCardsThemeData? theme;
  final String? themeName;
  final String? tagContent;
  final Widget? tagWidget;
  final TextStyle? tagStyle;

  const _Fourth({
    this.title = '',
    this.subTitle = 'Sous-titre',
    this.titleStyle,
    this.subTitleStyle,
    this.boxConstraints,
    this.onTap,
    this.onDoubleTap,
    this.radius,
    this.backgroundColor,
    this.paddingText,
    this.imageProvider,
    this.imageWidget,
    this.horizontal = false,
    this.theme,
    this.themeName,
    this.tagContent,
    this.tagStyle,
    this.tagWidget,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, themeName ?? "cards_four", () => const CustomCardsThemeData());

    return Material(
        type: MaterialType.transparency,
        child: Container(
          clipBehavior: Clip.hardEdge,
          constraints: boxConstraints ??
              (horizontal
                  ? BoxConstraints(
                      minHeight: formatHeight(96),
                      minWidth: formatWidth(312),
                      maxHeight: formatHeight(96),
                      maxWidth: formatWidth(312))
                  : BoxConstraints(
                      minHeight: formatHeight(156),
                      minWidth: formatWidth(158),
                      maxHeight: formatHeight(156),
                      maxWidth: formatWidth(158))),
          decoration: BoxDecoration(
            color: backgroundColor ?? themeData.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(
              radius ?? themeData.radius ?? formatWidth(10),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                borderRadius: BorderRadius.circular(
                    radius ?? themeData.radius ?? formatWidth(10)),
                child: Stack(
                  children: !horizontal
                      ? [
                          Container(
                            height: formatWidth(96),
                            decoration: imageProvider != null
                                ? BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(formatWidth(7)),
                                    image: DecorationImage(
                                        image: imageProvider!,
                                        fit: BoxFit.cover),
                                  )
                                : BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(formatWidth(7)),
                                    color: const Color(0xFF02132B)),
                            clipBehavior: Clip.hardEdge,
                            child: imageWidget,
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: formatHeight(6), right: formatWidth(7)),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: tagWidget ??
                                  Container(
                                    height: formatHeight(21),
                                    width: formatWidth(34),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: const Color(0xFF02132B)),
                                    child: Center(
                                      child: Text(
                                        tagContent ?? 'Tag',
                                        style: tagStyle ??
                                            themeData.tagStyle ??
                                            TextStyle(
                                                fontSize: sp(7),
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          Padding(
                            padding: paddingText ??
                                themeData.paddingText ??
                                EdgeInsets.only(
                                    left: formatWidth(14),
                                    bottom: formatHeight(9)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: titleStyle ??
                                        themeData.titleStyle ??
                                        TextStyle(
                                            fontSize: sp(11),
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF02132B)),
                                    textAlign: TextAlign.left),
                                Text(subTitle,
                                    style: subTitleStyle ??
                                        themeData.subTitleStyle ??
                                        TextStyle(
                                            fontSize: sp(10),
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF5A6575)),
                                    textAlign: TextAlign.left),
                              ],
                            ),
                          )
                        ]
                      : [
                          Row(
                            children: [
                              imageWidget ??
                                  Container(
                                    width: formatWidth(156),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(formatWidth(7)),
                                      color: const Color(0xFF02132B)
                                          .withOpacity(0.50),
                                    ),
                                  ),
                              SizedBox(width: formatWidth(12)),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      formatWidth(12.5),
                                      formatHeight(12.5),
                                      formatWidth(24),
                                      formatHeight(9)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: titleStyle,
                                          textAlign: TextAlign.left),
                                      const Spacer(),
                                      Text(subTitle,
                                          style: subTitleStyle,
                                          textAlign: TextAlign.left),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: formatHeight(6), left: formatWidth(7)),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                height: formatHeight(21),
                                width: formatWidth(34),
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(formatWidth(5)),
                                    color: const Color(0xFF02132B)),
                                child: Center(
                                    child: Text(
                                  'Tag',
                                  style: TextStyle(
                                      fontSize: sp(7),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white),
                                )),
                              ),
                            ),
                          ),
                        ],
                )),
          ),
        ));
  }
}

class _Five extends StatelessWidget implements Cards {
  final String title;
  final String subTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final String desc;
  final int descMaxLine;
  final TextStyle? descStyle;
  final String mark;
  final TextStyle? markTextStyle;
  final String bottomTitle;
  final TextStyle? bottomTitleStyle;
  final bool bigImage;
  final BoxConstraints? boxConstraints;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double? radius;
  final Color? backgroundColor;
  final EdgeInsets? paddingImage;
  final ImageProvider? imageProvider;
  final Widget? imageWidget;
  final CustomCardsThemeData? theme;
  final String? themeName;
  final Color? starColor;

  const _Five({
    this.title = 'Anna Clark',
    this.subTitle = 'à 21km',
    this.titleStyle,
    this.subTitleStyle,
    this.desc =
        '',
    this.descStyle,
    this.descMaxLine = 3,
    this.mark = '5/5',
    this.markTextStyle,
    this.bottomTitle = '25 € /h',
    this.bottomTitleStyle,
    this.bigImage = false,
    this.boxConstraints,
    this.onTap,
    this.onDoubleTap,
    this.radius,
    this.backgroundColor,
    this.paddingImage,
    this.imageProvider,
    this.imageWidget,
    this.theme,
    this.themeName,
    this.starColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, themeName ?? "cards_five", () => const CustomCardsThemeData());

    return Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: boxConstraints ??
              themeData.constraints ??
              BoxConstraints(
                minHeight: formatHeight(134),
                minWidth: formatWidth(317),
                maxHeight: formatHeight(134),
                maxWidth: formatWidth(317),
              ),
          decoration: BoxDecoration(
            color: backgroundColor ?? themeData.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(
                radius ?? themeData.radius ?? formatWidth(10)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                borderRadius: BorderRadius.circular(
                    radius ?? themeData.radius ?? formatWidth(10)),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: formatHeight(8), right: formatWidth(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(mark,
                              style: markTextStyle ??
                                  themeData.markTextStyle ??
                                  TextStyle(
                                      fontSize: sp(11),
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF5A6575))),
                          Icon(Icons.star_rate_rounded,
                              color: starColor ?? const Color(0xFF02132B),
                              size: 16),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: formatHeight(8), right: formatWidth(10)),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          bottomTitle,
                          style: bottomTitleStyle ??
                              themeData.bottomTitleStyle ??
                              TextStyle(
                                  fontSize: sp(12),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF02132B)),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: paddingImage ??
                              themeData.paddingImage ??
                              EdgeInsets.fromLTRB(
                                  formatWidth(13),
                                  formatHeight(11),
                                  formatWidth(16),
                                  formatHeight(11)),
                          child: bigImage
                              ? imageWidget ??
                                  Container(
                                    width: formatWidth(99),
                                    decoration: imageProvider != null
                                        ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                formatWidth(7)),
                                            image: DecorationImage(
                                                image: imageProvider!,
                                                fit: BoxFit.cover),
                                          )
                                        : BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                formatWidth(7)),
                                            color: const Color(0xFF02132B),
                                          ),
                                  )
                              : imageWidget ??
                                  Container(
                                    height: formatHeight(40),
                                    width: formatWidth(40),
                                    decoration: imageProvider != null
                                        ? BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                                image: imageProvider!,
                                                fit: BoxFit.cover),
                                          )
                                        : const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF02132B),
                                          ),
                                  ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                formatWidth(0),
                                formatHeight(13),
                                formatWidth(14),
                                formatHeight(26)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: titleStyle ??
                                      themeData.titleStyle ??
                                      TextStyle(
                                          fontSize: sp(13),
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF02132B)),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  subTitle,
                                  style: subTitleStyle ??
                                      themeData.subTitleStyle ??
                                      TextStyle(
                                          fontSize: sp(11),
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF5A6575)),
                                  textAlign: TextAlign.left,
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        desc,
                                        maxLines: descMaxLine,
                                        style: descStyle ??
                                            themeData.descStyle ??
                                            TextStyle(
                                                fontSize: sp(12),
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF02132B)),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                )),
          ),
        ));
  }
}

class _Six extends StatelessWidget implements Cards {
  final String title;
  final String subTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final String miniTitle;
  final TextStyle? miniTitleStyle;
  final String miniSubtitle;
  final TextStyle? miniSubtitleStyle;
  final String statusText;
  final TextStyle? statusTextStyle;
  final Color? statusColor;
  final bool withIconButton;
  final bool withStatus;
  final bool boxShadow;
  final bool threeDots;
  final Widget? iconButton;
  final BoxConstraints? boxConstraints;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTapIconButton;
  final VoidCallback? onTapThreePoint;
  final double? radius;
  final Color? backgroundColor;
  final ImageProvider? imageProvider;
  final Widget? imageWidget;
  final Widget? threePointWidget;
  final Icon? iconMiniSubTitle;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? threePointWidgetPadding;
  final CustomCardsThemeData? theme;
  final String? themeName;

  const _Six({
    this.title = 'Titre',
    this.subTitle = 'Sous-titre',
    this.titleStyle,
    this.subTitleStyle,
    this.miniTitle = 'Titre',
    this.miniSubtitle = '4.9',
    this.miniTitleStyle,
    this.miniSubtitleStyle,
    this.statusText = 'En cours',
    this.statusTextStyle,
    this.statusColor,
    this.withIconButton = true,
    this.withStatus = true,
    this.boxShadow = false,
    this.threeDots = false,
    this.iconButton,
    this.boxConstraints,
    this.onTap,
    this.onDoubleTap,
    this.radius,
    this.backgroundColor,
    this.imageProvider,
    this.imageWidget,
    this.onTapIconButton,
    this.iconMiniSubTitle,
    this.threePointWidget,
    this.onTapThreePoint,
    this.contentPadding,
    this.threePointWidgetPadding,
    this.theme,
    this.themeName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, themeName ?? "cards_six", () => const CustomCardsThemeData());

    return Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: boxConstraints ??
              themeData.constraints ??
              BoxConstraints(
                  minHeight: formatHeight(125),
                  minWidth: formatWidth(315),
                  maxHeight: formatHeight(125),
                  maxWidth: formatWidth(315)),
          decoration: BoxDecoration(
            boxShadow: boxShadow
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 10))
                  ]
                : null,
            color: backgroundColor ?? themeData.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(
                radius ?? themeData.radius ?? formatWidth(10)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                borderRadius: BorderRadius.circular(
                    radius ?? themeData.radius ?? formatWidth(10)),
                child: Stack(
                  children: [
                    if (threeDots)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: threePointWidgetPadding ??
                              themeData.paddingTriplePoint ??
                              EdgeInsets.only(
                                  top: formatHeight(7), right: formatWidth(4)),
                          child: InkWell(
                            onTap: onTapThreePoint,
                            borderRadius: BorderRadius.circular(
                                radius ?? themeData.radius ?? formatWidth(10)),
                            child: SizedBox(
                              height: formatHeight(30),
                              width: formatWidth(30),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: formatHeight(3),
                                    width: formatWidth(3),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF9199A7)),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    height: formatHeight(3),
                                    width: formatWidth(3),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF9199A7)),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    height: formatHeight(3),
                                    width: formatWidth(3),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF9199A7)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: contentPadding ??
                          themeData.paddingContent ??
                          EdgeInsets.fromLTRB(formatWidth(17), formatHeight(17),
                              formatWidth(16), formatHeight(19)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: titleStyle ??
                                  themeData.titleStyle ??
                                  TextStyle(
                                      fontSize: sp(13),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF02132B))),
                          Text(subTitle,
                              style: subTitleStyle ??
                                  themeData.subTitleStyle ??
                                  TextStyle(
                                      fontSize: sp(10),
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF5A6575))),
                          const Spacer(),
                          Container(
                            height: formatHeight(0.5),
                            color: const Color(0xFF02132B).withOpacity(0.17),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              imageWidget ??
                                  Container(
                                    height: formatHeight(27),
                                    width: formatWidth(27),
                                    decoration: imageProvider != null
                                        ? BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                                image: imageProvider!,
                                                fit: BoxFit.cover),
                                          )
                                        : const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF02132B),
                                          ),
                                  ),
                              SizedBox(width: formatWidth(6)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(miniTitle,
                                      style: miniTitleStyle ??
                                          themeData.miniTitleStyle ??
                                          TextStyle(
                                              fontSize: sp(9),
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF02132B))),
                                  Row(
                                    children: [
                                      Text(miniSubtitle,
                                          style: miniSubtitleStyle ??
                                              themeData.miniSubTitleStyle ??
                                              TextStyle(
                                                  fontSize: sp(7),
                                                  fontWeight: FontWeight.w400,
                                                  color:
                                                      const Color(0xFF5A6575))),
                                      iconMiniSubTitle ??
                                          const Icon(Icons.star_rate_rounded,
                                              color: Color(0xFF02132B),
                                              size: 10),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              withIconButton
                                  ? InkWell(
                                      onTap: onTapIconButton,
                                      child: iconButton ??
                                          Container(
                                            height: formatHeight(34),
                                            width: formatWidth(34),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFF02132B),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        radius ??
                                                            themeData.radius ??
                                                            formatWidth(10))),
                                            child: const Icon(
                                              Iconsax.message,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                    )
                                  : const SizedBox(),
                              SizedBox(width: formatWidth(9)),
                              withStatus
                                  ? Container(
                                      height: formatHeight(34),
                                      width: formatWidth(99),
                                      decoration: BoxDecoration(
                                          color: statusColor ??
                                              const Color(0xFF02132B)
                                                  .withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(
                                              radius ??
                                                  themeData.radius ??
                                                  formatWidth(10))),
                                      child: Center(
                                        child: Text(
                                          statusText,
                                          style: statusTextStyle ??
                                              TextStyle(
                                                  color: const Color(0xFF02132B)
                                                      .withOpacity(0.65),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: sp(10)),
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                )),
          ),
        ));
  }
}

class _Seven extends StatelessWidget implements Cards {
  final String title;
  final String subTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final BoxConstraints? boxConstraints;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double? radius;
  final Color? backgroundColor;
  final ImageProvider? imageProvider;
  final String? imageUrl;
  final Widget? doublePointWidget;
  final Size? doublePointSize;
  final VoidCallback? doublePointonTap;
  final VoidCallback? doublePointonDoubleTap;
  final EdgeInsets? contentPadding;
  final bool variant;
  final CustomCardsThemeData? theme;
  final String? themeName;

  const _Seven({
    this.title = 'Titre',
    this.subTitle = 'Sous-titre',
    this.titleStyle,
    this.subTitleStyle,
    this.boxConstraints,
    this.onTap,
    this.onDoubleTap,
    this.radius,
    this.backgroundColor,
    this.imageProvider,
    this.imageUrl,
    this.doublePointWidget,
    this.doublePointSize,
    this.doublePointonDoubleTap,
    this.doublePointonTap,
    this.contentPadding,
    this.variant = false,
    this.theme,
    this.themeName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        type: MaterialType.transparency,
        child: imageProvider == null && imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                imageBuilder: (context, image) {
                  return card(image);
                },
              )
            : imageUrl == null
                ? card(imageProvider!)
                : card(null));
  }

  Widget card(ImageProvider<Object>? image) {
    final themeData = loadThemeData(
        theme, themeName ?? "cards_seven", () => const CustomCardsThemeData());

    return Container(
      constraints: boxConstraints ??
          BoxConstraints(
              minHeight: formatHeight(190),
              minWidth: formatWidth(315),
              maxHeight: formatHeight(190),
              maxWidth: formatWidth(315)),
      padding: contentPadding ??
          (!variant
              ? EdgeInsets.fromLTRB(formatWidth(19), formatHeight(0),
                  formatWidth(7), formatHeight(13))
              : EdgeInsets.zero),
      decoration: image != null
          ? BoxDecoration(
              image: DecorationImage(image: image, fit: BoxFit.cover),
              borderRadius: BorderRadius.circular(
                  radius ?? themeData.radius ?? formatWidth(10)))
          : BoxDecoration(
              color: backgroundColor ?? const Color(0xFF02132B),
              borderRadius: BorderRadius.circular(
                  radius ?? themeData.radius ?? formatWidth(10)),
            ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            borderRadius: BorderRadius.circular(
                radius ?? themeData.radius ?? formatWidth(10)),
            child: Stack(
                children: !variant
                    ? [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: titleStyle ??
                                      themeData.titleStyle ??
                                      TextStyle(
                                          fontSize: sp(14),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                  textAlign: TextAlign.left),
                              Text(subTitle,
                                  style: subTitleStyle ??
                                      themeData.subTitleStyle ??
                                      TextStyle(
                                          fontSize: sp(10),
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white),
                                  textAlign: TextAlign.left),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                                radius ?? themeData.radius ?? formatWidth(10)),
                            onTap: doublePointonTap,
                            onDoubleTap: doublePointonDoubleTap,
                            child: SizedBox(
                              height: (doublePointSize ??
                                      themeData.doublePointSize ??
                                      Size(formatWidth(23), formatHeight(23)))
                                  .height,
                              width: (doublePointSize ??
                                      themeData.doublePointSize ??
                                      Size(formatWidth(23), formatHeight(23)))
                                  .width,
                              child: doublePointWidget ??
                                  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: formatHeight(3),
                                          width: formatWidth(3),
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white),
                                        ),
                                        SizedBox(height: formatHeight(3)),
                                        Container(
                                          height: formatHeight(3),
                                          width: formatWidth(3),
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white),
                                        ),
                                      ]),
                            ),
                          ),
                        ),
                      ]
                    : [
                        Padding(
                          padding: EdgeInsets.only(
                              left: formatWidth(19), bottom: formatHeight(13)),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              title,
                              style: titleStyle ??
                                  themeData.titleStyle ??
                                  TextStyle(
                                      fontSize: sp(14),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              right: formatWidth(19), bottom: formatHeight(15)),
                          child: Align(
                              alignment: Alignment.bottomRight,
                              child: Text(subTitle,
                                  style: subTitleStyle,
                                  textAlign: TextAlign.left)),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: formatHeight(8), right: formatWidth(9)),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(radius ??
                                  themeData.radius ??
                                  formatWidth(10)),
                              onTap: doublePointonTap,
                              onDoubleTap: doublePointonDoubleTap,
                              child: Container(
                                height: (doublePointSize ??
                                        themeData.doublePointSize ??
                                        Size(formatWidth(23), formatHeight(23)))
                                    .height,
                                width: (doublePointSize ??
                                        themeData.doublePointSize ??
                                        Size(formatWidth(23), formatHeight(23)))
                                    .width,
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle),
                                child: doublePointWidget ??
                                    Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            height: formatHeight(3),
                                            width: formatWidth(3),
                                            decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white),
                                          ),
                                          SizedBox(height: formatHeight(3)),
                                          Container(
                                            height: formatHeight(3),
                                            width: formatWidth(3),
                                            decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white),
                                          ),
                                        ]),
                              ),
                            ),
                          ),
                        ),
                      ])),
      ),
    );
  }
}

class _Nine extends StatelessWidget implements Cards {
  final String title;
  final String subTitle;
  final String desc;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final TextStyle? descStyle;
  final BoxConstraints? boxConstraints;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double? radius;
  final Color? backgroundColor;
  final EdgeInsets? paddingImage;
  final EdgeInsets? paddingText;
  final Widget? doublePointWidget;
  final EdgeInsets? doublePointPadding;
  final Size? doublePointSize;
  final VoidCallback? doublePointonTap;
  final VoidCallback? doublePointonDoubleTap;
  final ImageProvider? imageProvider;
  final Widget? imageWidget;
  final CustomCardsThemeData? theme;
  final String? themeName;

  const _Nine({
    this.title = 'Titre',
    this.subTitle = 'Sous-titre',
    this.desc =
        '',
    this.titleStyle,
    this.subTitleStyle,
    this.descStyle,
    this.boxConstraints,
    this.onTap,
    this.onDoubleTap,
    this.radius,
    this.backgroundColor,
    this.paddingImage,
    this.paddingText,
    this.doublePointWidget,
    this.doublePointPadding,
    this.doublePointSize,
    this.doublePointonTap,
    this.doublePointonDoubleTap,
    this.imageProvider,
    this.imageWidget,
    this.theme,
    this.themeName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, themeName ?? "cards_nine", () => const CustomCardsThemeData());

    return Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: boxConstraints ??
              BoxConstraints(
                  minHeight: formatHeight(125),
                  minWidth: formatWidth(315),
                  maxHeight: formatHeight(125),
                  maxWidth: formatWidth(315)),
          decoration: BoxDecoration(
            color: backgroundColor ?? themeData.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(
                radius ?? themeData.radius ?? formatWidth(10)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                borderRadius: BorderRadius.circular(
                    radius ?? themeData.radius ?? formatWidth(10)),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: paddingImage ??
                              themeData.paddingImage ??
                              EdgeInsets.only(
                                  left: formatWidth(7),
                                  bottom: formatHeight(6),
                                  top: formatHeight(6)),
                          child: imageWidget ??
                              Container(
                                width: formatWidth(120),
                                decoration: imageProvider != null
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            radius ??
                                                themeData.radius ??
                                                formatWidth(10)),
                                        image: DecorationImage(
                                            image: imageProvider!),
                                      )
                                    : BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            radius ??
                                                themeData.radius ??
                                                formatWidth(10)),
                                        color: const Color(0xFF02132B),
                                      ),
                              ),
                        ),
                        sw(5),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(formatWidth(16)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: titleStyle ??
                                          themeData.titleStyle ??
                                          TextStyle(
                                              fontSize: sp(13),
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF02132B)),
                                      textAlign: TextAlign.left),
                                  const Spacer(),
                                  Text(subTitle,
                                      style: subTitleStyle ??
                                          themeData.subTitleStyle ??
                                          TextStyle(
                                              fontSize: sp(10),
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF5A6575)),
                                      textAlign: TextAlign.left),
                                  const Spacer(),
                                  Text(desc,
                                      style: descStyle ??
                                          themeData.descStyle ??
                                          TextStyle(
                                              fontSize: sp(12),
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF02132B)),
                                      textAlign: TextAlign.left),
                                ]),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: doublePointPadding ??
                            themeData.paddingDoublePoint ??
                            EdgeInsets.only(
                                top: formatHeight(7), right: formatWidth(3)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                              radius ?? themeData.radius ?? formatWidth(10)),
                          onTap: doublePointonTap,
                          onDoubleTap: doublePointonDoubleTap,
                          child: SizedBox(
                            height: (doublePointSize ??
                                    themeData.doublePointSize ??
                                    Size(formatWidth(23), formatHeight(23)))
                                .height,
                            width: (doublePointSize ??
                                    themeData.doublePointSize ??
                                    Size(formatWidth(23), formatHeight(23)))
                                .width,
                            child: doublePointWidget ??
                                Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: formatHeight(3),
                                        width: formatWidth(3),
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF9199A7)),
                                      ),
                                      sh(3),
                                      Container(
                                        height: formatHeight(3),
                                        width: formatWidth(3),
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF9199A7)),
                                      ),
                                    ]),
                          ),
                        ),
                      ),
                    )
                  ],
                )),
          ),
        ));
  }
}
