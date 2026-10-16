// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_kosmos_v4/_deprecated/form/theme.dart';

abstract class Input extends HookWidget {
  final double? height;
  final String? fieldName;
  final TextStyle? fieldNameStyle;
  final String? fieldPostRedirection;
  final TextStyle? fieldPostRedirectionStyle;
  final VoidCallback? postFieldOnClick;
  final Widget? child;
  final String? svgIconPath;
  final bool? pdfOnly;
  final VoidCallback? onTap;
  final VoidCallback? onTapFieldName;
  final VoidCallback? onDoubleTap;
  final PlatformFile? image;
  final BoxDecoration? boxDecoration;
  final double? inkRadius;
  final EdgeInsets? contentPadding;
  final double? imageRadius;
  final TextStyle? textStyle;
  final Color? iconColor;
  final double? widthImage;
  final String? contentTitle;

  final CustomFormFieldThemeData? theme;

  final List<FileNameItem>? listNameFiles;
  final Function(PlatformFile?)? onChanged;
  final PlatformFile? defaultFile;
  final List<PlatformFile>? defaultFileList;
  final Function(List<PlatformFile>?)? onMultipleChanged;

  final String? desc;
  final Widget? header;
  final Widget? footer;
  final bool? isValid;
  final File? imageMobile;
  final String? urlImage;
  final String? defaultFileName;

  final List<PlatformFile>? defaultFiles;

  const Input({
    this.theme,
    this.height,
    this.child,
    this.pdfOnly,
    this.svgIconPath,
    this.onTap,
    this.onTapFieldName,
    this.onDoubleTap,
    this.image,
    this.boxDecoration,
    this.inkRadius,
    this.contentPadding,
    this.imageRadius,
    this.textStyle,
    this.iconColor,
    this.contentTitle,
    this.widthImage,
    this.urlImage,
    this.listNameFiles,
    this.fieldName,
    this.fieldNameStyle,
    this.defaultFileName,
    this.fieldPostRedirection,
    this.fieldPostRedirectionStyle,
    this.postFieldOnClick,
    this.defaultFile,
    this.onChanged,
    this.defaultFileList,
    this.onMultipleChanged,
    this.desc,
    this.footer,
    this.header,
    this.defaultFiles,
    this.isValid,
    this.imageMobile,
    Key? key,
  }) : super(key: key);

  const factory Input.image({
    final double? height,
    final String? svgIconPath,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final VoidCallback? onTap,
    final VoidCallback? onTapFieldName,
    final String? urlImage,
    final VoidCallback? onDoubleTap,
    final PlatformFile? image,
    final BoxDecoration? boxDecoration,
    final double? inkRadius,
    final EdgeInsets? contentPadding,
    final double? imageRadius,
    final TextStyle? textStyle,
    final Color? iconColor,
    final double? widthImage,
    final CustomFormFieldThemeData? theme,
    final Function(PlatformFile?)? onChanged,
    final PlatformFile? defaultFile,
    final File? imageMobile,
    final Widget? child,
    final String? contentTitle,
  }) = _OneImage;

  const factory Input.files({
    final String? svgIconPath,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final BoxDecoration? boxDecoration,
    final double? inkRadius,
    final EdgeInsets? contentPadding,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final TextStyle? textStyle,
    final Color? iconColor,
    final List<FileNameItem>? listNameFiles,
    final CustomFormFieldThemeData? theme,
    final List<PlatformFile>? defaultFileList,
    final Function(List<PlatformFile>?)? onMultipleChanged,
    final String? contentTitle,
  }) = _MultipleFile;

  const factory Input.validatedFile({
    final String? svgIconPath,
    final VoidCallback? onTap,
    final bool? pdfOnly,
    final VoidCallback? onDoubleTap,
    final BoxDecoration? boxDecoration,
    final double? inkRadius,
    final EdgeInsets? contentPadding,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final TextStyle? textStyle,
    final Color? iconColor,
    final String? contentTitle,
    final double? widthImage,
    final CustomFormFieldThemeData? theme,
    final Function(PlatformFile?)? onChanged,
    final List<PlatformFile>? defaultFiles,
    final String? desc,
    final Widget? header,
    final Widget? footer,
    final double? height,
    final bool? isValid,
    final PlatformFile? defaultFile,
    final String? defaultFileName,
  }) = _ValidatedFile;

