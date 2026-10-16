// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stripe_fees_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StripeFeesModel _$StripeFeesModelFromJson(Map<String, dynamic> json) {
  return _StripeFeesModel.fromJson(json);
}

/// @nodoc
mixin _$StripeFeesModel {
  num? get percent => throw _privateConstructorUsedError;
  num? get fixAmount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StripeFeesModelCopyWith<StripeFeesModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StripeFeesModelCopyWith<$Res> {
  factory $StripeFeesModelCopyWith(
          StripeFeesModel value, $Res Function(StripeFeesModel) then) =
      _$StripeFeesModelCopyWithImpl<$Res, StripeFeesModel>;
  @useResult
  $Res call({num? percent, num? fixAmount});
}

/// @nodoc
class _$StripeFeesModelCopyWithImpl<$Res, $Val extends StripeFeesModel>
    implements $StripeFeesModelCopyWith<$Res> {
  _$StripeFeesModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? percent = freezed,
    Object? fixAmount = freezed,
  }) {
    return _then(_value.copyWith(
      percent: freezed == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as num?,
      fixAmount: freezed == fixAmount
          ? _value.fixAmount
          : fixAmount // ignore: cast_nullable_to_non_nullable
              as num?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StripeFeesModelImplCopyWith<$Res>
    implements $StripeFeesModelCopyWith<$Res> {
  factory _$$StripeFeesModelImplCopyWith(_$StripeFeesModelImpl value,
          $Res Function(_$StripeFeesModelImpl) then) =
      __$$StripeFeesModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({num? percent, num? fixAmount});
}

/// @nodoc
class __$$StripeFeesModelImplCopyWithImpl<$Res>
    extends _$StripeFeesModelCopyWithImpl<$Res, _$StripeFeesModelImpl>
    implements _$$StripeFeesModelImplCopyWith<$Res> {
  __$$StripeFeesModelImplCopyWithImpl(
      _$StripeFeesModelImpl _value, $Res Function(_$StripeFeesModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? percent = freezed,
    Object? fixAmount = freezed,
  }) {
    return _then(_$StripeFeesModelImpl(
      percent: freezed == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as num?,
      fixAmount: freezed == fixAmount
          ? _value.fixAmount
          : fixAmount // ignore: cast_nullable_to_non_nullable
              as num?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StripeFeesModelImpl implements _StripeFeesModel {
  const _$StripeFeesModelImpl({this.percent, this.fixAmount});

  factory _$StripeFeesModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StripeFeesModelImplFromJson(json);

  @override
  final num? percent;
  @override
  final num? fixAmount;

  @override
  String toString() {
    return 'StripeFeesModel(percent: $percent, fixAmount: $fixAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StripeFeesModelImpl &&
            (identical(other.percent, percent) || other.percent == percent) &&
            (identical(other.fixAmount, fixAmount) ||
                other.fixAmount == fixAmount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, percent, fixAmount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StripeFeesModelImplCopyWith<_$StripeFeesModelImpl> get copyWith =>
      __$$StripeFeesModelImplCopyWithImpl<_$StripeFeesModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StripeFeesModelImplToJson(
      this,
    );
  }
}

abstract class _StripeFeesModel implements StripeFeesModel {
  const factory _StripeFeesModel({final num? percent, final num? fixAmount}) =
      _$StripeFeesModelImpl;

  factory _StripeFeesModel.fromJson(Map<String, dynamic> json) =
      _$StripeFeesModelImpl.fromJson;

  @override
  num? get percent;
  @override
  num? get fixAmount;
  @override
  @JsonKey(ignore: true)
  _$$StripeFeesModelImplCopyWith<_$StripeFeesModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
