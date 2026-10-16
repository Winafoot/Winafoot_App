// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'disponibility_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DisponibilityModel _$DisponibilityModelFromJson(Map<String, dynamic> json) {
  return _DisponibilityModel.fromJson(json);
}

/// @nodoc
mixin _$DisponibilityModel {
  bool get isOpen => throw _privateConstructorUsedError;
  List<DisponibilityItemModel> get items => throw _privateConstructorUsedError;

  /// Serializes this DisponibilityModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DisponibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DisponibilityModelCopyWith<DisponibilityModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DisponibilityModelCopyWith<$Res> {
  factory $DisponibilityModelCopyWith(
          DisponibilityModel value, $Res Function(DisponibilityModel) then) =
      _$DisponibilityModelCopyWithImpl<$Res, DisponibilityModel>;
  @useResult
  $Res call({bool isOpen, List<DisponibilityItemModel> items});
}

/// @nodoc
class _$DisponibilityModelCopyWithImpl<$Res, $Val extends DisponibilityModel>
    implements $DisponibilityModelCopyWith<$Res> {
  _$DisponibilityModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DisponibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOpen = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      isOpen: null == isOpen
          ? _value.isOpen
          : isOpen // ignore: cast_nullable_to_non_nullable
              as bool,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DisponibilityItemModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DisponibilityModelImplCopyWith<$Res>
    implements $DisponibilityModelCopyWith<$Res> {
  factory _$$DisponibilityModelImplCopyWith(_$DisponibilityModelImpl value,
          $Res Function(_$DisponibilityModelImpl) then) =
      __$$DisponibilityModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isOpen, List<DisponibilityItemModel> items});
}

