// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metadata_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppMetadataConfig _$AppMetadataConfigFromJson(Map<String, dynamic> json) {
  return _AppMetadataConfig.fromJson(json);
}

/// @nodoc
mixin _$AppMetadataConfig {
  /// Security
  String? get appHash => throw _privateConstructorUsedError;

  /// Share
  String? get shareMessage => throw _privateConstructorUsedError;

  /// Legal documents
  String? get cgvu => throw _privateConstructorUsedError;
  String? get confidentialityPolicy => throw _privateConstructorUsedError;
  String? get legalNotice => throw _privateConstructorUsedError;
  String? get about => throw _privateConstructorUsedError;

  /// Contact
  String? get contactEmail => throw _privateConstructorUsedError;
  String? get contactPhone => throw _privateConstructorUsedError;

  /// Social Network
  String? get facebookUrl => throw _privateConstructorUsedError;
  String? get instagramUrl => throw _privateConstructorUsedError;
  String? get twitterUrl => throw _privateConstructorUsedError;
  String? get youtubeUrl => throw _privateConstructorUsedError;
  String? get linkedinUrl => throw _privateConstructorUsedError;
  String? get snapchatUrl => throw _privateConstructorUsedError;
  String? get tiktokUrl => throw _privateConstructorUsedError;
  bool get activateInAppPurchase => throw _privateConstructorUsedError;

  /// Security Strenght
  PasswordSecurityConfig get passwordSecurityConfig =>
      throw _privateConstructorUsedError;
  StripeConfig? get stripeConfig => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AppMetadataConfigCopyWith<AppMetadataConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppMetadataConfigCopyWith<$Res> {
  factory $AppMetadataConfigCopyWith(
          AppMetadataConfig value, $Res Function(AppMetadataConfig) then) =
      _$AppMetadataConfigCopyWithImpl<$Res, AppMetadataConfig>;
  @useResult
  $Res call(
      {String? appHash,
      String? shareMessage,
      String? cgvu,
      String? confidentialityPolicy,
      String? legalNotice,
      String? about,
      String? contactEmail,
      String? contactPhone,
      String? facebookUrl,
      String? instagramUrl,
      String? twitterUrl,
      String? youtubeUrl,
      String? linkedinUrl,
      String? snapchatUrl,
      String? tiktokUrl,
      bool activateInAppPurchase,
      PasswordSecurityConfig passwordSecurityConfig,
      StripeConfig? stripeConfig});

  $PasswordSecurityConfigCopyWith<$Res> get passwordSecurityConfig;
  $StripeConfigCopyWith<$Res>? get stripeConfig;
}

/// @nodoc
class _$AppMetadataConfigCopyWithImpl<$Res, $Val extends AppMetadataConfig>
    implements $AppMetadataConfigCopyWith<$Res> {
  _$AppMetadataConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? appHash = freezed,
    Object? shareMessage = freezed,
    Object? cgvu = freezed,
    Object? confidentialityPolicy = freezed,
    Object? legalNotice = freezed,
    Object? about = freezed,
    Object? contactEmail = freezed,
    Object? contactPhone = freezed,
    Object? facebookUrl = freezed,
    Object? instagramUrl = freezed,
    Object? twitterUrl = freezed,
    Object? youtubeUrl = freezed,
    Object? linkedinUrl = freezed,
    Object? snapchatUrl = freezed,
    Object? tiktokUrl = freezed,
    Object? activateInAppPurchase = null,
    Object? passwordSecurityConfig = null,
    Object? stripeConfig = freezed,
  }) {
    return _then(_value.copyWith(
      appHash: freezed == appHash
          ? _value.appHash
          : appHash // ignore: cast_nullable_to_non_nullable
              as String?,
      shareMessage: freezed == shareMessage
          ? _value.shareMessage
          : shareMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      cgvu: freezed == cgvu
          ? _value.cgvu
          : cgvu // ignore: cast_nullable_to_non_nullable
              as String?,
      confidentialityPolicy: freezed == confidentialityPolicy
          ? _value.confidentialityPolicy
          : confidentialityPolicy // ignore: cast_nullable_to_non_nullable
              as String?,
      legalNotice: freezed == legalNotice
          ? _value.legalNotice
          : legalNotice // ignore: cast_nullable_to_non_nullable
              as String?,
      about: freezed == about
          ? _value.about
          : about // ignore: cast_nullable_to_non_nullable
              as String?,
      contactEmail: freezed == contactEmail
          ? _value.contactEmail
          : contactEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      contactPhone: freezed == contactPhone
          ? _value.contactPhone
          : contactPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      facebookUrl: freezed == facebookUrl
          ? _value.facebookUrl
          : facebookUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramUrl: freezed == instagramUrl
          ? _value.instagramUrl
          : instagramUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      twitterUrl: freezed == twitterUrl
          ? _value.twitterUrl
          : twitterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeUrl: freezed == youtubeUrl
          ? _value.youtubeUrl
          : youtubeUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      linkedinUrl: freezed == linkedinUrl
          ? _value.linkedinUrl
          : linkedinUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      snapchatUrl: freezed == snapchatUrl
          ? _value.snapchatUrl
          : snapchatUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tiktokUrl: freezed == tiktokUrl
          ? _value.tiktokUrl
          : tiktokUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      activateInAppPurchase: null == activateInAppPurchase
          ? _value.activateInAppPurchase
          : activateInAppPurchase // ignore: cast_nullable_to_non_nullable
              as bool,
      passwordSecurityConfig: null == passwordSecurityConfig
          ? _value.passwordSecurityConfig
          : passwordSecurityConfig // ignore: cast_nullable_to_non_nullable
              as PasswordSecurityConfig,
      stripeConfig: freezed == stripeConfig
          ? _value.stripeConfig
          : stripeConfig // ignore: cast_nullable_to_non_nullable
              as StripeConfig?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PasswordSecurityConfigCopyWith<$Res> get passwordSecurityConfig {
    return $PasswordSecurityConfigCopyWith<$Res>(_value.passwordSecurityConfig,
        (value) {
      return _then(_value.copyWith(passwordSecurityConfig: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $StripeConfigCopyWith<$Res>? get stripeConfig {
    if (_value.stripeConfig == null) {
      return null;
    }

    return $StripeConfigCopyWith<$Res>(_value.stripeConfig!, (value) {
      return _then(_value.copyWith(stripeConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AppMetadataConfigImplCopyWith<$Res>
    implements $AppMetadataConfigCopyWith<$Res> {
  factory _$$AppMetadataConfigImplCopyWith(_$AppMetadataConfigImpl value,
          $Res Function(_$AppMetadataConfigImpl) then) =
      __$$AppMetadataConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? appHash,
      String? shareMessage,
      String? cgvu,
      String? confidentialityPolicy,
      String? legalNotice,
      String? about,
      String? contactEmail,
      String? contactPhone,
      String? facebookUrl,
      String? instagramUrl,
      String? twitterUrl,
      String? youtubeUrl,
      String? linkedinUrl,
      String? snapchatUrl,
      String? tiktokUrl,
      bool activateInAppPurchase,
      PasswordSecurityConfig passwordSecurityConfig,
      StripeConfig? stripeConfig});

  @override
  $PasswordSecurityConfigCopyWith<$Res> get passwordSecurityConfig;
  @override
  $StripeConfigCopyWith<$Res>? get stripeConfig;
}

/// @nodoc
class __$$AppMetadataConfigImplCopyWithImpl<$Res>
    extends _$AppMetadataConfigCopyWithImpl<$Res, _$AppMetadataConfigImpl>
    implements _$$AppMetadataConfigImplCopyWith<$Res> {
  __$$AppMetadataConfigImplCopyWithImpl(_$AppMetadataConfigImpl _value,
      $Res Function(_$AppMetadataConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? appHash = freezed,
    Object? shareMessage = freezed,
    Object? cgvu = freezed,
    Object? confidentialityPolicy = freezed,
    Object? legalNotice = freezed,
    Object? about = freezed,
    Object? contactEmail = freezed,
    Object? contactPhone = freezed,
    Object? facebookUrl = freezed,
    Object? instagramUrl = freezed,
    Object? twitterUrl = freezed,
    Object? youtubeUrl = freezed,
    Object? linkedinUrl = freezed,
    Object? snapchatUrl = freezed,
    Object? tiktokUrl = freezed,
    Object? activateInAppPurchase = null,
    Object? passwordSecurityConfig = null,
    Object? stripeConfig = freezed,
  }) {
    return _then(_$AppMetadataConfigImpl(
      appHash: freezed == appHash
          ? _value.appHash
          : appHash // ignore: cast_nullable_to_non_nullable
              as String?,
      shareMessage: freezed == shareMessage
          ? _value.shareMessage
          : shareMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      cgvu: freezed == cgvu
          ? _value.cgvu
          : cgvu // ignore: cast_nullable_to_non_nullable
              as String?,
      confidentialityPolicy: freezed == confidentialityPolicy
          ? _value.confidentialityPolicy
          : confidentialityPolicy // ignore: cast_nullable_to_non_nullable
              as String?,
      legalNotice: freezed == legalNotice
          ? _value.legalNotice
          : legalNotice // ignore: cast_nullable_to_non_nullable
              as String?,
      about: freezed == about
          ? _value.about
          : about // ignore: cast_nullable_to_non_nullable
              as String?,
      contactEmail: freezed == contactEmail
          ? _value.contactEmail
          : contactEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      contactPhone: freezed == contactPhone
          ? _value.contactPhone
          : contactPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      facebookUrl: freezed == facebookUrl
          ? _value.facebookUrl
          : facebookUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramUrl: freezed == instagramUrl
          ? _value.instagramUrl
          : instagramUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      twitterUrl: freezed == twitterUrl
          ? _value.twitterUrl
          : twitterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeUrl: freezed == youtubeUrl
          ? _value.youtubeUrl
          : youtubeUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      linkedinUrl: freezed == linkedinUrl
          ? _value.linkedinUrl
          : linkedinUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      snapchatUrl: freezed == snapchatUrl
          ? _value.snapchatUrl
          : snapchatUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tiktokUrl: freezed == tiktokUrl
          ? _value.tiktokUrl
          : tiktokUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      activateInAppPurchase: null == activateInAppPurchase
          ? _value.activateInAppPurchase
          : activateInAppPurchase // ignore: cast_nullable_to_non_nullable
              as bool,
      passwordSecurityConfig: null == passwordSecurityConfig
          ? _value.passwordSecurityConfig
          : passwordSecurityConfig // ignore: cast_nullable_to_non_nullable
              as PasswordSecurityConfig,
      stripeConfig: freezed == stripeConfig
          ? _value.stripeConfig
          : stripeConfig // ignore: cast_nullable_to_non_nullable
              as StripeConfig?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppMetadataConfigImpl implements _AppMetadataConfig {
  const _$AppMetadataConfigImpl(
      {this.appHash,
      this.shareMessage,
      this.cgvu,
      this.confidentialityPolicy,
      this.legalNotice,
      this.about,
      this.contactEmail,
      this.contactPhone,
      this.facebookUrl,
      this.instagramUrl,
      this.twitterUrl,
      this.youtubeUrl,
      this.linkedinUrl,
      this.snapchatUrl,
      this.tiktokUrl,
      this.activateInAppPurchase = true,
      this.passwordSecurityConfig = const PasswordSecurityConfig(),
      this.stripeConfig});

  factory _$AppMetadataConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppMetadataConfigImplFromJson(json);

  /// Security
  @override
  final String? appHash;

  /// Share
  @override
  final String? shareMessage;

  /// Legal documents
  @override
  final String? cgvu;
  @override
  final String? confidentialityPolicy;
  @override
  final String? legalNotice;
  @override
  final String? about;

  /// Contact
  @override
  final String? contactEmail;
  @override
  final String? contactPhone;

  /// Social Network
  @override
  final String? facebookUrl;
  @override
  final String? instagramUrl;
  @override
  final String? twitterUrl;
  @override
  final String? youtubeUrl;
  @override
  final String? linkedinUrl;
  @override
  final String? snapchatUrl;
  @override
  final String? tiktokUrl;
  @override
  @JsonKey()
  final bool activateInAppPurchase;

  /// Security Strenght
  @override
  @JsonKey()
  final PasswordSecurityConfig passwordSecurityConfig;
  @override
  final StripeConfig? stripeConfig;

  @override
  String toString() {
    return 'AppMetadataConfig(appHash: $appHash, shareMessage: $shareMessage, cgvu: $cgvu, confidentialityPolicy: $confidentialityPolicy, legalNotice: $legalNotice, about: $about, contactEmail: $contactEmail, contactPhone: $contactPhone, facebookUrl: $facebookUrl, instagramUrl: $instagramUrl, twitterUrl: $twitterUrl, youtubeUrl: $youtubeUrl, linkedinUrl: $linkedinUrl, snapchatUrl: $snapchatUrl, tiktokUrl: $tiktokUrl, activateInAppPurchase: $activateInAppPurchase, passwordSecurityConfig: $passwordSecurityConfig, stripeConfig: $stripeConfig)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppMetadataConfigImpl &&
            (identical(other.appHash, appHash) || other.appHash == appHash) &&
            (identical(other.shareMessage, shareMessage) ||
                other.shareMessage == shareMessage) &&
            (identical(other.cgvu, cgvu) || other.cgvu == cgvu) &&
            (identical(other.confidentialityPolicy, confidentialityPolicy) ||
                other.confidentialityPolicy == confidentialityPolicy) &&
            (identical(other.legalNotice, legalNotice) ||
                other.legalNotice == legalNotice) &&
            (identical(other.about, about) || other.about == about) &&
            (identical(other.contactEmail, contactEmail) ||
                other.contactEmail == contactEmail) &&
            (identical(other.contactPhone, contactPhone) ||
                other.contactPhone == contactPhone) &&
            (identical(other.facebookUrl, facebookUrl) ||
                other.facebookUrl == facebookUrl) &&
            (identical(other.instagramUrl, instagramUrl) ||
                other.instagramUrl == instagramUrl) &&
            (identical(other.twitterUrl, twitterUrl) ||
                other.twitterUrl == twitterUrl) &&
            (identical(other.youtubeUrl, youtubeUrl) ||
                other.youtubeUrl == youtubeUrl) &&
            (identical(other.linkedinUrl, linkedinUrl) ||
                other.linkedinUrl == linkedinUrl) &&
            (identical(other.snapchatUrl, snapchatUrl) ||
                other.snapchatUrl == snapchatUrl) &&
            (identical(other.tiktokUrl, tiktokUrl) ||
                other.tiktokUrl == tiktokUrl) &&
            (identical(other.activateInAppPurchase, activateInAppPurchase) ||
                other.activateInAppPurchase == activateInAppPurchase) &&
            (identical(other.passwordSecurityConfig, passwordSecurityConfig) ||
                other.passwordSecurityConfig == passwordSecurityConfig) &&
            (identical(other.stripeConfig, stripeConfig) ||
                other.stripeConfig == stripeConfig));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      appHash,
      shareMessage,
      cgvu,
      confidentialityPolicy,
      legalNotice,
      about,
      contactEmail,
      contactPhone,
      facebookUrl,
      instagramUrl,
      twitterUrl,
      youtubeUrl,
      linkedinUrl,
      snapchatUrl,
      tiktokUrl,
      activateInAppPurchase,
      passwordSecurityConfig,
      stripeConfig);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppMetadataConfigImplCopyWith<_$AppMetadataConfigImpl> get copyWith =>
      __$$AppMetadataConfigImplCopyWithImpl<_$AppMetadataConfigImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppMetadataConfigImplToJson(
      this,
    );
  }
}

abstract class _AppMetadataConfig implements AppMetadataConfig {
  const factory _AppMetadataConfig(
      {final String? appHash,
      final String? shareMessage,
      final String? cgvu,
      final String? confidentialityPolicy,
      final String? legalNotice,
      final String? about,
      final String? contactEmail,
      final String? contactPhone,
      final String? facebookUrl,
      final String? instagramUrl,
      final String? twitterUrl,
      final String? youtubeUrl,
      final String? linkedinUrl,
      final String? snapchatUrl,
      final String? tiktokUrl,
      final bool activateInAppPurchase,
      final PasswordSecurityConfig passwordSecurityConfig,
      final StripeConfig? stripeConfig}) = _$AppMetadataConfigImpl;

  factory _AppMetadataConfig.fromJson(Map<String, dynamic> json) =
      _$AppMetadataConfigImpl.fromJson;

  @override

  /// Security
  String? get appHash;
  @override

  /// Share
  String? get shareMessage;
  @override

  /// Legal documents
  String? get cgvu;
  @override
  String? get confidentialityPolicy;
  @override
  String? get legalNotice;
  @override
  String? get about;
  @override

  /// Contact
  String? get contactEmail;
  @override
  String? get contactPhone;
  @override

  /// Social Network
  String? get facebookUrl;
  @override
  String? get instagramUrl;
  @override
  String? get twitterUrl;
  @override
  String? get youtubeUrl;
  @override
  String? get linkedinUrl;
  @override
  String? get snapchatUrl;
  @override
  String? get tiktokUrl;
  @override
  bool get activateInAppPurchase;
  @override

  /// Security Strenght
  PasswordSecurityConfig get passwordSecurityConfig;
  @override
  StripeConfig? get stripeConfig;
  @override
  @JsonKey(ignore: true)
  _$$AppMetadataConfigImplCopyWith<_$AppMetadataConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PasswordSecurityConfig _$PasswordSecurityConfigFromJson(
    Map<String, dynamic> json) {
  return _PasswordSecurityConfig.fromJson(json);
}

/// @nodoc
mixin _$PasswordSecurityConfig {
  bool get atLeast6Char => throw _privateConstructorUsedError;
  num get passwordMinimalLength => throw _privateConstructorUsedError;
  bool get atLeast1Number => throw _privateConstructorUsedError;
  bool get atLeast1SpecialChar => throw _privateConstructorUsedError;
  bool get atLeast1Uppercase => throw _privateConstructorUsedError;
  bool get atLeast1Lowercase => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PasswordSecurityConfigCopyWith<PasswordSecurityConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PasswordSecurityConfigCopyWith<$Res> {
  factory $PasswordSecurityConfigCopyWith(PasswordSecurityConfig value,
          $Res Function(PasswordSecurityConfig) then) =
      _$PasswordSecurityConfigCopyWithImpl<$Res, PasswordSecurityConfig>;
  @useResult
  $Res call(
      {bool atLeast6Char,
      num passwordMinimalLength,
      bool atLeast1Number,
      bool atLeast1SpecialChar,
      bool atLeast1Uppercase,
      bool atLeast1Lowercase});
}

/// @nodoc
class _$PasswordSecurityConfigCopyWithImpl<$Res,
        $Val extends PasswordSecurityConfig>
    implements $PasswordSecurityConfigCopyWith<$Res> {
  _$PasswordSecurityConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? atLeast6Char = null,
    Object? passwordMinimalLength = null,
    Object? atLeast1Number = null,
    Object? atLeast1SpecialChar = null,
    Object? atLeast1Uppercase = null,
    Object? atLeast1Lowercase = null,
  }) {
    return _then(_value.copyWith(
      atLeast6Char: null == atLeast6Char
          ? _value.atLeast6Char
          : atLeast6Char // ignore: cast_nullable_to_non_nullable
              as bool,
      passwordMinimalLength: null == passwordMinimalLength
          ? _value.passwordMinimalLength
          : passwordMinimalLength // ignore: cast_nullable_to_non_nullable
              as num,
      atLeast1Number: null == atLeast1Number
          ? _value.atLeast1Number
          : atLeast1Number // ignore: cast_nullable_to_non_nullable
              as bool,
      atLeast1SpecialChar: null == atLeast1SpecialChar
          ? _value.atLeast1SpecialChar
          : atLeast1SpecialChar // ignore: cast_nullable_to_non_nullable
              as bool,
      atLeast1Uppercase: null == atLeast1Uppercase
          ? _value.atLeast1Uppercase
          : atLeast1Uppercase // ignore: cast_nullable_to_non_nullable
              as bool,
      atLeast1Lowercase: null == atLeast1Lowercase
          ? _value.atLeast1Lowercase
          : atLeast1Lowercase // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PasswordSecurityConfigImplCopyWith<$Res>
    implements $PasswordSecurityConfigCopyWith<$Res> {
  factory _$$PasswordSecurityConfigImplCopyWith(
          _$PasswordSecurityConfigImpl value,
          $Res Function(_$PasswordSecurityConfigImpl) then) =
      __$$PasswordSecurityConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool atLeast6Char,
      num passwordMinimalLength,
      bool atLeast1Number,
      bool atLeast1SpecialChar,
      bool atLeast1Uppercase,
      bool atLeast1Lowercase});
}

/// @nodoc
class __$$PasswordSecurityConfigImplCopyWithImpl<$Res>
    extends _$PasswordSecurityConfigCopyWithImpl<$Res,
        _$PasswordSecurityConfigImpl>
    implements _$$PasswordSecurityConfigImplCopyWith<$Res> {
  __$$PasswordSecurityConfigImplCopyWithImpl(
      _$PasswordSecurityConfigImpl _value,
      $Res Function(_$PasswordSecurityConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? atLeast6Char = null,
    Object? passwordMinimalLength = null,
    Object? atLeast1Number = null,
    Object? atLeast1SpecialChar = null,
    Object? atLeast1Uppercase = null,
    Object? atLeast1Lowercase = null,
  }) {
    return _then(_$PasswordSecurityConfigImpl(
      atLeast6Char: null == atLeast6Char
          ? _value.atLeast6Char
          : atLeast6Char // ignore: cast_nullable_to_non_nullable
              as bool,
      passwordMinimalLength: null == passwordMinimalLength
          ? _value.passwordMinimalLength
          : passwordMinimalLength // ignore: cast_nullable_to_non_nullable
              as num,
      atLeast1Number: null == atLeast1Number
          ? _value.atLeast1Number
          : atLeast1Number // ignore: cast_nullable_to_non_nullable
              as bool,
      atLeast1SpecialChar: null == atLeast1SpecialChar
          ? _value.atLeast1SpecialChar
          : atLeast1SpecialChar // ignore: cast_nullable_to_non_nullable
              as bool,
      atLeast1Uppercase: null == atLeast1Uppercase
          ? _value.atLeast1Uppercase
          : atLeast1Uppercase // ignore: cast_nullable_to_non_nullable
              as bool,
      atLeast1Lowercase: null == atLeast1Lowercase
          ? _value.atLeast1Lowercase
          : atLeast1Lowercase // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PasswordSecurityConfigImpl implements _PasswordSecurityConfig {
  const _$PasswordSecurityConfigImpl(
      {this.atLeast6Char = true,
      this.passwordMinimalLength = 6,
      this.atLeast1Number = true,
      this.atLeast1SpecialChar = true,
      this.atLeast1Uppercase = true,
      this.atLeast1Lowercase = true});

  factory _$PasswordSecurityConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$PasswordSecurityConfigImplFromJson(json);

  @override
  @JsonKey()
  final bool atLeast6Char;
  @override
  @JsonKey()
  final num passwordMinimalLength;
  @override
  @JsonKey()
  final bool atLeast1Number;
  @override
  @JsonKey()
  final bool atLeast1SpecialChar;
  @override
  @JsonKey()
  final bool atLeast1Uppercase;
  @override
  @JsonKey()
  final bool atLeast1Lowercase;

  @override
  String toString() {
    return 'PasswordSecurityConfig(atLeast6Char: $atLeast6Char, passwordMinimalLength: $passwordMinimalLength, atLeast1Number: $atLeast1Number, atLeast1SpecialChar: $atLeast1SpecialChar, atLeast1Uppercase: $atLeast1Uppercase, atLeast1Lowercase: $atLeast1Lowercase)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PasswordSecurityConfigImpl &&
            (identical(other.atLeast6Char, atLeast6Char) ||
                other.atLeast6Char == atLeast6Char) &&
            (identical(other.passwordMinimalLength, passwordMinimalLength) ||
                other.passwordMinimalLength == passwordMinimalLength) &&
            (identical(other.atLeast1Number, atLeast1Number) ||
                other.atLeast1Number == atLeast1Number) &&
            (identical(other.atLeast1SpecialChar, atLeast1SpecialChar) ||
                other.atLeast1SpecialChar == atLeast1SpecialChar) &&
            (identical(other.atLeast1Uppercase, atLeast1Uppercase) ||
                other.atLeast1Uppercase == atLeast1Uppercase) &&
            (identical(other.atLeast1Lowercase, atLeast1Lowercase) ||
                other.atLeast1Lowercase == atLeast1Lowercase));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      atLeast6Char,
      passwordMinimalLength,
      atLeast1Number,
      atLeast1SpecialChar,
      atLeast1Uppercase,
      atLeast1Lowercase);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PasswordSecurityConfigImplCopyWith<_$PasswordSecurityConfigImpl>
      get copyWith => __$$PasswordSecurityConfigImplCopyWithImpl<
          _$PasswordSecurityConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PasswordSecurityConfigImplToJson(
      this,
    );
  }
}

abstract class _PasswordSecurityConfig implements PasswordSecurityConfig {
  const factory _PasswordSecurityConfig(
      {final bool atLeast6Char,
      final num passwordMinimalLength,
      final bool atLeast1Number,
      final bool atLeast1SpecialChar,
      final bool atLeast1Uppercase,
      final bool atLeast1Lowercase}) = _$PasswordSecurityConfigImpl;

  factory _PasswordSecurityConfig.fromJson(Map<String, dynamic> json) =
      _$PasswordSecurityConfigImpl.fromJson;

  @override
  bool get atLeast6Char;
  @override
  num get passwordMinimalLength;
  @override
  bool get atLeast1Number;
  @override
  bool get atLeast1SpecialChar;
  @override
  bool get atLeast1Uppercase;
  @override
  bool get atLeast1Lowercase;
  @override
  @JsonKey(ignore: true)
  _$$PasswordSecurityConfigImplCopyWith<_$PasswordSecurityConfigImpl>
      get copyWith => throw _privateConstructorUsedError;
}
