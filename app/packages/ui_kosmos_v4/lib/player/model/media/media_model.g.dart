// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MediaModelImpl _$$MediaModelImplFromJson(Map<String, dynamic> json) =>
    _$MediaModelImpl(
      id: json['id'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      mediaRelativePath: json['mediaRelativePath'] as String?,
      mediaType: $enumDecodeNullable(_$AssetTypeEnumMap, json['mediaType']),
      mediaName: json['mediaName'] as String?,
      mediaHeight: (json['mediaHeight'] as num?)?.toDouble(),
      mediaWidth: (json['mediaWidth'] as num?)?.toDouble(),
      mediaDuration: (json['mediaDuration'] as num?)?.toInt(),
      videoThumbnail: json['videoThumbnail'] as String?,
      videoThumbnailRelativePath: json['videoThumbnailRelativePath'] as String?,
    );

Map<String, dynamic> _$$MediaModelImplToJson(_$MediaModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaUrl': instance.mediaUrl,
      'mediaRelativePath': instance.mediaRelativePath,
      'mediaType': _$AssetTypeEnumMap[instance.mediaType],
      'mediaName': instance.mediaName,
      'mediaHeight': instance.mediaHeight,
      'mediaWidth': instance.mediaWidth,
      'mediaDuration': instance.mediaDuration,
      'videoThumbnail': instance.videoThumbnail,
      'videoThumbnailRelativePath': instance.videoThumbnailRelativePath,
    };

const _$AssetTypeEnumMap = {
  AssetType.other: 'other',
  AssetType.image: 'image',
  AssetType.video: 'video',
  AssetType.audio: 'audio',
};
