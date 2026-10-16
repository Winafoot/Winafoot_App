// ignore_for_file: prefer_final_fields

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import 'package:ui_kosmos_v4/multiImagePicker/model/pickedAssets/multi_picked_asset.dart';
import 'package:ui_kosmos_v4/multiImagePicker/theme/multi_image_picker_theme_data.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

/// {@category Widget}
/// **/!\ Only for IOS and Android /!\**
///
  @Deprecated('Use MultiImagePickerV3 instead')
class MultiImagePicker extends StatefulWidget {
  final int maxItem;
  final RequestType type;
  final String? fieldName;

  final TextStyle? fieldNameStyle;
  final ScrollController? controller;
  final double? bottomSpacing;

  /// Theme
  final Color? deleteButtonColor;
  final double? itemSpacing;
  final double? itemRunSpacing;
  final EdgeInsetsGeometry? imageBoxPadding;
  final BorderRadiusGeometry? imageBoxBorderRadius;
  final Color? imageBoxColor;
  final double? imageBoxWidth;
  final double? imageBoxHeight;
  final String? themeName;
  final MultiImagePickerThemeData? theme;

  final Function(List<MultiPickedAsset> newMedias)? onAdded;
  final Function(List<MultiPickedAsset> newOrder)? onChangedOrder;
  final Function(String? id, int idx)? onDelete;

  final List<MultiPickedAsset> assetItem;

  const MultiImagePicker({
    super.key,
    this.maxItem = 8,
    this.type = RequestType.all,
    this.bottomSpacing,
    this.themeName,
    this.theme,
    this.controller,
    this.deleteButtonColor,
    this.itemRunSpacing,
    this.itemSpacing,
    this.imageBoxBorderRadius,
    this.imageBoxPadding,
    this.imageBoxColor,
    this.imageBoxHeight,
    this.imageBoxWidth,
    this.fieldName,
    this.fieldNameStyle,
    this.onAdded,
    this.assetItem = const [],
    this.onDelete,
    this.onChangedOrder,
  });

  @override
  State<MultiImagePicker> createState() => MultiImagePickerState();
}

class MultiImagePickerState extends State<MultiImagePicker> {
  late final MultiImagePickerThemeData? _themeData;

  List<MultiPickedAsset> _images = [];

  late ScrollController ctlr;

