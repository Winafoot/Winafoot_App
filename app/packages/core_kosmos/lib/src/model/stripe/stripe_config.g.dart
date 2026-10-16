// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stripe_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StripeConfigImpl _$$StripeConfigImplFromJson(Map json) => _$StripeConfigImpl(
      publishableKey: json['publishableKey'] as String,
      publishableProdKey: json['publishableProdKey'] as String?,
      isProdMode: json['isProdMode'] as bool? ?? false,
      merchantIdentifier: json['merchantIdentifier'] as String,
      urlScheme: json['urlScheme'] as String,
      testEmail: (json['testEmail'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      stripeCommission: json['stripeCommission'] == null
          ? null
          : StripeFeesModel.fromJson(
              Map<String, dynamic>.from(json['stripeCommission'] as Map)),
      defaultMerchantName: json['defaultMerchantName'] as String?,
      enableApplePay: json['enableApplePay'] ?? false,
      enableGooglePay: json['enableGooglePay'] ?? false,
    );

Map<String, dynamic> _$$StripeConfigImplToJson(_$StripeConfigImpl instance) =>
    <String, dynamic>{
      'publishableKey': instance.publishableKey,
      'publishableProdKey': instance.publishableProdKey,
      'isProdMode': instance.isProdMode,
      'merchantIdentifier': instance.merchantIdentifier,
      'urlScheme': instance.urlScheme,
      'testEmail': instance.testEmail,
      'stripeCommission': instance.stripeCommission?.toJson(),
      'defaultMerchantName': instance.defaultMerchantName,
      'enableApplePay': instance.enableApplePay,
      'enableGooglePay': instance.enableGooglePay,
    };
