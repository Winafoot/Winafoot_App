// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disponibility_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DisponibilityModelImpl _$$DisponibilityModelImplFromJson(
        Map<String, dynamic> json) =>
    _$DisponibilityModelImpl(
      isOpen: json['isOpen'] as bool? ?? true,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  DisponibilityItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$DisponibilityModelImplToJson(
        _$DisponibilityModelImpl instance) =>
    <String, dynamic>{
      'isOpen': instance.isOpen,
      'items': instance.items,
    };

_$DisponibilityItemModelImpl _$$DisponibilityItemModelImplFromJson(
        Map<String, dynamic> json) =>
    _$DisponibilityItemModelImpl(
      from: const TimestampConverter().fromJson(json['from']),
      to: const TimestampConverter().fromJson(json['to']),
      isPaused: json['isPaused'] as bool? ?? false,
    );

Map<String, dynamic> _$$DisponibilityItemModelImplToJson(
        _$DisponibilityItemModelImpl instance) =>
    <String, dynamic>{
      'from': const TimestampConverter().toJson(instance.from),
      'to': const TimestampConverter().toJson(instance.to),
      'isPaused': instance.isPaused,
    };
