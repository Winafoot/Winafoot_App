// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_theme.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SkeletonSettingsThemeData {
  Color? get actionIconColor => throw _privateConstructorUsedError;

  /// Create a copy of SkeletonSettingsThemeData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkeletonSettingsThemeDataCopyWith<SkeletonSettingsThemeData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkeletonSettingsThemeDataCopyWith<$Res> {
  factory $SkeletonSettingsThemeDataCopyWith(SkeletonSettingsThemeData value,
          $Res Function(SkeletonSettingsThemeData) then) =
      _$SkeletonSettingsThemeDataCopyWithImpl<$Res, SkeletonSettingsThemeData>;
  @useResult
  $Res call({Color? actionIconColor});
}

/// @nodoc
class _$SkeletonSettingsThemeDataCopyWithImpl<$Res,
        $Val extends SkeletonSettingsThemeData>
    implements $SkeletonSettingsThemeDataCopyWith<$Res> {
  _$SkeletonSettingsThemeDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkeletonSettingsThemeData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? actionIconColor = freezed,
  }) {
    return _then(_value.copyWith(
      actionIconColor: freezed == actionIconColor
          ? _value.actionIconColor
          : actionIconColor // ignore: cast_nullable_to_non_nullable
              as Color?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SkeletonSettingsThemeDataImplCopyWith<$Res>
    implements $SkeletonSettingsThemeDataCopyWith<$Res> {
  factory _$$SkeletonSettingsThemeDataImplCopyWith(
          _$SkeletonSettingsThemeDataImpl value,
          $Res Function(_$SkeletonSettingsThemeDataImpl) then) =
      __$$SkeletonSettingsThemeDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Color? actionIconColor});
}

/// @nodoc
class __$$SkeletonSettingsThemeDataImplCopyWithImpl<$Res>
    extends _$SkeletonSettingsThemeDataCopyWithImpl<$Res,
        _$SkeletonSettingsThemeDataImpl>
    implements _$$SkeletonSettingsThemeDataImplCopyWith<$Res> {
  __$$SkeletonSettingsThemeDataImplCopyWithImpl(
      _$SkeletonSettingsThemeDataImpl _value,
      $Res Function(_$SkeletonSettingsThemeDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SkeletonSettingsThemeData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? actionIconColor = freezed,
  }) {
    return _then(_$SkeletonSettingsThemeDataImpl(
      actionIconColor: freezed == actionIconColor
          ? _value.actionIconColor
          : actionIconColor // ignore: cast_nullable_to_non_nullable
              as Color?,
    ));
  }
}

/// @nodoc

class _$SkeletonSettingsThemeDataImpl implements _SkeletonSettingsThemeData {
  const _$SkeletonSettingsThemeDataImpl({this.actionIconColor});

  @override
  final Color? actionIconColor;

  @override
  String toString() {
    return 'SkeletonSettingsThemeData(actionIconColor: $actionIconColor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkeletonSettingsThemeDataImpl &&
            (identical(other.actionIconColor, actionIconColor) ||
                other.actionIconColor == actionIconColor));
  }

  @override
  int get hashCode => Object.hash(runtimeType, actionIconColor);

  /// Create a copy of SkeletonSettingsThemeData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkeletonSettingsThemeDataImplCopyWith<_$SkeletonSettingsThemeDataImpl>
      get copyWith => __$$SkeletonSettingsThemeDataImplCopyWithImpl<
          _$SkeletonSettingsThemeDataImpl>(this, _$identity);
}

abstract class _SkeletonSettingsThemeData implements SkeletonSettingsThemeData {
  const factory _SkeletonSettingsThemeData({final Color? actionIconColor}) =
      _$SkeletonSettingsThemeDataImpl;

  @override
  Color? get actionIconColor;

  /// Create a copy of SkeletonSettingsThemeData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkeletonSettingsThemeDataImplCopyWith<_$SkeletonSettingsThemeDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}
