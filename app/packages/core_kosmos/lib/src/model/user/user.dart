import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// {@category Model}
/// {@category User}
///
/// Permet de stocker les données de l'utilisateur.
///
@Freezed(genericArgumentFactories: true)
class UserModel<R> with _$UserModel<R> {
  const factory UserModel({
    final String? id,
    final String? email,
    final String? credentialAppleClientID,
    final String? phone,
    @Default(false) final bool? isValidate,
    @Default(false) final bool autoSaveMedia,
    @PhoneNumberConverter() final PhoneNumber? phoneNumber,
    final String? firstname,
    final String? lastname,
    final String? pseudo,
    @Deprecated("Use userProfileImage to get compressed image")
    final String? profileImage,
    final SizedImage? userProfileImage,
    final String? language,
    final GenderEnum? gender,
    final bool? online,
    @Default(false) bool socialAccount,
    final bool? cguAccepted,
    @TimestampConverter() final DateTime? birthdate,
    @TimestampConverter() final DateTime? createdAt,
    @Default("default") final String userType,

    /// Special data for application
    R? userData,
  }) = _UserModel;

  factory UserModel.fromJson(
          Map<String, dynamic> json, R Function(Object?) fromJsonR) =>
      _$UserModelFromJson(json, fromJsonR);

  const UserModel._();

  String get fullName => "$firstname $lastname";
}

@freezed
class UserMetadataModel with _$UserMetadataModel {
  factory UserMetadataModel({
    /// Required for bloqued data
    @Default([]) final List<String> bloquedUsers,

    /// Required for Social App
    final List<String>? friends,
    final List<String>? friendsRequest,
    final List<String>? friendsRequestedBy,

    /// Required for Tchat
    @TimestampConverter() final DateTime? createdAt,
    @TimestampConverter() final DateTime? lastSeen,

    /// Required for Position
    @GeoPointConverters() final GeoPoint? lastKnownPosition,
    @TimestampConverter() final DateTime? lastKnownPositionUpdate,

    /// Push Notification
    final bool? enablePushNotification,
    final String? fcmToken,
    @Default(false) final bool enableEmailNotification,
  }) = _UserMetadataModel;

  factory UserMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$UserMetadataModelFromJson(json);
}

@freezed
class UserSecurityMetadataModel with _$UserSecurityMetadataModel {
  factory UserSecurityMetadataModel({
    final String? email,
    final String? phone,

    /// Security
    final bool? profilCompleted,
    final bool? cguAccepted,
    @TimestampConverter() final DateTime? cguAcceptedDate,
    @Default(false) final bool enableBiometricLogin,
    @Default(false) final bool forceEnableLoginAtEachAuth,
    final bool? isFirstLogin,

    /// Security Information
    @TimestampConverter() final DateTime? lastPasswordUpdate,
    @TimestampConverter() final DateTime? lastVerifEmailAt,
  }) = _UserSecurityMetadataModel;

  factory UserSecurityMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$UserSecurityMetadataModelFromJson(json);
}

@freezed
class UserStripeMetadataModel with _$UserStripeMetadataModel {
  factory UserStripeMetadataModel({
    /// Stripe
    final UserStripeModel? stripe,
    final UserSocietyModel? society,
  }) = _UserStripeMetadataModel;

  factory UserStripeMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$UserStripeMetadataModelFromJson(json);
}

@freezed
class UserStripeModel with _$UserStripeModel {
  factory UserStripeModel({
    final String? accountId,
    final String? accountStatus,
    final String? customerId,
    @Default(false) final bool isAccountSubmited,
    @Default(false) final bool isChargeEnabled,
    @Default(false) final bool payoutEnabled,
  }) = _UserStripeModel;

  factory UserStripeModel.fromJson(Map<String, dynamic> json) =>
      _$UserStripeModelFromJson(json);
}

@freezed
class UserSocietyModel with _$UserSocietyModel {
  factory UserSocietyModel({
    final String? siret,
    final String? siren,
    final String? tvaNumber,
    final String? society,
    final String? addressLine,
    final String? postalCode,
    final String? country,
    final String? city,
  }) = _UserSocietyModel;

  factory UserSocietyModel.fromJson(Map<String, dynamic> json) =>
      _$UserSocietyModelFromJson(json);
}
