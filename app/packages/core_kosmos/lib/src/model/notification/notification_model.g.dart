// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(Map json) =>
    _$NotificationModelImpl(
      sendToIds:
          (json['sendToIds'] as List<dynamic>).map((e) => e as String).toList(),
      title: json['title'] as String,
      body: json['body'] as String?,
      type: json['type'] as String?,
      toTopic: json['toTopic'] as bool? ?? false,
      topic: json['topic'] as String?,
      metadata: (json['metadata'] as Map?)?.map(
        (k, e) => MapEntry(k as String, e),
      ),
    );

Map<String, dynamic> _$$NotificationModelImplToJson(
        _$NotificationModelImpl instance) =>
    <String, dynamic>{
      'sendToIds': instance.sendToIds,
      'title': instance.title,
      'body': instance.body,
      'type': instance.type,
      'toTopic': instance.toTopic,
      'topic': instance.topic,
      'metadata': instance.metadata,
    };