/// @nodoc
class __$$DisponibilityModelImplCopyWithImpl<$Res>
    extends _$DisponibilityModelCopyWithImpl<$Res, _$DisponibilityModelImpl>
    implements _$$DisponibilityModelImplCopyWith<$Res> {
  __$$DisponibilityModelImplCopyWithImpl(_$DisponibilityModelImpl _value,
      $Res Function(_$DisponibilityModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DisponibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOpen = null,
    Object? items = null,
  }) {
    return _then(_$DisponibilityModelImpl(
      isOpen: null == isOpen
          ? _value.isOpen
          : isOpen // ignore: cast_nullable_to_non_nullable
              as bool,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DisponibilityItemModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DisponibilityModelImpl implements _DisponibilityModel {
  const _$DisponibilityModelImpl(
      {this.isOpen = true, final List<DisponibilityItemModel> items = const []})
      : _items = items;

  factory _$DisponibilityModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DisponibilityModelImplFromJson(json);

  @override
  @JsonKey()
  final bool isOpen;
  final List<DisponibilityItemModel> _items;
  @override
  @JsonKey()
  List<DisponibilityItemModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'DisponibilityModel(isOpen: $isOpen, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DisponibilityModelImpl &&
            (identical(other.isOpen, isOpen) || other.isOpen == isOpen) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, isOpen, const DeepCollectionEquality().hash(_items));

  /// Create a copy of DisponibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DisponibilityModelImplCopyWith<_$DisponibilityModelImpl> get copyWith =>
      __$$DisponibilityModelImplCopyWithImpl<_$DisponibilityModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DisponibilityModelImplToJson(
      this,
    );
  }
}

abstract class _DisponibilityModel implements DisponibilityModel {
  const factory _DisponibilityModel(
      {final bool isOpen,
      final List<DisponibilityItemModel> items}) = _$DisponibilityModelImpl;

  factory _DisponibilityModel.fromJson(Map<String, dynamic> json) =
      _$DisponibilityModelImpl.fromJson;

  @override
  bool get isOpen;
  @override
  List<DisponibilityItemModel> get items;

  /// Create a copy of DisponibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DisponibilityModelImplCopyWith<_$DisponibilityModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DisponibilityItemModel _$DisponibilityItemModelFromJson(
    Map<String, dynamic> json) {
  return _DisponibilityItemModel.fromJson(json);
}

/// @nodoc
mixin _$DisponibilityItemModel {
  @TimestampConverter()
  DateTime? get from => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get to => throw _privateConstructorUsedError;
  bool get isPaused => throw _privateConstructorUsedError;

  /// Serializes this DisponibilityItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DisponibilityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DisponibilityItemModelCopyWith<DisponibilityItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DisponibilityItemModelCopyWith<$Res> {
  factory $DisponibilityItemModelCopyWith(DisponibilityItemModel value,
          $Res Function(DisponibilityItemModel) then) =
      _$DisponibilityItemModelCopyWithImpl<$Res, DisponibilityItemModel>;
  @useResult
  $Res call(
      {@TimestampConverter() DateTime? from,
      @TimestampConverter() DateTime? to,
      bool isPaused});
}

/// @nodoc
class _$DisponibilityItemModelCopyWithImpl<$Res,
        $Val extends DisponibilityItemModel>
    implements $DisponibilityItemModelCopyWith<$Res> {
  _$DisponibilityItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DisponibilityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? from = freezed,
    Object? to = freezed,
    Object? isPaused = null,
  }) {
    return _then(_value.copyWith(
      from: freezed == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      to: freezed == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPaused: null == isPaused
          ? _value.isPaused
          : isPaused // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DisponibilityItemModelImplCopyWith<$Res>
    implements $DisponibilityItemModelCopyWith<$Res> {
  factory _$$DisponibilityItemModelImplCopyWith(
          _$DisponibilityItemModelImpl value,
          $Res Function(_$DisponibilityItemModelImpl) then) =
      __$$DisponibilityItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@TimestampConverter() DateTime? from,
      @TimestampConverter() DateTime? to,
      bool isPaused});
}

/// @nodoc
class __$$DisponibilityItemModelImplCopyWithImpl<$Res>
    extends _$DisponibilityItemModelCopyWithImpl<$Res,
        _$DisponibilityItemModelImpl>
    implements _$$DisponibilityItemModelImplCopyWith<$Res> {
  __$$DisponibilityItemModelImplCopyWithImpl(
      _$DisponibilityItemModelImpl _value,
      $Res Function(_$DisponibilityItemModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DisponibilityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? from = freezed,
    Object? to = freezed,
    Object? isPaused = null,
  }) {
    return _then(_$DisponibilityItemModelImpl(
      from: freezed == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      to: freezed == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPaused: null == isPaused
          ? _value.isPaused
          : isPaused // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DisponibilityItemModelImpl implements _DisponibilityItemModel {
  const _$DisponibilityItemModelImpl(
      {@TimestampConverter() this.from,
      @TimestampConverter() this.to,
      this.isPaused = false});

  factory _$DisponibilityItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DisponibilityItemModelImplFromJson(json);

  @override
  @TimestampConverter()
  final DateTime? from;
  @override
  @TimestampConverter()
  final DateTime? to;
  @override
  @JsonKey()
  final bool isPaused;

  @override
  String toString() {
    return 'DisponibilityItemModel(from: $from, to: $to, isPaused: $isPaused)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DisponibilityItemModelImpl &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.isPaused, isPaused) ||
                other.isPaused == isPaused));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, from, to, isPaused);

  /// Create a copy of DisponibilityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DisponibilityItemModelImplCopyWith<_$DisponibilityItemModelImpl>
      get copyWith => __$$DisponibilityItemModelImplCopyWithImpl<
          _$DisponibilityItemModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DisponibilityItemModelImplToJson(
      this,
    );
  }
}

abstract class _DisponibilityItemModel implements DisponibilityItemModel {
  const factory _DisponibilityItemModel(
      {@TimestampConverter() final DateTime? from,
      @TimestampConverter() final DateTime? to,
      final bool isPaused}) = _$DisponibilityItemModelImpl;

  factory _DisponibilityItemModel.fromJson(Map<String, dynamic> json) =
      _$DisponibilityItemModelImpl.fromJson;

  @override
  @TimestampConverter()
  DateTime? get from;
  @override
  @TimestampConverter()
  DateTime? get to;
  @override
  bool get isPaused;

  /// Create a copy of DisponibilityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DisponibilityItemModelImplCopyWith<_$DisponibilityItemModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
