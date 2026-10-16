// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sized_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SizedImage _$SizedImageFromJson(Map<String, dynamic> json) {
  return _SizedImage.fromJson(json);
}

/// @nodoc
mixin _$SizedImage {
  String? get url => throw _privateConstructorUsedError;
  String? get compressedUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SizedImageCopyWith<SizedImage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SizedImageCopyWith<$Res> {
  factory $SizedImageCopyWith(
          SizedImage value, $Res Function(SizedImage) then) =
      _$SizedImageCopyWithImpl<$Res, SizedImage>;
  @useResult
  $Res call({String? url, String? compressedUrl});
}

/// @nodoc
class _$SizedImageCopyWithImpl<$Res, $Val extends SizedImage>
    implements $SizedImageCopyWith<$Res> {
  _$SizedImageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = freezed,
    Object? compressedUrl = freezed,
  }) {
    return _then(_value.copyWith(
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      compressedUrl: freezed == compressedUrl
          ? _value.compressedUrl
          : compressedUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SizedImageImplCopyWith<$Res>
    implements $SizedImageCopyWith<$Res> {
  factory _$$SizedImageImplCopyWith(
          _$SizedImageImpl value, $Res Function(_$SizedImageImpl) then) =
      __$$SizedImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? url, String? compressedUrl});
}

/// @nodoc
class __$$SizedImageImplCopyWithImpl<$Res>
    extends _$SizedImageCopyWithImpl<$Res, _$SizedImageImpl>
    implements _$$SizedImageImplCopyWith<$Res> {
  __$$SizedImageImplCopyWithImpl(
      _$SizedImageImpl _value, $Res Function(_$SizedImageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = freezed,
    Object? compressedUrl = freezed,
  }) {
    return _then(_$SizedImageImpl(
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      compressedUrl: freezed == compressedUrl
          ? _value.compressedUrl
          : compressedUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SizedImageImpl implements _SizedImage {
  _$SizedImageImpl({this.url, this.compressedUrl});

  factory _$SizedImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$SizedImageImplFromJson(json);

  @override
  final String? url;
  @override
  final String? compressedUrl;

  @override
  String toString() {
    return 'SizedImage(url: $url, compressedUrl: $compressedUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SizedImageImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.compressedUrl, compressedUrl) ||
                other.compressedUrl == compressedUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, url, compressedUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SizedImageImplCopyWith<_$SizedImageImpl> get copyWith =>
      __$$SizedImageImplCopyWithImpl<_$SizedImageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SizedImageImplToJson(
      this,
    );
  }
}

abstract class _SizedImage implements SizedImage {
  factory _SizedImage({final String? url, final String? compressedUrl}) =
      _$SizedImageImpl;

  factory _SizedImage.fromJson(Map<String, dynamic> json) =
      _$SizedImageImpl.fromJson;

  @override
  String? get url;
  @override
  String? get compressedUrl;
  @override
  @JsonKey(ignore: true)
  _$$SizedImageImplCopyWith<_$SizedImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