  @override
  void initState() {
    _themeData = loadThemeData(
        widget.theme,
        widget.themeName ?? "multi_image_picker",
        (() => kDefaultMultiImagePickerTheme));
    _images = widget.assetItem;
    ctlr = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      controller: widget.controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sh(5),
          if (widget.fieldName != null) ...[
            Text(
              widget.fieldName!,
              style: widget.fieldNameStyle ??
                  const TextStyle(
                      color: Color(0xFF02132B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
            ),
            sh(12),
          ],
          ReorderableWrap(
            controller: ctlr,
            spacing: widget.itemSpacing ??
                _themeData?.itemSpacing ??
                formatWidth(25),
            runSpacing: widget.itemRunSpacing ??
                _themeData?.itemRunSpacing ??
                formatHeight(15),
            children: [
              for (int i = 0; i < widget.maxItem; i++) _buildImageBox(i)
            ],
            onReorder: (firstPos, endPos) {
              final MultiPickedAsset firstItem = widget.assetItem[firstPos];
              _images.removeAt(firstPos);
              if (endPos > _images.length) {
                _images.insert(_images.length, firstItem);
              } else {
                _images.insert(endPos, firstItem);
              }

              widget.onChangedOrder?.call(_images);
              setState(() {});
            },
          ),
          SizedBox(
              height: widget.bottomSpacing ??
                  (context.paddingBottom + formatHeight(60))),
        ],
      ),
    );
  }

  Widget _buildImageBox(int index) {
    //final File? image = index < _images.length ? _images[index] : null;
    final MultiPickedAsset? image =
        index < _images.length ? _images[index] : null;

    bool isActive = false;

    return InkWell(
      onTap: () async {
        if (image == null) {
          await _pickImages(context, index, type: widget.type);
        }
      },
      child: Container(
        width: widget.imageBoxWidth ??
            _themeData?.imageBoxWidth ??
            formatWidth(142),
        height: widget.imageBoxHeight ??
            _themeData?.imageBoxHeight ??
            formatHeight(183),
        padding: widget.imageBoxPadding ??
            _themeData?.imageBoxPadding ??
            EdgeInsets.all(formatWidth(6)),
        decoration: BoxDecoration(
          borderRadius: widget.imageBoxBorderRadius ??
              _themeData?.imageBoxBorderRadius ??
              BorderRadius.circular(formatWidth(7)),
          color: widget.imageBoxColor ??
              _themeData?.imageBoxColor ??
              const Color(0xFFF7F7F8),
        ),
        clipBehavior: Clip.none,
        child: image != null
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: widget.imageBoxWidth ??
                        _themeData?.imageBoxWidth ??
                        formatWidth(142),
                    height: widget.imageBoxHeight ??
                        _themeData?.imageBoxHeight ??
                        formatHeight(183),
                    decoration: BoxDecoration(
                      borderRadius: widget.imageBoxBorderRadius ??
                          _themeData?.imageBoxBorderRadius ??
                          BorderRadius.circular(formatWidth(11)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: widget.imageBoxWidth ??
                              _themeData?.imageBoxWidth ??
                              formatWidth(142),
                          height: widget.imageBoxHeight ??
                              _themeData?.imageBoxHeight ??
                              formatHeight(183),
                          child: image.type == PickedAssetType.video
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: image.thumbnailUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  image.thumbnailUrl ?? "",
                                              fit: BoxFit.cover,
                                            )
                                          : image.thumbnail != null
                                              ? Image.memory(image.thumbnail!,
                                                  fit: BoxFit.cover)
                                              : const SizedBox(),
                                    ),
                                    Positioned.fill(
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: formatWidth(30),
                                      ),
                                    ),
                                  ],
                                )
                              : image.url != null
                                  ? CachedNetworkImage(
                                      imageUrl: image.url ?? "",
                                      fit: BoxFit.cover,
                                    )
                                  : image.file != null
                                      ? Image.file(image.file!,
                                          fit: BoxFit.cover)
                                      : const SizedBox(),
                          //child: Image.file(image, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: formatHeight(-3),
                          left: formatWidth(-6),
                          child: const Icon(
                            CupertinoIcons.line_horizontal_3,
                            size: 12,
                          ),
                        ),
                        Positioned(
                          bottom: formatHeight(5),
                          left: formatWidth(6),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(formatWidth(100)),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: formatWidth(10),
                                    vertical: formatHeight(3)),
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(formatWidth(100)),
                                    color: Colors.black.withOpacity(.4)),
                                child: Text(
                                    "utils.number_x"
                                        .tr(args: [(index + 1).toString()]),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: sp(9),
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Positioned(
                    top: -15,
                    right: -15,
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerUp: (_) {
                        if (isActive == true) return;
                        if (widget.onDelete != null) {
                          widget.onDelete!.call(image.id, index);
                        } else {
                          setState(() {
                            _images.removeAt(index);
                          });
                        }
                        isActive = false;
                      },
                      child: AbsorbPointer(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: formatWidth(18),
                            height: formatWidth(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEB5353),
                              border: Border.all(width: 1, color: Colors.white),
                              borderRadius:
                                  BorderRadius.circular(formatWidth(20)),
                            ),
                            child: Center(
                                child: Icon(Icons.remove_rounded,
                                    color: Colors.white,
                                    size: formatWidth(13))),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )
            : Center(
                child: Icon(
                  Icons.add_rounded,
                  color: const Color(0xFF9299A4),
                  size: formatWidth(30),
                ),
              ),
      ),
    );
  }

  // List<File> getPickedImages() => _images;

  _pickImages(BuildContext context, int index,
      {RequestType type = RequestType.all}) async {
    if (widget.maxItem == _images.length) return;
    final pickedImage = await ImageFileController.pickMedia(
      context,
      assetType: type,
      allowMultiple: true,
      maxAssets: widget.maxItem - _images.length,
    );

    if (pickedImage == null) return;
    if (pickedImage.isNotEmpty) {
      if (widget.onAdded != null) {
        List<MultiPickedAsset> newMedias = [];
        for (var asset in pickedImage) {
          File? file = await asset.file;
          if (file == null) continue;

          Uint8List? thumbnailData;

          if (asset.type == AssetType.video) {
            thumbnailData = (await asset.thumbnailData)!;
          }

          MultiPickedAsset newMedia = MultiPickedAsset(
              file: file,
              type: asset.type == AssetType.image
                  ? PickedAssetType.image
                  : PickedAssetType.video,
              thumbnail: thumbnailData);

          newMedias.add(newMedia);
        }
        widget.onAdded!(newMedias);
      }
    }
  }
}
