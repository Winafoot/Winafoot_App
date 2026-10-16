// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FileData _$FileDataFromJson(Map<String, dynamic> json) {
  return _FileData.fromJson(json);
}

/// @nodoc
mixin _$FileData {
  String? get url => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FileDataCopyWith<FileData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileDataCopyWith<$Res> {
  factory $FileDataCopyWith(FileData value, $Res Function(FileData) then) =
      _$FileDataCopyWithImpl<$Res, FileData>;
  @useResult
  $Res call({String? url, String? fileName});
}

/// @nodoc
class _$FileDataCopyWithImpl<$Res, $Val extends FileData>
    implements $FileDataCopyWith<$Res> {
  _$FileDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = freezed,
    Object? fileName = freezed,
  }) {
    return _then(_value.copyWith(
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileDataImplCopyWith<$Res>
    implements $FileDataCopyWith<$Res> {
  factory _$$FileDataImplCopyWith(
          _$FileDataImpl value, $Res Function(_$FileDataImpl) then) =
      __$$FileDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? url, String? fileName});
}

/// @nodoc
class __$$FileDataImplCopyWithImpl<$Res>
    extends _$FileDataCopyWithImpl<$Res, _$FileDataImpl>
    implements _$$FileDataImplCopyWith<$Res> {
  __$$FileDataImplCopyWithImpl(
      _$FileDataImpl _value, $Res Function(_$FileDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = freezed,
    Object? fileName = freezed,
  }) {
    return _then(_$FileDataImpl(
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FileDataImpl implements _FileData {
  _$FileDataImpl({this.url, this.fileName});

  factory _$FileDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileDataImplFromJson(json);

  @override
  final String? url;
  @override
  final String? fileName;

  @override
  String toString() {
    return 'FileData(url: $url, fileName: $fileName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileDataImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, url, fileName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FileDataImplCopyWith<_$FileDataImpl> get copyWith =>
      __$$FileDataImplCopyWithImpl<_$FileDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileDataImplToJson(
      this,
    );
  }
}

abstract class _FileData implements FileData {
  factory _FileData({final String? url, final String? fileName}) =
      _$FileDataImpl;

  factory _FileData.fromJson(Map<String, dynamic> json) =
      _$FileDataImpl.fromJson;

  @override
  String? get url;
  @override
  String? get fileName;
  @override
  @JsonKey(ignore: true)
  _$$FileDataImplCopyWith<_$FileDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