  @override
  Widget build(BuildContext context) => Container();
}

class _OneImage extends Input {
  const _OneImage({
    final double? height,
    final String? svgIconPath,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final String? urlImage,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final VoidCallback? onTap,
    final VoidCallback? onTapFieldName,
    final VoidCallback? onDoubleTap,
    final PlatformFile? image,
    final BoxDecoration? boxDecoration,
    final double? inkRadius,
    final EdgeInsets? contentPadding,
    final double? imageRadius,
    final TextStyle? textStyle,
    final Color? iconColor,
    final double? widthImage,
    final Widget? child,
    final CustomFormFieldThemeData? theme,
    final Function(PlatformFile?)? onChanged,
    final PlatformFile? defaultFile,
    final File? imageMobile,
    final String? contentTitle,
  }) : super(
          height: height,
          svgIconPath: svgIconPath,
          onTap: onTap,
          onTapFieldName: onTapFieldName,
          onDoubleTap: onDoubleTap,
          image: image,
          urlImage: urlImage,
          boxDecoration: boxDecoration,
          inkRadius: inkRadius,
          contentPadding: contentPadding,
          imageRadius: imageRadius,
          textStyle: textStyle,
          child: child,
          iconColor: iconColor,
          widthImage: widthImage,
          fieldName: fieldName,
          fieldNameStyle: fieldNameStyle,
          fieldPostRedirection: fieldPostRedirection,
          fieldPostRedirectionStyle: fieldPostRedirectionStyle,
          postFieldOnClick: postFieldOnClick,
          theme: theme,
          onChanged: onChanged,
          defaultFile: defaultFile,
          imageMobile: imageMobile,
          contentTitle: contentTitle,
        );
  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, "input_field", () => const CustomFormFieldThemeData());
    final state = useState<PlatformFile?>(defaultFile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            fieldName != null
                ? InkWell(
                    onTap: onTapFieldName,
                    child: Text(
                      fieldName!,
                      style: fieldNameStyle ??
                          themeData.fieldNameStyle ??
                          const TextStyle(
                              color: Color(0xFF02132B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                    ),
                  )
                : Container(),
            fieldPostRedirection == null ? const SizedBox() : const Spacer(),
            fieldPostRedirection == null
                ? const SizedBox()
                : InkWell(
                    onTap: postFieldOnClick,
                    child: Text(
                      fieldPostRedirection!,
                      style: fieldPostRedirectionStyle ??
                          themeData.fieldPostRedirectionStyle ??
                          const TextStyle(
                            color: Color(0xFF02132B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                    )),
          ],
        ),
        sh(7),
        Material(
            type: MaterialType.transparency,
            child: Container(
              height: formatHeight(height ?? themeData.pickerHeight ?? 108),
              constraints: themeData.pickerConstraints,
              decoration: boxDecoration ??
                  themeData.pickerDecoration ??
                  BoxDecoration(
                    color: themeData.backgroundColor ??
                        const Color(0xFF02132B).withOpacity(0.03),
                    borderRadius:
                        BorderRadius.circular(themeData.selectRadius ?? 7),
                  ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                    borderRadius: BorderRadius.circular(inkRadius ?? 7),
                    onTap: () {
                      if (onTap != null) onTap!();
                      if (onChanged != null) onChanged!(state.value);
                    },
                    onDoubleTap: onDoubleTap,
                    child: Padding(
                      padding: state.value != null ||
                              imageMobile != null ||
                              urlImage != null
                          ? (contentPadding ??
                              themeData.contentPadding ??
                              const EdgeInsets.fromLTRB(7, 6, 30, 6))
                          : EdgeInsets.zero,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: state.value != null ||
                                imageMobile != null ||
                                urlImage != null ||
                                image != null ||
                                child != null
                            ? [
                                state.value != null
                                    ? Container(
                                        child: Image.file(File.fromRawPath(
                                            state.value!.bytes!)),
                                        width: formatWidth(widthImage ??
                                            themeData.pickerImageWidth ??
                                            81),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              imageRadius ??
                                                  themeData.pickerImageRadius ??
                                                  5),
                                        ),
                                      )
                                    : child != null
                                        ? Container(
                                            child: child,
                                            width: formatWidth(widthImage ??
                                                themeData.pickerImageWidth ??
                                                81),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius
                                                  .circular(imageRadius ??
                                                      themeData
                                                          .pickerImageRadius ??
                                                      5),
                                            ),
                                          )
                                        : imageMobile != null
                                            ? Container(
                                                width: formatWidth(widthImage ??
                                                    themeData
                                                        .pickerImageWidth ??
                                                    81),
                                                decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      image: FileImage(
                                                          imageMobile!),
                                                      fit: BoxFit.cover),
                                                  borderRadius: BorderRadius
                                                      .circular(imageRadius ??
                                                          themeData
                                                              .pickerImageRadius ??
                                                          5),
                                                ),
                                              )
                                            : image != null
                                                ? SizedBox(
                                                    width: formatWidth(widthImage ??
                                                        themeData
                                                            .pickerImageWidth ??
                                                        81),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius
                                                          .circular(imageRadius ??
                                                              themeData
                                                                  .pickerImageRadius ??
                                                              5),
                                                      child: Image.memory(
                                                          image!.bytes!),
                                                    ))
                                                : SizedBox(
                                                    width: formatWidth(widthImage ??
                                                        themeData
                                                            .pickerImageWidth ??
                                                        81),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius
                                                          .circular(imageRadius ??
                                                              themeData
                                                                  .pickerImageRadius ??
                                                              5),
                                                      child: CachedNetworkImage(
                                                        imageUrl: urlImage!,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      svgIconPath == null
                                          ? Icon(
                                              Icons.cloud_upload_outlined,
                                              color: iconColor ??
                                                  themeData.pickerIconColor ??
                                                  const Color(0xFF02132B)
                                                      .withOpacity(0.41),
                                            )
                                          : SvgPicture.asset(
                                              svgIconPath!,
                                              color: iconColor ??
                                                  themeData.pickerIconColor ??
                                                  const Color(0xFF02132B)
                                                      .withOpacity(0.41),
                                            ),
                                      const SizedBox(height: 7),
                                      SizedBox(
                                          width: 120,
                                          child: Text(
                                            'Appuyez pour modifier la photo',
                                            textAlign: TextAlign.right,
                                            style: textStyle ??
                                                themeData.hintStyle ??
                                                TextStyle(
                                                    fontSize: sp(13),
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        const Color(0xFF02132B)
                                                            .withOpacity(0.41)),
                                          )),
                                    ],
                                  ),
                                ),
                              ]
                            : [
                                Align(
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      svgIconPath == null
                                          ? Icon(
                                              Icons.cloud_upload_outlined,
                                              color: iconColor ??
                                                  themeData.pickerIconColor ??
                                                  const Color(0xFF02132B)
                                                      .withOpacity(0.41),
                                            )
                                          : SvgPicture.asset(
                                              svgIconPath!,
                                              color: iconColor ??
                                                  themeData.pickerIconColor ??
                                                  const Color(0xFF02132B)
                                                      .withOpacity(0.41),
                                            ),
                                      sh(7),
                                      Text(
                                        contentTitle ??
                                            'Appuyez pour choisir une photo',
                                        textAlign: TextAlign.center,
                                        style: textStyle ??
                                            themeData.hintStyle ??
                                            TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF02132B)
                                                  .withOpacity(0.41),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                      ),
                    )),
              ),
            )),
      ],
    );
  }
}

