// ignore_for_file: prefer_final_fields

import 'package:mime/mime.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import 'package:ui_kosmos_v4/multiImagePicker/model/pickedAssets/multi_picked_asset.dart';
import 'package:ui_kosmos_v4/multiImagePicker/theme/multi_image_picker_theme_data.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vd;

// =====================
// Shared, capped cache
// =====================

/// {@category Widget}
/// **/!\ Only for iOS and Android /!\**
class MultiImagePickerV3 extends StatefulWidget {
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

  const MultiImagePickerV3({
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
  State<MultiImagePickerV3> createState() => MultiImagePickerV3State();
}

class MultiImagePickerV3State extends State<MultiImagePickerV3> {
  late final MultiImagePickerThemeData? _themeData;
  List<MultiPickedAsset> _images = [];
  late ScrollController ctlr;

  @override
  void initState() {
    _themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "multi_image_picker",
      (() => kDefaultMultiImagePickerTheme),
    );
    _images = widget.assetItem;
    ctlr = ScrollController();
    super.initState();
  }

  @override
  void didUpdateWidget(MultiImagePickerV3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetItem != widget.assetItem) {
      _images = widget.assetItem;
    }
  }

  @override
  void dispose() {
    ctlr.dispose(); // ✅ prevent controller leak
    super.dispose();
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
                    fontWeight: FontWeight.w500,
                  ),
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
                (context.paddingBottom + formatHeight(60)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBox(int index) {
    final MultiPickedAsset? image =
        index < _images.length ? _images[index] : null;

    // compute final render size once
    final double boxW =
        widget.imageBoxWidth ?? _themeData?.imageBoxWidth ?? formatWidth(142);
    final double boxH = widget.imageBoxHeight ??
        _themeData?.imageBoxHeight ??
        formatHeight(183);
    final int memW = boxW.round();
    final int memH = boxH.round();

    bool isActive = false;

    return InkWell(
      onTap: () async {
        if (image == null) {
          if (Platform.isAndroid) {
            await _pickImagesAndroid(context, index, type: widget.type);
          } else {
            await _pickImagesIOS(context, index, type: widget.type);
          }
        }
      },
      child: Container(
        width: boxW,
        height: boxH,
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
                    width: boxW,
                    height: boxH,
                    decoration: BoxDecoration(
                      borderRadius: widget.imageBoxBorderRadius ??
                          _themeData?.imageBoxBorderRadius ??
                          BorderRadius.circular(formatWidth(11)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: boxW,
                          height: boxH,
                          child: image.type == PickedAssetType.video
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: image.thumbnailUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  image.thumbnailUrl ?? "",
                                              fit: BoxFit.cover,
                                              memCacheWidth: memW,
                                              memCacheHeight: memH,
                                              maxWidthDiskCache: memW,
                                              maxHeightDiskCache: memH,
                                              // cacheManager: kMultiImageCacheManager,
                                            )
                                          : image.thumbnail != null
                                              ? Image.memory(
                                                  image.thumbnail!,
                                                  fit: BoxFit.cover,
                                                  cacheWidth: memW,
                                                  cacheHeight: memH,
                                                )
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
                                      memCacheWidth: memW,
                                      memCacheHeight: memH,
                                      maxWidthDiskCache: memW,
                                      maxHeightDiskCache: memH,
                                      // cacheManager: kMultiImageCacheManager,
                                    )
                                  : image.file != null
                                      ? Image.file(
                                          image.file!,
                                          fit: BoxFit.cover,
                                          cacheWidth: memW,
                                          cacheHeight: memH,
                                        )
                                      : const SizedBox(),
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
                                  vertical: formatHeight(3),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(formatWidth(100)),
                                  color: Colors.black.withOpacity(.4),
                                ),
                                child: Text(
                                  "utils.number_x"
                                      .tr(args: [(index + 1).toString()]),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: sp(9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                              child: Icon(
                                Icons.remove_rounded,
                                color: Colors.white,
                                size: formatWidth(13),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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

  // iOS picker
  Future<void> _pickImagesIOS(BuildContext context, int index,
      {RequestType type = RequestType.all}) async {
    if (widget.maxItem == _images.length) return;

    final pickedImage = await ImageFileController.pickMedia(
      context,
      assetType: type,
      allowMultiple: true,
      maxAssets: widget.maxItem - _images.length,
    );

    if (pickedImage == null || pickedImage.isEmpty) return;

    if (widget.onAdded != null) {
      List<MultiPickedAsset> newMedias = [];
      for (var asset in pickedImage) {
        final File? file = await asset.file;
        if (file == null) continue;

        Uint8List? thumbnailData;
        if (asset.type == AssetType.video) {
          thumbnailData = await asset.thumbnailData;
        }

        final MultiPickedAsset newMedia = MultiPickedAsset(
          file: file,
          type: asset.type == AssetType.image
              ? PickedAssetType.image
              : PickedAssetType.video,
          thumbnail: thumbnailData,
        );

        newMedias.add(newMedia);
      }
      widget.onAdded!(newMedias);
    }
  }

  // Android picker
  Future<void> _pickImagesAndroid(BuildContext context, int index,
      {RequestType type = RequestType.all}) async {
    if (widget.maxItem == _images.length) return;

    List<XFile> pickedImages = [];
    switch (type) {
      case RequestType.all:
        pickedImages = await ImageFileController.pickMultipleMediaAndroid(
          context,
          limit: widget.maxItem - _images.length,
        );
        break;
      case RequestType.image:
        pickedImages = await ImageFileController.pickImages(
          context,
          limit: widget.maxItem - _images.length,
        );
        break;
    }

    if (pickedImages.isEmpty) return;

    if (widget.onAdded != null) {
      List<MultiPickedAsset> newMedias = [];
      for (var asset in pickedImages) {
        final File file = File(asset.path);

        Uint8List? thumbnailData;
        final bool? isFileImage = isImage(asset);
        if (isFileImage == null) continue; // ✅ don't bail the whole method

        if (!isFileImage) {
          thumbnailData = await getVideoThumbnail(asset);
        }

        final MultiPickedAsset newMedia = MultiPickedAsset(
          file: file,
          type: isFileImage ? PickedAssetType.image : PickedAssetType.video,
          thumbnail: thumbnailData,
        );

        newMedias.add(newMedia);
      }
      widget.onAdded!(newMedias);
    }
  }

  // Returns true for image, false for video, null for unknown
  bool? isImage(XFile xfile) {
    final mimeType = lookupMimeType(xfile.path);
    if (mimeType != null && mimeType.startsWith('image/')) return true;
    if (mimeType != null && mimeType.startsWith('video/')) return false;

    final ext = getExtension(xfile.path); // fixed: no leading dot
    if (["png", "jpg", "jpeg", "gif", "webp", "heic"].contains(ext)) {
      return true;
    } else if ([
      "mp4",
      "mov",
      "avi",
      "mkv",
      "wmv",
      "flv",
      "mpg",
      "mpeg",
      "m4v",
      "3gp",
      "3g2",
      "webm",
    ].contains(ext)) {
      return false;
    } else {
      return null;
    }
  }

  // Fixed: return extension without leading dot
  String getExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  Future<Uint8List?> getVideoThumbnail(XFile videoFile) async {
    try {
      // Generate thumbnail as bytes
      final Uint8List? bytes = await vd.VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: vd.ImageFormat.PNG,
        maxHeight: 150,
        quality: 95,
      );
      return bytes;
    } catch (_) {
      return null;
    }
  }
}
