import 'package:auto_size_text/auto_size_text.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/_deprecated/header/theme.dart';

abstract class Header extends StatelessWidget {
  const factory Header.primary({
    final String title,
    final TextStyle titleStyle,
    final ImageProvider? imageProvider,
    final Icon? icon,
    final bool reverse,
    final EdgeInsets contentPadding,
    final Color backgroundColor,
    final CustomHeadersThemeData? theme,
    final String? themeName,
  }) = _Primary;

  const factory Header.secondary({
    final ImageProvider? imageProvider,
    final String title,
    final String title_2,
    final String subTitle,
    final TextStyle subTitleStyle,
    final TextStyle titleStyle,
    final TextStyle title2Style,
    final bool reverse,
    final EdgeInsets contentPadding,
    final Color backgroundColor,
    final CustomHeadersThemeData? theme,
    final String? themeName,
  }) = _Secondary;

  const factory Header.third({
    final EdgeInsets contentPadding,
    final Color backgroundColor,
    final VoidCallback? onTapBack,
    final VoidCallback? onTapIcon,
    final VoidCallback? onDoubleTapBack,
    final VoidCallback? onDoubleTapIcon,
    final Icon? backIcon,
    final Icon? customIcon,
    final String title,
    final TextStyle titleStyle,
    final CustomHeadersThemeData? theme,
    final String? themeName,
  }) = _Third;
}

class _Primary extends StatelessWidget implements Header {
  final String title;
  final TextStyle? titleStyle;
  final ImageProvider? imageProvider;
  final Icon? icon;
  final bool reverse;
  final EdgeInsets? contentPadding;
  final Color? backgroundColor;
  final CustomHeadersThemeData? theme;
  final String? themeName;
  const _Primary(
      {this.title = 'Découvrir',
      this.titleStyle,
      this.imageProvider,
      this.icon,
      this.reverse = false,
      this.contentPadding,
      this.backgroundColor,
      this.theme,
      this.themeName,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(theme, themeName ?? "headers_one",
        () => const CustomHeadersThemeData());

    return Container(
      constraints: const BoxConstraints(minHeight: 77, maxHeight: 77),
      padding: contentPadding ??
          themeData.contentPadding ??
          const EdgeInsets.fromLTRB(23, 24, 23, 13),
      color: backgroundColor ?? themeData.backgroundColor ?? Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: !reverse
            ? [
                Center(
                  child: Text(
                    title,
                    style: titleStyle ??
                        themeData.titleStyle ??
                        const TextStyle(
                            fontSize: 21,
                            color: Color(0xFF02132B),
                            fontWeight: FontWeight.w600),
                  ),
                ),
                Row(
                  children: [
                    icon ?? const SizedBox(),
                    const SizedBox(width: 17),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: imageProvider != null
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                  image: imageProvider!, fit: BoxFit.cover))
                          : const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xFF02132B)),
                    )
                  ],
                ),
              ]
            : [
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: imageProvider != null
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                  image: imageProvider!, fit: BoxFit.cover))
                          : const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xFF02132B)),
                    ),
                    const SizedBox(width: 12),
                    Center(
                      child: Text(
                        title,
                        style: titleStyle ??
                            themeData.titleStyle ??
                            const TextStyle(
                                fontSize: 21,
                                color: Color(0xFF02132B),
                                fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Center(child: icon ?? const SizedBox()),
              ],
      ),
    );
  }
}

class _Secondary extends StatelessWidget implements Header {
  final ImageProvider? imageProvider;
  final String title;
  final String title_2;
  final String? subTitle;
  final TextStyle? subTitleStyle;
  final TextStyle? titleStyle;
  final TextStyle? title2Style;
  final bool reverse;
  final EdgeInsets? contentPadding;
  final Color? backgroundColor;
  final CustomHeadersThemeData? theme;
  final String? themeName;

