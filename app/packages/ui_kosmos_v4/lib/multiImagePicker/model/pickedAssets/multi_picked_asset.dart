import 'dart:io';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'multi_picked_asset.freezed.dart';

enum PickedAssetType {
  image,
  video,
}

@freezed
class MultiPickedAsset with _$MultiPickedAsset {
  factory MultiPickedAsset({
    String? id,
    int? pos,
    File? file,
    Uint8List? thumbnail,
    String? url,
    String? thumbnailUrl,
    double? mediaWidth,
    double? mediaHeight,
    String? mimeType,
    required PickedAssetType type,

  }) = _MultiPickedAsset;
}
