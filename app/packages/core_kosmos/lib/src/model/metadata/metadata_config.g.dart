// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppMetadataConfigImpl _$$AppMetadataConfigImplFromJson(Map json) =>
    _$AppMetadataConfigImpl(
      appHash: json['appHash'] as String?,
      shareMessage: json['shareMessage'] as String?,
      cgvu: json['cgvu'] as String?,
      confidentialityPolicy: json['confidentialityPolicy'] as String?,
      legalNotice: json['legalNotice'] as String?,
      about: json['about'] as String?,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      twitterUrl: json['twitterUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      snapchatUrl: json['snapchatUrl'] as String?,
      tiktokUrl: json['tiktokUrl'] as String?,
      activateInAppPurchase: json['activateInAppPurchase'] as bool? ?? true,
      passwordSecurityConfig: json['passwordSecurityConfig'] == null
          ? const PasswordSecurityConfig()
          : PasswordSecurityConfig.fromJson(
              Map<String, dynamic>.from(json['passwordSecurityConfig'] as Map)),
      stripeConfig: json['stripeConfig'] == null
          ? null
          : StripeConfig.fromJson(
              Map<String, dynamic>.from(json['stripeConfig'] as Map)),
    );

Map<String, dynamic> _$$AppMetadataConfigImplToJson(
        _$AppMetadataConfigImpl instance) =>
    <String, dynamic>{
      'appHash': instance.appHash,
      'shareMessage': instance.shareMessage,
      'cgvu': instance.cgvu,
      'confidentialityPolicy': instance.confidentialityPolicy,
      'legalNotice': instance.legalNotice,
      'about': instance.about,
      'contactEmail': instance.contactEmail,
      'contactPhone': instance.contactPhone,
      'facebookUrl': instance.facebookUrl,
      'instagramUrl': instance.instagramUrl,
      'twitterUrl': instance.twitterUrl,
      'youtubeUrl': instance.youtubeUrl,
      'linkedinUrl': instance.linkedinUrl,
      'snapchatUrl': instance.snapchatUrl,
      'tiktokUrl': instance.tiktokUrl,
      'activateInAppPurchase': instance.activateInAppPurchase,
      'passwordSecurityConfig': instance.passwordSecurityConfig.toJson(),
      'stripeConfig': instance.stripeConfig?.toJson(),
    };

_$PasswordSecurityConfigImpl _$$PasswordSecurityConfigImplFromJson(Map json) =>
    _$PasswordSecurityConfigImpl(
      atLeast6Char: json['atLeast6Char'] as bool? ?? true,
      passwordMinimalLength: json['passwordMinimalLength'] as num? ?? 6,
      atLeast1Number: json['atLeast1Number'] as bool? ?? true,
      atLeast1SpecialChar: json['atLeast1SpecialChar'] as bool? ?? true,
      atLeast1Uppercase: json['atLeast1Uppercase'] as bool? ?? true,
      atLeast1Lowercase: json['atLeast1Lowercase'] as bool? ?? true,
    );

Map<String, dynamic> _$$PasswordSecurityConfigImplToJson(
        _$PasswordSecurityConfigImpl instance) =>
    <String, dynamic>{
      'atLeast6Char': instance.atLeast6Char,
      'passwordMinimalLength': instance.passwordMinimalLength,
      'atLeast1Number': instance.atLeast1Number,
      'atLeast1SpecialChar': instance.atLeast1SpecialChar,
      'atLeast1Uppercase': instance.atLeast1Uppercase,
      'atLeast1Lowercase': instance.atLeast1Lowercase,
    };
