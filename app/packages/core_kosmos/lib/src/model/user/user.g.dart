// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl<R> _$$UserModelImplFromJson<R>(
  Map json,
  R Function(Object? json) fromJsonR,
) =>
    _$UserModelImpl<R>(
      id: json['id'] as String?,
      email: json['email'] as String?,
      credentialAppleClientID: json['credentialAppleClientID'] as String?,
      phone: json['phone'] as String?,
      isValidate: json['isValidate'] as bool? ?? false,
      autoSaveMedia: json['autoSaveMedia'] as bool? ?? false,
      phoneNumber: const PhoneNumberConverter()
          .fromJson(json['phoneNumber'] as Map<String, dynamic>?),
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      pseudo: json['pseudo'] as String?,
      profileImage: json['profileImage'] as String?,
      userProfileImage: json['userProfileImage'] == null
          ? null
          : SizedImage.fromJson(
              Map<String, dynamic>.from(json['userProfileImage'] as Map)),
      language: json['language'] as String?,
      gender: $enumDecodeNullable(_$GenderEnumEnumMap, json['gender']),
      online: json['online'] as bool?,
      socialAccount: json['socialAccount'] as bool? ?? false,
      cguAccepted: json['cguAccepted'] as bool?,
      birthdate: const TimestampConverter().fromJson(json['birthdate']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      userType: json['userType'] as String? ?? "default",
      userData: _$nullableGenericFromJson(json['userData'], fromJsonR),
    );

Map<String, dynamic> _$$UserModelImplToJson<R>(
  _$UserModelImpl<R> instance,
  Object? Function(R value) toJsonR,
) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'credentialAppleClientID': instance.credentialAppleClientID,
      'phone': instance.phone,
      'isValidate': instance.isValidate,
      'autoSaveMedia': instance.autoSaveMedia,
      'phoneNumber': const PhoneNumberConverter().toJson(instance.phoneNumber),
      'firstname': instance.firstname,
      'lastname': instance.lastname,
      'pseudo': instance.pseudo,
      'profileImage': instance.profileImage,
      'userProfileImage': instance.userProfileImage?.toJson(),
      'language': instance.language,
      'gender': _$GenderEnumEnumMap[instance.gender],
      'online': instance.online,
      'socialAccount': instance.socialAccount,
      'cguAccepted': instance.cguAccepted,
      'birthdate': const TimestampConverter().toJson(instance.birthdate),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'userType': instance.userType,
      'userData': _$nullableGenericToJson(instance.userData, toJsonR),
    };

const _$GenderEnumEnumMap = {
  GenderEnum.men: 'men',
  GenderEnum.women: 'women',
  GenderEnum.other: 'other',
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);

