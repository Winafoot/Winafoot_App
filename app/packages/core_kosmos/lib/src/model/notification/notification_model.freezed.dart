// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) {
  return _NotificationModel.fromJson(json);
}

/// @nodoc
mixin _$NotificationModel {
  /// Required fields
  List<String> get sendToIds => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get body => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  bool get toTopic => throw _privateConstructorUsedError;
  String? get topic => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationModelCopyWith<NotificationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationModelCopyWith<$Res> {
  factory $NotificationModelCopyWith(
          NotificationModel value, $Res Function(NotificationModel) then) =
      _$NotificationModelCopyWithImpl<$Res, NotificationModel>;
  @useResult
  $Res call(
      {List<String> sendToIds,
      String title,
      String? body,
      String? type,
      bool toTopic,
      String? topic,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$NotificationModelCopyWithImpl<$Res, $Val extends NotificationModel>
    implements $NotificationModelCopyWith<$Res> {
  _$NotificationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sendToIds = null,
    Object? title = null,
    Object? body = freezed,
    Object? type = freezed,
    Object? toTopic = null,
    Object? topic = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      sendToIds: null == sendToIds
          ? _value.sendToIds
          : sendToIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      toTopic: null == toTopic
          ? _value.toTopic
          : toTopic // ignore: cast_nullable_to_non_nullable
              as bool,
      topic: freezed == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationModelImplCopyWith<$Res>
    implements $NotificationModelCopyWith<$Res> {
  factory _$$NotificationModelImplCopyWith(_$NotificationModelImpl value,
          $Res Function(_$NotificationModelImpl) then) =
      __$$NotificationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String> sendToIds,
      String title,
      String? body,
      String? type,
      bool toTopic,
      String? topic,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$NotificationModelImplCopyWithImpl<$Res>
    extends _$NotificationModelCopyWithImpl<$Res, _$NotificationModelImpl>
    implements _$$NotificationModelImplCopyWith<$Res> {
  __$$NotificationModelImplCopyWithImpl(_$NotificationModelImpl _value,
      $Res Function(_$NotificationModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sendToIds = null,
    Object? title = null,
    Object? body = freezed,
    Object? type = freezed,
    Object? toTopic = null,
    Object? topic = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$NotificationModelImpl(
      sendToIds: null == sendToIds
          ? _value._sendToIds
          : sendToIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      toTopic: null == toTopic
          ? _value.toTopic
          : toTopic // ignore: cast_nullable_to_non_nullable
              as bool,
      topic: freezed == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationModelImpl implements _NotificationModel {
  const _$NotificationModelImpl(
      {required final List<String> sendToIds,
      required this.title,
      this.body,
      this.type,
      this.toTopic = false,
      this.topic,
      final Map<String, dynamic>? metadata})
      : _sendToIds = sendToIds,
        _metadata = metadata;

  factory _$NotificationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationModelImplFromJson(json);

  /// Required fields
  final List<String> _sendToIds;

  /// Required fields
  @override
  List<String> get sendToIds {
    if (_sendToIds is EqualUnmodifiableListView) return _sendToIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sendToIds);
  }

  @override
  final String title;
  @override
  final String? body;
  @override
  final String? type;
  @override
  @JsonKey()
  final bool toTopic;
  @override
  final String? topic;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'NotificationModel(sendToIds: $sendToIds, title: $title, body: $body, type: $type, toTopic: $toTopic, topic: $topic, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationModelImpl &&
            const DeepCollectionEquality()
                .equals(other._sendToIds, _sendToIds) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.toTopic, toTopic) || other.toTopic == toTopic) &&
            (identical(other.topic, topic) || other.topic == topic) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_sendToIds),
      title,
      body,
      type,
      toTopic,
      topic,
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationModelImplCopyWith<_$NotificationModelImpl> get copyWith =>
      __$$NotificationModelImplCopyWithImpl<_$NotificationModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationModelImplToJson(
      this,
    );
  }
}

abstract class _NotificationModel implements NotificationModel {
  const factory _NotificationModel(
      {required final List<String> sendToIds,
      required final String title,
      final String? body,
      final String? type,
      final bool toTopic,
      final String? topic,
      final Map<String, dynamic>? metadata}) = _$NotificationModelImpl;

  factory _NotificationModel.fromJson(Map<String, dynamic> json) =
      _$NotificationModelImpl.fromJson;

  @override

  /// Required fields
  List<String> get sendToIds;
  @override
  String get title;
  @override
  String? get body;
  @override
  String? get type;
  @override
  bool get toTopic;
  @override
  String? get topic;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$NotificationModelImplCopyWith<_$NotificationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
