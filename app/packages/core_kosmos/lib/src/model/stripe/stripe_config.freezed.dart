// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stripe_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StripeConfig _$StripeConfigFromJson(Map<String, dynamic> json) {
  return _StripeConfig.fromJson(json);
}

/// @nodoc
mixin _$StripeConfig {
  String get publishableKey => throw _privateConstructorUsedError;
  String? get publishableProdKey => throw _privateConstructorUsedError;
  bool get isProdMode => throw _privateConstructorUsedError;
  String get merchantIdentifier => throw _privateConstructorUsedError;
  String get urlScheme => throw _privateConstructorUsedError;
  List<String> get testEmail => throw _privateConstructorUsedError;
  StripeFeesModel? get stripeCommission => throw _privateConstructorUsedError;

  /// Merchant Data
  String? get defaultMerchantName => throw _privateConstructorUsedError;

  /// iOS only
  dynamic get enableApplePay => throw _privateConstructorUsedError;

  /// Android only
  dynamic get enableGooglePay => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StripeConfigCopyWith<StripeConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StripeConfigCopyWith<$Res> {
  factory $StripeConfigCopyWith(
          StripeConfig value, $Res Function(StripeConfig) then) =
      _$StripeConfigCopyWithImpl<$Res, StripeConfig>;
  @useResult
  $Res call(
      {String publishableKey,
      String? publishableProdKey,
      bool isProdMode,
      String merchantIdentifier,
      String urlScheme,
      List<String> testEmail,
      StripeFeesModel? stripeCommission,
      String? defaultMerchantName,
      dynamic enableApplePay,
      dynamic enableGooglePay});

  $StripeFeesModelCopyWith<$Res>? get stripeCommission;
}

/// @nodoc
class _$StripeConfigCopyWithImpl<$Res, $Val extends StripeConfig>
    implements $StripeConfigCopyWith<$Res> {
  _$StripeConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publishableKey = null,
    Object? publishableProdKey = freezed,
    Object? isProdMode = null,
    Object? merchantIdentifier = null,
    Object? urlScheme = null,
    Object? testEmail = null,
    Object? stripeCommission = freezed,
    Object? defaultMerchantName = freezed,
    Object? enableApplePay = freezed,
    Object? enableGooglePay = freezed,
  }) {
    return _then(_value.copyWith(
      publishableKey: null == publishableKey
          ? _value.publishableKey
          : publishableKey // ignore: cast_nullable_to_non_nullable
              as String,
      publishableProdKey: freezed == publishableProdKey
          ? _value.publishableProdKey
          : publishableProdKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isProdMode: null == isProdMode
          ? _value.isProdMode
          : isProdMode // ignore: cast_nullable_to_non_nullable
              as bool,
      merchantIdentifier: null == merchantIdentifier
          ? _value.merchantIdentifier
          : merchantIdentifier // ignore: cast_nullable_to_non_nullable
              as String,
      urlScheme: null == urlScheme
          ? _value.urlScheme
          : urlScheme // ignore: cast_nullable_to_non_nullable
              as String,
      testEmail: null == testEmail
          ? _value.testEmail
          : testEmail // ignore: cast_nullable_to_non_nullable
              as List<String>,
      stripeCommission: freezed == stripeCommission
          ? _value.stripeCommission
          : stripeCommission // ignore: cast_nullable_to_non_nullable
              as StripeFeesModel?,
      defaultMerchantName: freezed == defaultMerchantName
          ? _value.defaultMerchantName
          : defaultMerchantName // ignore: cast_nullable_to_non_nullable
              as String?,
      enableApplePay: freezed == enableApplePay
          ? _value.enableApplePay
          : enableApplePay // ignore: cast_nullable_to_non_nullable
              as dynamic,
      enableGooglePay: freezed == enableGooglePay
          ? _value.enableGooglePay
          : enableGooglePay // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $StripeFeesModelCopyWith<$Res>? get stripeCommission {
    if (_value.stripeCommission == null) {
      return null;
    }

    return $StripeFeesModelCopyWith<$Res>(_value.stripeCommission!, (value) {
      return _then(_value.copyWith(stripeCommission: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StripeConfigImplCopyWith<$Res>
    implements $StripeConfigCopyWith<$Res> {
  factory _$$StripeConfigImplCopyWith(
          _$StripeConfigImpl value, $Res Function(_$StripeConfigImpl) then) =
      __$$StripeConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String publishableKey,
      String? publishableProdKey,
      bool isProdMode,
      String merchantIdentifier,
      String urlScheme,
      List<String> testEmail,
      StripeFeesModel? stripeCommission,
      String? defaultMerchantName,
      dynamic enableApplePay,
      dynamic enableGooglePay});

  @override
  $StripeFeesModelCopyWith<$Res>? get stripeCommission;
}

/// @nodoc
class __$$StripeConfigImplCopyWithImpl<$Res>
    extends _$StripeConfigCopyWithImpl<$Res, _$StripeConfigImpl>
    implements _$$StripeConfigImplCopyWith<$Res> {
  __$$StripeConfigImplCopyWithImpl(
      _$StripeConfigImpl _value, $Res Function(_$StripeConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publishableKey = null,
    Object? publishableProdKey = freezed,
    Object? isProdMode = null,
    Object? merchantIdentifier = null,
    Object? urlScheme = null,
    Object? testEmail = null,
    Object? stripeCommission = freezed,
    Object? defaultMerchantName = freezed,
    Object? enableApplePay = freezed,
    Object? enableGooglePay = freezed,
  }) {
    return _then(_$StripeConfigImpl(
      publishableKey: null == publishableKey
          ? _value.publishableKey
          : publishableKey // ignore: cast_nullable_to_non_nullable
              as String,
      publishableProdKey: freezed == publishableProdKey
          ? _value.publishableProdKey
          : publishableProdKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isProdMode: null == isProdMode
          ? _value.isProdMode
          : isProdMode // ignore: cast_nullable_to_non_nullable
              as bool,
      merchantIdentifier: null == merchantIdentifier
          ? _value.merchantIdentifier
          : merchantIdentifier // ignore: cast_nullable_to_non_nullable
              as String,
      urlScheme: null == urlScheme
          ? _value.urlScheme
          : urlScheme // ignore: cast_nullable_to_non_nullable
              as String,
      testEmail: null == testEmail
          ? _value._testEmail
          : testEmail // ignore: cast_nullable_to_non_nullable
              as List<String>,
      stripeCommission: freezed == stripeCommission
          ? _value.stripeCommission
          : stripeCommission // ignore: cast_nullable_to_non_nullable
              as StripeFeesModel?,
      defaultMerchantName: freezed == defaultMerchantName
          ? _value.defaultMerchantName
          : defaultMerchantName // ignore: cast_nullable_to_non_nullable
              as String?,
      enableApplePay:
          freezed == enableApplePay ? _value.enableApplePay! : enableApplePay,
      enableGooglePay: freezed == enableGooglePay
          ? _value.enableGooglePay!
          : enableGooglePay,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StripeConfigImpl implements _StripeConfig {
  const _$StripeConfigImpl(
      {required this.publishableKey,
      this.publishableProdKey,
      this.isProdMode = false,
      required this.merchantIdentifier,
      required this.urlScheme,
      final List<String> testEmail = const [],
      this.stripeCommission,
      this.defaultMerchantName,
      this.enableApplePay = false,
      this.enableGooglePay = false})
      : _testEmail = testEmail;

  factory _$StripeConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$StripeConfigImplFromJson(json);

  @override
  final String publishableKey;
  @override
  final String? publishableProdKey;
  @override
  @JsonKey()
  final bool isProdMode;
  @override
  final String merchantIdentifier;
  @override
  final String urlScheme;
  final List<String> _testEmail;
  @override
  @JsonKey()
  List<String> get testEmail {
    if (_testEmail is EqualUnmodifiableListView) return _testEmail;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_testEmail);
  }

  @override
  final StripeFeesModel? stripeCommission;

  /// Merchant Data
  @override
  final String? defaultMerchantName;

  /// iOS only
  @override
  @JsonKey()
  final dynamic enableApplePay;

  /// Android only
  @override
  @JsonKey()
  final dynamic enableGooglePay;

  @override
  String toString() {
    return 'StripeConfig(publishableKey: $publishableKey, publishableProdKey: $publishableProdKey, isProdMode: $isProdMode, merchantIdentifier: $merchantIdentifier, urlScheme: $urlScheme, testEmail: $testEmail, stripeCommission: $stripeCommission, defaultMerchantName: $defaultMerchantName, enableApplePay: $enableApplePay, enableGooglePay: $enableGooglePay)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StripeConfigImpl &&
            (identical(other.publishableKey, publishableKey) ||
                other.publishableKey == publishableKey) &&
            (identical(other.publishableProdKey, publishableProdKey) ||
                other.publishableProdKey == publishableProdKey) &&
            (identical(other.isProdMode, isProdMode) ||
                other.isProdMode == isProdMode) &&
            (identical(other.merchantIdentifier, merchantIdentifier) ||
                other.merchantIdentifier == merchantIdentifier) &&
            (identical(other.urlScheme, urlScheme) ||
                other.urlScheme == urlScheme) &&
            const DeepCollectionEquality()
                .equals(other._testEmail, _testEmail) &&
            (identical(other.stripeCommission, stripeCommission) ||
                other.stripeCommission == stripeCommission) &&
            (identical(other.defaultMerchantName, defaultMerchantName) ||
                other.defaultMerchantName == defaultMerchantName) &&
            const DeepCollectionEquality()
                .equals(other.enableApplePay, enableApplePay) &&
            const DeepCollectionEquality()
                .equals(other.enableGooglePay, enableGooglePay));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      publishableKey,
      publishableProdKey,
      isProdMode,
      merchantIdentifier,
      urlScheme,
      const DeepCollectionEquality().hash(_testEmail),
      stripeCommission,
      defaultMerchantName,
      const DeepCollectionEquality().hash(enableApplePay),
      const DeepCollectionEquality().hash(enableGooglePay));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StripeConfigImplCopyWith<_$StripeConfigImpl> get copyWith =>
      __$$StripeConfigImplCopyWithImpl<_$StripeConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StripeConfigImplToJson(
      this,
    );
  }
}

abstract class _StripeConfig implements StripeConfig {
  const factory _StripeConfig(
      {required final String publishableKey,
      final String? publishableProdKey,
      final bool isProdMode,
      required final String merchantIdentifier,
      required final String urlScheme,
      final List<String> testEmail,
      final StripeFeesModel? stripeCommission,
      final String? defaultMerchantName,
      final dynamic enableApplePay,
      final dynamic enableGooglePay}) = _$StripeConfigImpl;

  factory _StripeConfig.fromJson(Map<String, dynamic> json) =
      _$StripeConfigImpl.fromJson;

  @override
  String get publishableKey;
  @override
  String? get publishableProdKey;
  @override
  bool get isProdMode;
  @override
  String get merchantIdentifier;
  @override
  String get urlScheme;
  @override
  List<String> get testEmail;
  @override
  StripeFeesModel? get stripeCommission;
  @override

  /// Merchant Data
  String? get defaultMerchantName;
  @override

  /// iOS only
  dynamic get enableApplePay;
  @override

  /// Android only
  dynamic get enableGooglePay;
  @override
  @JsonKey(ignore: true)
  _$$StripeConfigImplCopyWith<_$StripeConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
