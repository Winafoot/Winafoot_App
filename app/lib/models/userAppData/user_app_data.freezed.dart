// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_app_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserAppData _$UserAppDataFromJson(Map<String, dynamic> json) {
  return _UserAppData.fromJson(json);
}

/// @nodoc
mixin _$UserAppData {
  List<String> get test => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserAppDataCopyWith<UserAppData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserAppDataCopyWith<$Res> {
  factory $UserAppDataCopyWith(
    UserAppData value,
    $Res Function(UserAppData) then,
  ) = _$UserAppDataCopyWithImpl<$Res, UserAppData>;
  @useResult
  $Res call({List<String> test});
}

/// @nodoc
class _$UserAppDataCopyWithImpl<$Res, $Val extends UserAppData>
    implements $UserAppDataCopyWith<$Res> {
  _$UserAppDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? test = null}) {
    return _then(
      _value.copyWith(
            test:
                null == test
                    ? _value.test
                    : test // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserAppDataImplCopyWith<$Res>
    implements $UserAppDataCopyWith<$Res> {
  factory _$$UserAppDataImplCopyWith(
    _$UserAppDataImpl value,
    $Res Function(_$UserAppDataImpl) then,
  ) = __$$UserAppDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> test});
}

/// @nodoc
class __$$UserAppDataImplCopyWithImpl<$Res>
    extends _$UserAppDataCopyWithImpl<$Res, _$UserAppDataImpl>
    implements _$$UserAppDataImplCopyWith<$Res> {
  __$$UserAppDataImplCopyWithImpl(
    _$UserAppDataImpl _value,
    $Res Function(_$UserAppDataImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? test = null}) {
    return _then(
      _$UserAppDataImpl(
        test:
            null == test
                ? _value._test
                : test // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserAppDataImpl implements _UserAppData {
  _$UserAppDataImpl({final List<String> test = const []}) : _test = test;

  factory _$UserAppDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserAppDataImplFromJson(json);

  final List<String> _test;
  @override
  @JsonKey()
  List<String> get test {
    if (_test is EqualUnmodifiableListView) return _test;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_test);
  }

  @override
  String toString() {
    return 'UserAppData(test: $test)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserAppDataImpl &&
            const DeepCollectionEquality().equals(other._test, _test));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_test));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserAppDataImplCopyWith<_$UserAppDataImpl> get copyWith =>
      __$$UserAppDataImplCopyWithImpl<_$UserAppDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserAppDataImplToJson(this);
  }
}

abstract class _UserAppData implements UserAppData {
  factory _UserAppData({final List<String> test}) = _$UserAppDataImpl;

  factory _UserAppData.fromJson(Map<String, dynamic> json) =
      _$UserAppDataImpl.fromJson;

  @override
  List<String> get test;
  @override
  @JsonKey(ignore: true)
  _$$UserAppDataImplCopyWith<_$UserAppDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
