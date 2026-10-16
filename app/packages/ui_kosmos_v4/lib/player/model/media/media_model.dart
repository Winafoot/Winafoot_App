import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:photo_manager/photo_manager.dart';

part 'media_model.freezed.dart';
part 'media_model.g.dart';

/// Média (image ou vidéo) affiché par le lecteur.
@freezed
class MediaModel with _$MediaModel {
  const factory MediaModel({
    final String? id,
    required final String? mediaUrl,
    final String? mediaRelativePath,
    final AssetType? mediaType,
    final String? mediaName,
    final double? mediaHeight,
    final double? mediaWidth,
    final int? mediaDuration,
    final String? videoThumbnail,
    final String? videoThumbnailRelativePath,
  }) = _MediaModel;

  factory MediaModel.fromJson(Map<String, dynamic> json) => _$MediaModelFromJson(json);
}
