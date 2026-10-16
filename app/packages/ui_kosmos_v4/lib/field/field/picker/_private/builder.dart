// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import "package:dartz/dartz.dart" as dz;
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

Widget buildEmptyPickerContent(String text, bool isDark, Color? color) {
  late final themeData = loadThemeData(
      null, "form_field", () => const FormFieldThemeData(),
      isDark: isDark);
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
            child: SvgPicture.asset("assets/svg/ic_upload.svg",
                package: "ui_kosmos_v4", color: color)),
        sh(7),
        Text(
          text,
          style: (themeData?.fieldTextStyle ??
                  DefaultAppStyle.grey(13, FontWeight.w500))
              .copyWith(color: color),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget buildPickedImage(
  BuildContext context,
  bool isDark,
  List<dz.Either<PlatformFile, XFile>> file,
  void Function(int)? onRemoveItem,
  double imageHeight, [
  String? select,
  Color? color,
]) {
  final bool canRemove = onRemoveItem != null;
  late final themeData = loadThemeData(
      null, "form_field", () => const FormFieldThemeData(),
      isDark: isDark);

  select ??= "package.ui-kosmos_v4.field.input.choose-image";

  final first = file.first;
  final c = first.fold(
    (l) {
      if (l.bytes == null)
        return const Center(child: Icon(Icons.error_outline_rounded));

      Uint8List bytes = l.bytes!;
      String base64Image = base64Encode(bytes);
      return Html(
        data: '<img src="data:image/png;base64,$base64Image"/>',
      );

      // return l.bytes != null ? Image.file(File.fromRawPath(l.bytes!), fit: BoxFit.cover) : const Center(child: Icon(Icons.error_outline_rounded));
    },
    (r) => Image.file(File(r.path), fit: BoxFit.cover),
  );

  return Row(
    mainAxisSize: MainAxisSize.max,
    children: [
      SizedBox(
        height: imageHeight,
        width: formatWidth(81),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(r(5)),
                child: c,
              ),
            ),
            if (canRemove)
              Positioned(
                top: -formatWidth(4),
                right: -formatWidth(4),
                child: InkWell(
                  onTap: () => onRemoveItem.call(0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(formatWidth(12)),
                      color: DefaultColor.error,
                    ),
                    width: formatWidth(14),
                    height: formatWidth(14),
                    child: Center(
                        child: Icon(Icons.close_rounded,
                            color: (themeData?.fieldTextStyle?.color) ??
                                Colors.white,
                            size: formatWidth(10))),
                  ),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SvgPicture.asset(
              "assets/svg/ic_upload.svg",
              package: "ui_kosmos_v4",
              color: color ?? DefaultColor.grey,
            ),
            sh(7),
            Text(
              select.tr(),
              style: themeData?.fieldTextStyle ??
                  DefaultAppStyle.grey(13, FontWeight.w500)
                      .copyWith(color: color),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget buildInitialImage(
  BuildContext context,
  bool isDark,
  List<String> file,
  void Function(int)? onRemoveItem,
  double imageHeight, [
  String? select,
  Color? color,
]) {
  final bool canRemove = onRemoveItem != null;
  late final themeData = loadThemeData(
    null,
    "form_field",
    () => const FormFieldThemeData(),
    isDark: isDark,
  );

  select ??= "package.ui-kosmos_v4.field.input.choose-image";

  final first = file.first;
  final c = kIsWeb
      ? Image.network(
          first,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.error_outline_rounded)),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: LoaderClassique());
          },
        )
      : CachedNetworkImage(
          imageUrl: first,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              const Center(child: Icon(Icons.error_outline_rounded)),
          placeholder: (_, __) => const Center(child: LoaderClassique()),
        );

  return Row(
    mainAxisSize: MainAxisSize.max,
    children: [
      SizedBox(
        height: imageHeight,
        width: formatWidth(81),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(r(5)),
                child: c,
              ),
            ),
            if (canRemove)
              Positioned(
                top: -formatWidth(4),
                right: -formatWidth(4),
                child: InkWell(
                  onTap: () => onRemoveItem.call(0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(formatWidth(12)),
                      color: DefaultColor.error,
                    ),
                    width: formatWidth(14),
                    height: formatWidth(14),
                    child: Center(
                        child: Icon(Icons.close_rounded,
                            color: (themeData?.fieldTextStyle?.color) ??
                                Colors.white,
                            size: formatWidth(10))),
                  ),
                ),
              ),
          ],
        ),
      ),
      const Spacer(),
      SizedBox(
        width: formatWidth(152),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SvgPicture.asset(
              "assets/svg/ic_upload.svg",
              package: "ui_kosmos_v4",
              color: color ?? DefaultColor.grey,
            ),
            sh(7),
            Text(
              select.tr(),
              style: themeData?.fieldTextStyle ??
                  DefaultAppStyle.grey(13, FontWeight.w500)
                      .copyWith(color: color),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget buildInitialMedia(
  BuildContext context,
  bool isDark,
  List<MediaModel> file,
  void Function(int)? onRemoveItem,
  double imageHeight, [
  String? select,
  Color? color,
]) {
  final bool canRemove = onRemoveItem != null;
  late final themeData = loadThemeData(
      null, "form_field", () => const FormFieldThemeData(),
      isDark: isDark);

  select ??= "package.ui-kosmos_v4.field.input.choose-image";

  final first = file.firstWhere(
      (element) => element.mediaUrl != null || element.videoThumbnail != null);
  final c = kIsWeb
      ? Image.network(
          first.mediaUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.error_outline_rounded)),
          loadingBuilder: (_, __, ___) =>
              const Center(child: LoaderClassique()),
        )
      : CachedNetworkImage(
          imageUrl: first.mediaUrl!,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              const Center(child: Icon(Icons.error_outline_rounded)),
          placeholder: (_, __) => const Center(child: LoaderClassique()),
        );

  return Row(
    mainAxisSize: MainAxisSize.max,
    children: [
      SizedBox(
        height: imageHeight,
        width: formatWidth(81),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(r(5)),
                child: c,
              ),
            ),
            if (canRemove)
              Positioned(
                top: -formatWidth(4),
                right: -formatWidth(4),
                child: InkWell(
                  onTap: () => onRemoveItem.call(0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(formatWidth(12)),
                      color: DefaultColor.error,
                    ),
                    width: formatWidth(14),
                    height: formatWidth(14),
                    child: Center(
                        child: Icon(Icons.close_rounded,
                            color: (themeData?.fieldTextStyle?.color) ??
                                Colors.white,
                            size: formatWidth(10))),
                  ),
                ),
              ),
          ],
        ),
      ),
      const Spacer(),
      SizedBox(
        width: formatWidth(152),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SvgPicture.asset(
              "assets/svg/ic_upload.svg",
              package: "ui_kosmos_v4",
              color: color ?? DefaultColor.grey,
            ),
            sh(7),
            Text(
              select.tr(),
              style: themeData?.fieldTextStyle ??
                  DefaultAppStyle.grey(13, FontWeight.w500)
                      .copyWith(color: color),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget buildFileNameList(BuildContext context, bool isDark, List<String> name,
    void Function(int)? onRemoveItem,
    [Color? color]) {
  late final themeData = loadThemeData(
      null, "form_field", () => const FormFieldThemeData(),
      isDark: isDark);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          SvgPicture.asset(
            "assets/svg/ic_upload.svg",
            package: "ui_kosmos_v4",
            color: color ?? DefaultColor.grey,
          ),
          sw(12),
          Expanded(
            child: Text(
              "package.ui-kosmos_v4.field.input.press-to-modify".tr(),
              style: themeData?.inputDecoration?.hintStyle ??
                  themeData?.fieldTextStyle ??
                  DefaultAppStyle.darkBlue(13, FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      sh(10),
      const Divider(),
      sh(9),
      ...name.map(
        (e) => Row(
          children: [
            Expanded(
              child: Text(
                e,
                style: themeData?.fieldTextStyle ??
                    DefaultAppStyle.darkBlue(13, FontWeight.w400),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            sh(10),
            InkWell(
              onTap: () => onRemoveItem?.call(name.indexOf(e)),
              child: Icon(Icons.close_rounded,
                  color: (themeData?.fieldTextStyle?.color) ??
                      DefaultColor.darkBlue,
                  size: 20),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget buildMediaEntityList(
  BuildContext context,
  bool isDark,
  List<AssetEntity> assets,
  void Function(int)? onRemoveItem,
  double imageHeight, [
  String? select,
  Color? color,
]) {
  final bool canRemove = onRemoveItem != null;
  late final themeData = loadThemeData(
    null,
    "form_field",
    () => const FormFieldThemeData(),
    isDark: isDark,
  );

  select ??= "package.ui-kosmos_v4.field.input.choose-media";
  final first = assets.first;

  return Row(
    mainAxisSize: MainAxisSize.max,
    children: [
      SizedBox(
        height: imageHeight,
        width: formatWidth(81),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(r(5)),
                child: AssetEntityImage(first, fit: BoxFit.cover),
              ),
            ),
            if (first.type == AssetType.video)
              Center(
                  child: Icon(Icons.play_arrow_rounded,
                      color: (themeData?.fieldTextStyle?.color) ?? Colors.white,
                      size: formatWidth(32))),
            if (canRemove)
              Positioned(
                top: -formatWidth(4),
                right: -formatWidth(4),
                child: InkWell(
                  onTap: () => onRemoveItem.call(0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(formatWidth(12)),
                      color: DefaultColor.error,
                    ),
                    width: formatWidth(14),
                    height: formatWidth(14),
                    child: Center(
                        child: Icon(Icons.close_rounded,
                            color: (themeData?.fieldTextStyle?.color) ??
                                Colors.white,
                            size: formatWidth(10))),
                  ),
                ),
              ),
          ],
        ),
      ),
      const Spacer(),
      SizedBox(
        width: formatWidth(152),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SvgPicture.asset(
              "assets/svg/ic_upload.svg",
              package: "ui_kosmos_v4",
              color: color ?? DefaultColor.grey,
            ),
            sh(7),
            Text(
              select.tr(),
              style: DefaultAppStyle.grey(13, FontWeight.w500)
                  .copyWith(color: color),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    ],
  );
}