class _MultipleFile extends Input {
  const _MultipleFile({
    final String? svgIconPath,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final BoxDecoration? boxDecoration,
    final double? inkRadius,
    final EdgeInsets? contentPadding,
    final TextStyle? textStyle,
    final Color? iconColor,
    final List<FileNameItem>? listNameFiles,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final CustomFormFieldThemeData? theme,
    final List<PlatformFile>? defaultFileList,
    final Function(List<PlatformFile>?)? onMultipleChanged,
    final String? contentTitle,
  }) : super(
          svgIconPath: svgIconPath,
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          boxDecoration: boxDecoration,
          inkRadius: inkRadius,
          contentPadding: contentPadding,
          textStyle: textStyle,
          iconColor: iconColor,
          listNameFiles: listNameFiles,
          fieldName: fieldName,
          fieldNameStyle: fieldNameStyle,
          fieldPostRedirection: fieldPostRedirection,
          fieldPostRedirectionStyle: fieldPostRedirectionStyle,
          postFieldOnClick: postFieldOnClick,
          theme: theme,
          defaultFileList: defaultFileList,
          onMultipleChanged: onMultipleChanged,
          contentTitle: contentTitle,
        );
  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, "input_field", () => const CustomFormFieldThemeData());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            fieldName != null
                ? Text(
                    fieldName!,
                    style: fieldNameStyle ??
                        themeData.fieldNameStyle ??
                        const TextStyle(
                            color: Color(0xFF02132B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                  )
                : Container(),
            fieldPostRedirection == null ? const SizedBox() : const Spacer(),
            fieldPostRedirection == null
                ? const SizedBox()
                : InkWell(
                    onTap: postFieldOnClick,
                    child: Text(
                      fieldPostRedirection!,
                      style: fieldPostRedirectionStyle ??
                          themeData.fieldPostRedirectionStyle ??
                          const TextStyle(
                            color: Color(0xFF02132B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                    )),
          ],
        ),
        sh(7),
        Material(
            // type: MaterialType.transparency,
            child: Container(
          constraints: themeData.pickerConstraints ??
              const BoxConstraints(minHeight: 108),
          decoration: boxDecoration ??
              themeData.pickerDecoration ??
              BoxDecoration(
                  color: themeData.backgroundColor ??
                      const Color(0xFF02132B).withOpacity(0.03),
                  borderRadius: BorderRadius.circular(7)),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
                borderRadius: BorderRadius.circular(inkRadius ?? 7),
                onTap: () {
                  if (onTap != null) onTap!();
                  // if (onMultipleChanged != null) onMultipleChanged!(state.value);
                },
                onDoubleTap: onDoubleTap,
                child: Padding(
                  padding: contentPadding ??
                      themeData.contentPadding ??
                      const EdgeInsets.fromLTRB(26, 6, 26, 6),
                  child: Stack(
                    alignment: Alignment.center,
                    children: (defaultFileList != null &&
                            defaultFileList!.isNotEmpty)
                        ? [
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: defaultFileList != null
                                    ? [
                                        ...defaultFileList!.map((e) {
                                          return Row(
                                            children: [
                                              FileNameItem(
                                                fileName: e.name,
                                                onClear: () {
                                                  if (defaultFileList == null)
                                                    return;
                                                  List<PlatformFile>? tmp =
                                                      List.from(
                                                          defaultFileList!);
                                                  if ((tmp.length) == 1) {
                                                    tmp = null;
                                                    if (onMultipleChanged !=
                                                        null)
                                                      onMultipleChanged!(tmp);
                                                    return;
                                                  }
                                                  List<PlatformFile>? ret = [];
                                                  for (final t in tmp) {
                                                    if (e != t) ret.add(t);
                                                  }
                                                  tmp = ret;
                                                  if (onMultipleChanged != null)
                                                    onMultipleChanged!(tmp);
                                                },
                                              ),
                                              sw(3),
                                            ],
                                          );
                                        }).toList(),
                                        SizedBox(
                                          width: 200,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                svgIconPath == null
                                                    ? Icon(
                                                        Icons
                                                            .cloud_upload_outlined,
                                                        color: iconColor ??
                                                            themeData
                                                                .pickerIconColor ??
                                                            const Color(
                                                                    0xFF02132B)
                                                                .withOpacity(
                                                                    0.41),
                                                      )
                                                    : SvgPicture.asset(
                                                        svgIconPath!,
                                                        color: iconColor ??
                                                            themeData
                                                                .pickerIconColor ??
                                                            const Color(
                                                                    0xFF02132B)
                                                                .withOpacity(
                                                                    0.41),
                                                      ),
                                                sh(7),
                                                SizedBox(
                                                  width: 100,
                                                  child: Text(
                                                    'Appuyez pour modifier la / les fichier(s)',
                                                    textAlign: TextAlign.center,
                                                    style: textStyle ??
                                                        themeData.fieldStyle ??
                                                        TextStyle(
                                                            fontSize: sp(13),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: const Color(
                                                                    0xFF02132B)
                                                                .withOpacity(
                                                                    0.41)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ]
                                    : [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            svgIconPath == null
                                                ? Icon(
                                                    Icons.cloud_upload_outlined,
                                                    color: iconColor ??
                                                        themeData
                                                            .pickerIconColor ??
                                                        const Color(0xFF02132B)
                                                            .withOpacity(0.41),
                                                  )
                                                : SvgPicture.asset(
                                                    svgIconPath!,
                                                    color: iconColor ??
                                                        themeData
                                                            .pickerIconColor ??
                                                        const Color(0xFF02132B)
                                                            .withOpacity(0.41),
                                                  ),
                                            sw(7),
                                            Text(
                                              'Appuyez pour choisir une / des fichier(s)',
                                              style: textStyle ??
                                                  themeData.fieldStyle ??
                                                  TextStyle(
                                                    fontSize: sp(13),
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        const Color(0xFF02132B)
                                                            .withOpacity(0.41),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                              ),
                            ),
                          ]
                        : [
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  svgIconPath == null
                                      ? Icon(
                                          Icons.cloud_upload_outlined,
                                          color: iconColor ??
                                              themeData.pickerIconColor ??
                                              const Color(0xFF02132B)
                                                  .withOpacity(0.41),
                                        )
                                      : SvgPicture.asset(
                                          svgIconPath!,
                                          color: iconColor ??
                                              themeData.pickerIconColor ??
                                              const Color(0xFF02132B)
                                                  .withOpacity(0.41),
                                        ),
                                  sh(7),
                                  Text(
                                    contentTitle ??
                                        'Appuyez pour choisir un fichier',
                                    textAlign: TextAlign.center,
                                    style: textStyle ??
                                        themeData.hintStyle ??
                                        TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF02132B)
                                              .withOpacity(0.41),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                  ),
                )),
          ),
        )),
      ],
    );
  }
}

class _ValidatedFile extends Input {
  const _ValidatedFile({
    final String? svgIconPath,
    final bool? pdfOnly,
    final VoidCallback? onTap,
    final VoidCallback? onDoubleTap,
    final BoxDecoration? boxDecoration,
    final double? inkRadius,
    final EdgeInsets? contentPadding,
    final String? fieldName,
    final TextStyle? fieldNameStyle,
    final String? fieldPostRedirection,
    final TextStyle? fieldPostRedirectionStyle,
    final VoidCallback? postFieldOnClick,
    final TextStyle? textStyle,
    final Color? iconColor,
    final double? height,
    final String? contentTitle,
    final double? widthImage,
    final CustomFormFieldThemeData? theme,
    final Function(PlatformFile?)? onChanged,
    final List<PlatformFile>? defaultFiles,
    final PlatformFile? defaultFile,
    final String? defaultFileName,
    final String? desc,
    final Widget? header,
    final Widget? footer,
    final bool? isValid,
  }) : super(
          svgIconPath: svgIconPath,
          onTap: onTap,
          pdfOnly: pdfOnly,
          height: height,
          onDoubleTap: onDoubleTap,
          boxDecoration: boxDecoration,
          inkRadius: inkRadius,
          contentPadding: contentPadding,
          fieldName: fieldName,
          fieldNameStyle: fieldNameStyle,
          fieldPostRedirection: fieldPostRedirection,
          fieldPostRedirectionStyle: fieldPostRedirectionStyle,
          postFieldOnClick: postFieldOnClick,
          textStyle: textStyle,
          iconColor: iconColor,
          contentTitle: contentTitle,
          widthImage: widthImage,
          theme: theme,
          onChanged: onChanged,
          defaultFiles: defaultFiles,
          desc: desc,
          header: header,
          defaultFile: defaultFile,
          footer: footer,
          isValid: isValid,
          defaultFileName: defaultFileName,
        );

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
        theme, "input_field", () => const CustomFormFieldThemeData());
    final state = useState<PlatformFile?>(defaultFile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            fieldName != null
                ? Expanded(
                    child: Text(
                      fieldName!,
                      style: fieldNameStyle ??
                          themeData.fieldNameStyle ??
                          const TextStyle(
                              color: Color(0xFF02132B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                    ),
                  )
                : Container(),
            fieldPostRedirection == null ? const SizedBox() : const Spacer(),
            fieldPostRedirection == null
                ? const SizedBox()
                : InkWell(
                    onTap: postFieldOnClick,
                    child: Text(
                      fieldPostRedirection!,
                      style: fieldPostRedirectionStyle ??
                          themeData.fieldPostRedirectionStyle ??
                          const TextStyle(
                            color: Color(0xFF02132B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                    )),
          ],
        ),
        sh(7),
        Material(
            type: MaterialType.transparency,
            child: Container(
              height: height,
              constraints: themeData.pickerConstraints ??
                  const BoxConstraints(minHeight: 108),
              decoration: boxDecoration ??
                  themeData.pickerDecoration ??
                  BoxDecoration(
                      color: theme?.backgroundColor ??
                          const Color(0xFF02132B).withOpacity(0.03),
                      borderRadius: BorderRadius.circular(7)),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(inkRadius ?? 7),
                          onTap: () async {
                            if (onTap != null) onTap!();
                            FilePickerResult? result = await FilePicker
                                .pickFiles(
                                    allowedExtensions:
                                        pdfOnly == true ? ["pdf", "PDF"] : null,
                                    type: pdfOnly == true
                                        ? FileType.custom
                                        : FileType.any);

                            if (result != null) {
                              state.value = result.files.single;
                            }
                            if (onChanged != null) onChanged!(state.value);
                          },
                          onDoubleTap: onDoubleTap,
                          child: Padding(
                            padding: contentPadding ??
                                themeData.contentPadding ??
                                const EdgeInsets.fromLTRB(26, 6, 26, 6),
                            child: Stack(
                              alignment: Alignment.center,
                              children: (state.value != null)
                                  ? [
                                      Align(
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: state.value != null
                                              ? [
                                                  sh(10),
                                                  header != null
                                                      ? header!
                                                      : Center(
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              svgIconPath ==
                                                                      null
                                                                  ? Icon(
                                                                      Icons
                                                                          .cloud_upload_outlined,
                                                                      color: iconColor ??
                                                                          themeData
                                                                              .pickerIconColor ??
                                                                          const Color(0xFF02132B)
                                                                              .withOpacity(0.41),
                                                                    )
                                                                  : SvgPicture
                                                                      .asset(
                                                                      svgIconPath!,
                                                                      color: iconColor ??
                                                                          themeData
                                                                              .pickerIconColor ??
                                                                          const Color(0xFF02132B)
                                                                              .withOpacity(0.41),
                                                                    ),
                                                              sw(4),
                                                              Expanded(
                                                                child: Text(
                                                                  'Appuyez pour modifier le fichier',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: textStyle ??
                                                                      themeData
                                                                          .fieldStyle ??
                                                                      TextStyle(
                                                                          fontSize: sp(
                                                                              13),
                                                                          fontWeight: FontWeight
                                                                              .w500,
                                                                          color:
                                                                              const Color(0xFF02132B).withOpacity(0.41)),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                  sh(10),
                                                  Divider(
                                                      height: .5,
                                                      color: Colors.black
                                                          .withOpacity(.15)),
                                                  sh(20),
                                                  isValid ?? true
                                                      ? Container(
                                                          width:
                                                              formatWidth(34),
                                                          height:
                                                              formatWidth(34),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFF2BD184),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        34),
                                                          ),
                                                          child: const Center(
                                                              child: Icon(
                                                                  Icons
                                                                      .check_rounded,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 24)),
                                                        )
                                                      : Container(
                                                          width:
                                                              formatWidth(34),
                                                          height:
                                                              formatWidth(34),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFFEA1C1C),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        34),
                                                          ),
                                                          child: const Center(
                                                              child: Icon(
                                                                  Icons
                                                                      .close_rounded,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 24)),
                                                        ),
                                                  sh(6),
                                                  Center(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Opacity(
                                                              opacity: 0,
                                                              child: Icon(
                                                                Icons.close,
                                                                color: const Color(
                                                                        0xFF02132B)
                                                                    .withOpacity(
                                                                        0.41),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Center(
                                                                child: Text(
                                                                  state.value!
                                                                      .name,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: TextStyle(
                                                                      color: const Color(
                                                                          0xFF02132B),
                                                                      fontSize:
                                                                          sp(
                                                                              13),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500),
                                                                ),
                                                              ),
                                                            ),
                                                            InkWell(
                                                              onTap: () {
                                                                state.value =
                                                                    null;
                                                                if (onChanged !=
                                                                    null)
                                                                  onChanged!(state
                                                                      .value);
                                                              },
                                                              child: const Icon(
                                                                  Icons.close,
                                                                  color: Color(
                                                                      0xFF02132B)),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ]
                                              : [
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      svgIconPath == null
                                                          ? Icon(
                                                              Icons
                                                                  .cloud_upload_outlined,
                                                              color: iconColor ??
                                                                  themeData
                                                                      .pickerIconColor ??
                                                                  const Color(
                                                                          0xFF02132B)
                                                                      .withOpacity(
                                                                          0.41),
                                                            )
                                                          : SvgPicture.asset(
                                                              svgIconPath!,
                                                              color: iconColor ??
                                                                  themeData
                                                                      .pickerIconColor ??
                                                                  const Color(
                                                                          0xFF02132B)
                                                                      .withOpacity(
                                                                          0.41),
                                                            ),
                                                      sw(7),
                                                      Text(
                                                        'Appuyez pour choisir une / des fichier(s)',
                                                        style: textStyle ??
                                                            themeData
                                                                .fieldStyle ??
                                                            TextStyle(
                                                              fontSize: sp(13),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: const Color(
                                                                      0xFF02132B)
                                                                  .withOpacity(
                                                                      0.41),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                        ),
                                      ),
                                    ]
                                  : defaultFileName != null
                                      ? [
                                          Align(
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: defaultFileName != null
                                                  ? [
                                                      sh(10),
                                                      header != null
                                                          ? header!
                                                          : Center(
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  svgIconPath ==
                                                                          null
                                                                      ? Icon(
                                                                          Icons
                                                                              .cloud_upload_outlined,
                                                                          color: iconColor ??
                                                                              themeData.pickerIconColor ??
                                                                              const Color(0xFF02132B).withOpacity(0.41),
                                                                        )
                                                                      : SvgPicture
                                                                          .asset(
                                                                          svgIconPath!,
                                                                          color: iconColor ??
                                                                              themeData.pickerIconColor ??
                                                                              const Color(0xFF02132B).withOpacity(0.41),
                                                                        ),
                                                                  sw(4),
                                                                  Expanded(
                                                                    child: Text(
                                                                      'Appuyez pour modifier le fichier',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: textStyle ??
                                                                          themeData
                                                                              .fieldStyle ??
                                                                          TextStyle(
                                                                              fontSize: sp(13),
                                                                              fontWeight: FontWeight.w500,
                                                                              color: const Color(0xFF02132B).withOpacity(0.41)),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                      sh(10),
                                                      Divider(
                                                          height: .5,
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  .15)),
                                                      sh(20),
                                                      isValid ?? true
                                                          ? Container(
                                                              width:
                                                                  formatWidth(
                                                                      34),
                                                              height:
                                                                  formatWidth(
                                                                      34),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFF2BD184),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            34),
                                                              ),
                                                              child: const Center(
                                                                  child: Icon(
                                                                      Icons
                                                                          .check_rounded,
                                                                      color: Colors
                                                                          .white,
                                                                      size:
                                                                          24)),
                                                            )
                                                          : Container(
                                                              width:
                                                                  formatWidth(
                                                                      34),
                                                              height:
                                                                  formatWidth(
                                                                      34),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFEA1C1C),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            34),
                                                              ),
                                                              child: const Center(
                                                                  child: Icon(
                                                                      Icons
                                                                          .close_rounded,
                                                                      color: Colors
                                                                          .white,
                                                                      size:
                                                                          24)),
                                                            ),
                                                      sh(6),
                                                      Center(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                Opacity(
                                                                  opacity: 0,
                                                                  child: Icon(
                                                                    Icons.close,
                                                                    color: const Color(
                                                                            0xFF02132B)
                                                                        .withOpacity(
                                                                            0.41),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: Center(
                                                                    child: Text(
                                                                      defaultFileName!,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: textStyle ??
                                                                          themeData
                                                                              .fieldStyle ??
                                                                          TextStyle(
                                                                              color: const Color(0xFF02132B),
                                                                              fontSize: sp(13),
                                                                              fontWeight: FontWeight.w500),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ]
                                                  : [
                                                      Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          svgIconPath == null
                                                              ? Icon(
                                                                  Icons
                                                                      .cloud_upload_outlined,
                                                                  color: iconColor ??
                                                                      themeData
                                                                          .pickerIconColor ??
                                                                      const Color(
                                                                              0xFF02132B)
                                                                          .withOpacity(
                                                                              0.41),
                                                                )
                                                              : SvgPicture
                                                                  .asset(
                                                                  svgIconPath!,
                                                                  color: iconColor ??
                                                                      themeData
                                                                          .pickerIconColor ??
                                                                      const Color(
                                                                              0xFF02132B)
                                                                          .withOpacity(
                                                                              0.41),
                                                                ),
                                                          sw(7),
                                                          Text(
                                                            'Appuyez pour choisir une / des fichier(s)',
                                                            style: textStyle ??
                                                                themeData
                                                                    .fieldStyle ??
                                                                TextStyle(
                                                                  fontSize:
                                                                      sp(13),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: const Color(
                                                                          0xFF02132B)
                                                                      .withOpacity(
                                                                          0.41),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                            ),
                                          ),
                                        ]
                                      : [
                                          Align(
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                svgIconPath == null
                                                    ? Icon(
                                                        Icons
                                                            .cloud_upload_outlined,
                                                        color: iconColor ??
                                                            themeData
                                                                .pickerIconColor ??
                                                            const Color(
                                                                    0xFF02132B)
                                                                .withOpacity(
                                                                    0.41),
                                                      )
                                                    : SvgPicture.asset(
                                                        svgIconPath!,
                                                        color: iconColor ??
                                                            themeData
                                                                .pickerIconColor ??
                                                            const Color(
                                                                    0xFF02132B)
                                                                .withOpacity(
                                                                    0.41),
                                                      ),
                                                sh(7),
                                                Text(
                                                  contentTitle ??
                                                      'Appuyez pour choisir un fichier',
                                                  textAlign: TextAlign.center,
                                                  style: textStyle ??
                                                      themeData.hintStyle ??
                                                      TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: const Color(
                                                                0xFF02132B)
                                                            .withOpacity(0.41),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (desc != null)
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Text(desc!,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: sp(11),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: const Color(
                                                          0xFF02132B))),
                                            )
                                        ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if ((desc?.isEmpty ?? true) && (pdfOnly ?? false)) ...[
                      Text("Format PDF",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: sp(11),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF02132B))),
                      sh(10)
                    ]
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class FileNameItem extends StatelessWidget {
  final String fileName;
  final VoidCallback onClear;
  const FileNameItem({
    required this.fileName,
    required this.onClear,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
            color: const Color(0xFF02132B).withOpacity(0.41),
            indent: 0,
            endIndent: 0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              fileName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF02132B),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
              splashRadius: 24,
            )
          ],
        ),
      ],
    );
  }
}
