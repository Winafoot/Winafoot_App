// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_app_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserAppDataImpl _$$UserAppDataImplFromJson(Map<String, dynamic> json) =>
    _$UserAppDataImpl(
      test:
          (json['test'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );

Map<String, dynamic> _$$UserAppDataImplToJson(_$UserAppDataImpl instance) =>
    <String, dynamic>{'test': instance.test};