  const _Secondary(
      {this.reverse = false,
      this.title = 'Bonjour',
      this.title_2 = ', Anna 👋',
      this.subTitle = 'aizuzaui',
      this.subTitleStyle,
      this.imageProvider,
      this.titleStyle,
      this.title2Style,
      this.contentPadding,
      this.backgroundColor,
      this.theme,
      this.themeName,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(theme, themeName ?? "headers_two",
        () => const CustomHeadersThemeData());

    return Container(
      constraints: const BoxConstraints(minHeight: 77, maxHeight: 77),
      padding: contentPadding ??
          themeData.contentPadding ??
          const EdgeInsets.fromLTRB(23, 22, 23, 8),
      color: backgroundColor ?? themeData.backgroundColor ?? Colors.white,
      child: Row(
        mainAxisAlignment:
            reverse ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
        children: !reverse
            ? [
                AutoSizeText.rich(
                  TextSpan(text: 'Bonjour', children: [
                    TextSpan(
                      text: ', Anna 👋',
                      style: title2Style ??
                          themeData.title2Style ??
                          const TextStyle(
                              color: Color(0xFF02132B),
                              fontSize: 21,
                              fontWeight: FontWeight.w600),
                    ),
                    if (subTitle != null && subTitle!.isNotEmpty)
                      TextSpan(
                        text: "\n${subTitle!}",
                        style: subTitleStyle ??
                            themeData.subTitleStyle ??
                            const TextStyle(
                                color: Color(0xFF737D8A),
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                      )
                  ]),
                  style: titleStyle ??
                      themeData.titleStyle ??
                      const TextStyle(
                          color: Color(0xFF02132B),
                          fontSize: 21,
                          fontWeight: FontWeight.w300),
                  minFontSize: 7,
                ),
                Container(
                  height: 40,
                  width: 40,
                  decoration: imageProvider != null
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              image: imageProvider!, fit: BoxFit.cover))
                      : const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF02132B)),
                ),
              ]
            : [
                Container(
                  height: 40,
                  width: 40,
                  decoration: imageProvider != null
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              image: imageProvider!, fit: BoxFit.cover))
                      : const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF02132B)),
                ),
                const SizedBox(width: 14),
                AutoSizeText.rich(
                  TextSpan(text: title, children: [
                    TextSpan(
                      text: title_2,
                      style: title2Style ??
                          themeData.title2Style ??
                          const TextStyle(
                              color: Color(0xFF02132B),
                              fontSize: 21,
                              fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: "\n$subTitle",
                      style: subTitleStyle ??
                          themeData.subTitleStyle ??
                          const TextStyle(
                              color: Color(0xFF737D8A),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                    ),
                  ]),
                  style: titleStyle ??
                      themeData.titleStyle ??
                      const TextStyle(
                          color: Color(0xFF02132B),
                          fontSize: 21,
                          fontWeight: FontWeight.w300),
                  minFontSize: 7,
                ),
              ],
      ),
    );
  }
}

class _Third extends StatelessWidget implements Header {
  final EdgeInsets? contentPadding;
  final Color? backgroundColor;
  final VoidCallback? onTapBack;
  final VoidCallback? onTapIcon;
  final VoidCallback? onDoubleTapBack;
  final VoidCallback? onDoubleTapIcon;
  final Icon? backIcon;
  final Icon? customIcon;
  final String title;
  final TextStyle? titleStyle;
  final CustomHeadersThemeData? theme;
  final String? themeName;
  const _Third(
      {this.onTapBack,
      this.onTapIcon,
      this.onDoubleTapBack,
      this.onDoubleTapIcon,
      this.backgroundColor,
      this.backIcon,
      this.customIcon,
      this.contentPadding,
      this.title = 'Titre',
      this.titleStyle,
      this.theme,
      this.themeName,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(theme, themeName ?? "headers_three",
        () => const CustomHeadersThemeData());

    return Container(
      constraints: const BoxConstraints(minHeight: 77, maxHeight: 77),
      padding: contentPadding ??
          themeData.contentPadding ??
          const EdgeInsets.fromLTRB(9, 22, 9, 9),
      color: backgroundColor ?? themeData.backgroundColor ?? Colors.white,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        onTapBack != null
            ? Material(
                type: MaterialType.transparency,
                child: Container(
                    height: 43,
                    width: 43,
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14)),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        splashColor: Colors.black38,
                        borderRadius: BorderRadius.circular(14),
                        onTap: onTapBack,
                        onDoubleTap: onDoubleTapBack,
                        child: backIcon ?? const Icon(Icons.arrow_back_ios_new),
                      ),
                    )))
            : const SizedBox(),
        Text(
          'Titre',
          style: titleStyle ??
              themeData.titleStyle ??
              const TextStyle(
                  color: Color(0xFF02132B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
        ),
        onTapIcon != null
            ? Material(
                type: MaterialType.transparency,
                child: Container(
                    height: 43,
                    width: 43,
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14)),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        splashColor: Colors.black38,
                        borderRadius: BorderRadius.circular(14),
                        onTap: onTapIcon,
                        onDoubleTap: onDoubleTapIcon,
                        child: customIcon ??
                            const Icon(
                              Icons.add,
                              size: 32,
                            ),
                      ),
                    )))
            : const SizedBox(),
      ]),
    );
  }
}
