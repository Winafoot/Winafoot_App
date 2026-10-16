// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ClassicLoaderThemeData {
  Color? get activeColor => throw _privateConstructorUsedError;
  Duration? get duration => throw _privateConstructorUsedError;
  double? get radius => throw _privateConstructorUsedError;

  /// Create a copy of ClassicLoaderThemeData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClassicLoaderThemeDataCopyWith<ClassicLoaderThemeData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClassicLoaderThemeDataCopyWith<$Res> {
  factory $ClassicLoaderThemeDataCopyWith(ClassicLoaderThemeData value,
          $Res Function(ClassicLoaderThemeData) then) =
      _$ClassicLoaderThemeDataCopyWithImpl<$Res, ClassicLoaderThemeData>;
  @useResult
  $Res call({Color? activeColor, Duration? duration, double? radius});
}

/// @nodoc
class _$ClassicLoaderThemeDataCopyWithImpl<$Res,
        $Val extends ClassicLoaderThemeData>
    implements $ClassicLoaderThemeDataCopyWith<$Res> {
  _$ClassicLoaderThemeDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClassicLoaderThemeData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeColor = freezed,
    Object? duration = freezed,
    Object? radius = freezed,
  }) {
    return _then(_value.copyWith(
      activeColor: freezed == activeColor
          ? _value.activeColor
          : activeColor // ignore: cast_nullable_to_non_nullable
              as Color?,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration?,
      radius: freezed == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClassicLoaderThemeDataImplCopyWith<$Res>
    implements $ClassicLoaderThemeDataCopyWith<$Res> {
  factory _$$ClassicLoaderThemeDataImplCopyWith(
          _$ClassicLoaderThemeDataImpl value,
          $Res Function(_$ClassicLoaderThemeDataImpl) then) =
      __$$ClassicLoaderThemeDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Color? activeColor, Duration? duration, double? radius});
}

/// @nodoc
class __$$ClassicLoaderThemeDataImplCopyWithImpl<$Res>
    extends _$ClassicLoaderThemeDataCopyWithImpl<$Res,
        _$ClassicLoaderThemeDataImpl>
    implements _$$ClassicLoaderThemeDataImplCopyWith<$Res> {
  __$$ClassicLoaderThemeDataImplCopyWithImpl(
      _$ClassicLoaderThemeDataImpl _value,
      $Res Function(_$ClassicLoaderThemeDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClassicLoaderThemeData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeColor = freezed,
    Object? duration = freezed,
    Object? radius = freezed,
  }) {
    return _then(_$ClassicLoaderThemeDataImpl(
      activeColor: freezed == activeColor
          ? _value.activeColor
          : activeColor // ignore: cast_nullable_to_non_nullable
              as Color?,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration?,
      radius: freezed == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc

class _$ClassicLoaderThemeDataImpl implements _ClassicLoaderThemeData {
  const _$ClassicLoaderThemeDataImpl(
      {this.activeColor, this.duration, this.radius});

  @override
  final Color? activeColor;
  @override
  final Duration? duration;
  @override
  final double? radius;

  @override
  String toString() {
    return 'ClassicLoaderThemeData(activeColor: $activeColor, duration: $duration, radius: $radius)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClassicLoaderThemeDataImpl &&
            (identical(other.activeColor, activeColor) ||
                other.activeColor == activeColor) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.radius, radius) || other.radius == radius));
  }

  @override
  int get hashCode => Object.hash(runtimeType, activeColor, duration, radius);

  /// Create a copy of ClassicLoaderThemeData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClassicLoaderThemeDataImplCopyWith<_$ClassicLoaderThemeDataImpl>
      get copyWith => __$$ClassicLoaderThemeDataImplCopyWithImpl<
          _$ClassicLoaderThemeDataImpl>(this, _$identity);
}

abstract class _ClassicLoaderThemeData implements ClassicLoaderThemeData {
  const factory _ClassicLoaderThemeData(
      {final Color? activeColor,
      final Duration? duration,
      final double? radius}) = _$ClassicLoaderThemeDataImpl;

  @override
  Color? get activeColor;
  @override
  Duration? get duration;
  @override
  double? get radius;

  /// Create a copy of ClassicLoaderThemeData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClassicLoaderThemeDataImplCopyWith<_$ClassicLoaderThemeDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}