_$UserMetadataModelImpl _$$UserMetadataModelImplFromJson(Map json) =>
    _$UserMetadataModelImpl(
      bloquedUsers: (json['bloquedUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      friends:
          (json['friends'] as List<dynamic>?)?.map((e) => e as String).toList(),
      friendsRequest: (json['friendsRequest'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      friendsRequestedBy: (json['friendsRequestedBy'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      lastSeen: const TimestampConverter().fromJson(json['lastSeen']),
      lastKnownPosition: const GeoPointConverters()
          .fromJson(json['lastKnownPosition'] as GeoPoint?),
      lastKnownPositionUpdate:
          const TimestampConverter().fromJson(json['lastKnownPositionUpdate']),
      enablePushNotification: json['enablePushNotification'] as bool?,
      fcmToken: json['fcmToken'] as String?,
      enableEmailNotification:
          json['enableEmailNotification'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserMetadataModelImplToJson(
        _$UserMetadataModelImpl instance) =>
    <String, dynamic>{
      'bloquedUsers': instance.bloquedUsers,
      'friends': instance.friends,
      'friendsRequest': instance.friendsRequest,
      'friendsRequestedBy': instance.friendsRequestedBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'lastSeen': const TimestampConverter().toJson(instance.lastSeen),
      'lastKnownPosition':
          const GeoPointConverters().toJson(instance.lastKnownPosition),
      'lastKnownPositionUpdate':
          const TimestampConverter().toJson(instance.lastKnownPositionUpdate),
      'enablePushNotification': instance.enablePushNotification,
      'fcmToken': instance.fcmToken,
      'enableEmailNotification': instance.enableEmailNotification,
    };

_$UserSecurityMetadataModelImpl _$$UserSecurityMetadataModelImplFromJson(
        Map json) =>
    _$UserSecurityMetadataModelImpl(
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profilCompleted: json['profilCompleted'] as bool?,
      cguAccepted: json['cguAccepted'] as bool?,
      cguAcceptedDate:
          const TimestampConverter().fromJson(json['cguAcceptedDate']),
      enableBiometricLogin: json['enableBiometricLogin'] as bool? ?? false,
      forceEnableLoginAtEachAuth:
          json['forceEnableLoginAtEachAuth'] as bool? ?? false,
      isFirstLogin: json['isFirstLogin'] as bool?,
      lastPasswordUpdate:
          const TimestampConverter().fromJson(json['lastPasswordUpdate']),
      lastVerifEmailAt:
          const TimestampConverter().fromJson(json['lastVerifEmailAt']),
    );

Map<String, dynamic> _$$UserSecurityMetadataModelImplToJson(
        _$UserSecurityMetadataModelImpl instance) =>
    <String, dynamic>{
      'email': instance.email,
      'phone': instance.phone,
      'profilCompleted': instance.profilCompleted,
      'cguAccepted': instance.cguAccepted,
      'cguAcceptedDate':
          const TimestampConverter().toJson(instance.cguAcceptedDate),
      'enableBiometricLogin': instance.enableBiometricLogin,
      'forceEnableLoginAtEachAuth': instance.forceEnableLoginAtEachAuth,
      'isFirstLogin': instance.isFirstLogin,
      'lastPasswordUpdate':
          const TimestampConverter().toJson(instance.lastPasswordUpdate),
      'lastVerifEmailAt':
          const TimestampConverter().toJson(instance.lastVerifEmailAt),
    };

_$UserStripeMetadataModelImpl _$$UserStripeMetadataModelImplFromJson(
        Map json) =>
    _$UserStripeMetadataModelImpl(
      stripe: json['stripe'] == null
          ? null
          : UserStripeModel.fromJson(
              Map<String, dynamic>.from(json['stripe'] as Map)),
      society: json['society'] == null
          ? null
          : UserSocietyModel.fromJson(
              Map<String, dynamic>.from(json['society'] as Map)),
    );

Map<String, dynamic> _$$UserStripeMetadataModelImplToJson(
        _$UserStripeMetadataModelImpl instance) =>
    <String, dynamic>{
      'stripe': instance.stripe?.toJson(),
      'society': instance.society?.toJson(),
    };

_$UserStripeModelImpl _$$UserStripeModelImplFromJson(Map json) =>
    _$UserStripeModelImpl(
      accountId: json['accountId'] as String?,
      accountStatus: json['accountStatus'] as String?,
      customerId: json['customerId'] as String?,
      isAccountSubmited: json['isAccountSubmited'] as bool? ?? false,
      isChargeEnabled: json['isChargeEnabled'] as bool? ?? false,
      payoutEnabled: json['payoutEnabled'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserStripeModelImplToJson(
        _$UserStripeModelImpl instance) =>
    <String, dynamic>{
      'accountId': instance.accountId,
      'accountStatus': instance.accountStatus,
      'customerId': instance.customerId,
      'isAccountSubmited': instance.isAccountSubmited,
      'isChargeEnabled': instance.isChargeEnabled,
      'payoutEnabled': instance.payoutEnabled,
    };

_$UserSocietyModelImpl _$$UserSocietyModelImplFromJson(Map json) =>
    _$UserSocietyModelImpl(
      siret: json['siret'] as String?,
      siren: json['siren'] as String?,
      tvaNumber: json['tvaNumber'] as String?,
      society: json['society'] as String?,
      addressLine: json['addressLine'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
    );

Map<String, dynamic> _$$UserSocietyModelImplToJson(
        _$UserSocietyModelImpl instance) =>
    <String, dynamic>{
      'siret': instance.siret,
      'siren': instance.siren,
      'tvaNumber': instance.tvaNumber,
      'society': instance.society,
      'addressLine': instance.addressLine,
      'postalCode': instance.postalCode,
      'country': instance.country,
      'city': instance.city,
    };
