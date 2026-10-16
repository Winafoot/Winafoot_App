// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel<R> _$UserModelFromJson<R>(
    Map<String, dynamic> json, R Function(Object?) fromJsonR) {
  return _UserModel<R>.fromJson(json, fromJsonR);
}

/// @nodoc
mixin _$UserModel<R> {
  String? get id => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get credentialAppleClientID => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  bool? get isValidate => throw _privateConstructorUsedError;
  bool get autoSaveMedia => throw _privateConstructorUsedError;
  @PhoneNumberConverter()
  PhoneNumber? get phoneNumber => throw _privateConstructorUsedError;
  String? get firstname => throw _privateConstructorUsedError;
  String? get lastname => throw _privateConstructorUsedError;
  String? get pseudo => throw _privateConstructorUsedError;
  @Deprecated("Use userProfileImage to get compressed image")
  String? get profileImage => throw _privateConstructorUsedError;
  SizedImage? get userProfileImage => throw _privateConstructorUsedError;
  String? get language => throw _privateConstructorUsedError;
  GenderEnum? get gender => throw _privateConstructorUsedError;
  bool? get online => throw _privateConstructorUsedError;
  bool get socialAccount => throw _privateConstructorUsedError;
  bool? get cguAccepted => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get birthdate => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String get userType => throw _privateConstructorUsedError;

  /// Special data for application
  R? get userData => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson(Object? Function(R) toJsonR) =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserModelCopyWith<R, UserModel<R>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<R, $Res> {
  factory $UserModelCopyWith(
          UserModel<R> value, $Res Function(UserModel<R>) then) =
      _$UserModelCopyWithImpl<R, $Res, UserModel<R>>;
  @useResult
  $Res call(
      {String? id,
      String? email,
      String? credentialAppleClientID,
      String? phone,
      bool? isValidate,
      bool autoSaveMedia,
      @PhoneNumberConverter() PhoneNumber? phoneNumber,
      String? firstname,
      String? lastname,
      String? pseudo,
      @Deprecated("Use userProfileImage to get compressed image")
      String? profileImage,
      SizedImage? userProfileImage,
      String? language,
      GenderEnum? gender,
      bool? online,
      bool socialAccount,
      bool? cguAccepted,
      @TimestampConverter() DateTime? birthdate,
      @TimestampConverter() DateTime? createdAt,
      String userType,
      R? userData});

  $SizedImageCopyWith<$Res>? get userProfileImage;
}

/// @nodoc
class _$UserModelCopyWithImpl<R, $Res, $Val extends UserModel<R>>
    implements $UserModelCopyWith<R, $Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? email = freezed,
    Object? credentialAppleClientID = freezed,
    Object? phone = freezed,
    Object? isValidate = freezed,
    Object? autoSaveMedia = null,
    Object? phoneNumber = freezed,
    Object? firstname = freezed,
    Object? lastname = freezed,
    Object? pseudo = freezed,
    Object? profileImage = freezed,
    Object? userProfileImage = freezed,
    Object? language = freezed,
    Object? gender = freezed,
    Object? online = freezed,
    Object? socialAccount = null,
    Object? cguAccepted = freezed,
    Object? birthdate = freezed,
    Object? createdAt = freezed,
    Object? userType = null,
    Object? userData = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      credentialAppleClientID: freezed == credentialAppleClientID
          ? _value.credentialAppleClientID
          : credentialAppleClientID // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      isValidate: freezed == isValidate
          ? _value.isValidate
          : isValidate // ignore: cast_nullable_to_non_nullable
              as bool?,
      autoSaveMedia: null == autoSaveMedia
          ? _value.autoSaveMedia
          : autoSaveMedia // ignore: cast_nullable_to_non_nullable
              as bool,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as PhoneNumber?,
      firstname: freezed == firstname
          ? _value.firstname
          : firstname // ignore: cast_nullable_to_non_nullable
              as String?,
      lastname: freezed == lastname
          ? _value.lastname
          : lastname // ignore: cast_nullable_to_non_nullable
              as String?,
      pseudo: freezed == pseudo
          ? _value.pseudo
          : pseudo // ignore: cast_nullable_to_non_nullable
              as String?,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      userProfileImage: freezed == userProfileImage
          ? _value.userProfileImage
          : userProfileImage // ignore: cast_nullable_to_non_nullable
              as SizedImage?,
      language: freezed == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as GenderEnum?,
      online: freezed == online
          ? _value.online
          : online // ignore: cast_nullable_to_non_nullable
              as bool?,
      socialAccount: null == socialAccount
          ? _value.socialAccount
          : socialAccount // ignore: cast_nullable_to_non_nullable
              as bool,
      cguAccepted: freezed == cguAccepted
          ? _value.cguAccepted
          : cguAccepted // ignore: cast_nullable_to_non_nullable
              as bool?,
      birthdate: freezed == birthdate
          ? _value.birthdate
          : birthdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userType: null == userType
          ? _value.userType
          : userType // ignore: cast_nullable_to_non_nullable
              as String,
      userData: freezed == userData
          ? _value.userData
          : userData // ignore: cast_nullable_to_non_nullable
              as R?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SizedImageCopyWith<$Res>? get userProfileImage {
    if (_value.userProfileImage == null) {
      return null;
    }

    return $SizedImageCopyWith<$Res>(_value.userProfileImage!, (value) {
      return _then(_value.copyWith(userProfileImage: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<R, $Res>
    implements $UserModelCopyWith<R, $Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl<R> value, $Res Function(_$UserModelImpl<R>) then) =
      __$$UserModelImplCopyWithImpl<R, $Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String? email,
      String? credentialAppleClientID,
      String? phone,
      bool? isValidate,
      bool autoSaveMedia,
      @PhoneNumberConverter() PhoneNumber? phoneNumber,
      String? firstname,
      String? lastname,
      String? pseudo,
      @Deprecated("Use userProfileImage to get compressed image")
      String? profileImage,
      SizedImage? userProfileImage,
      String? language,
      GenderEnum? gender,
      bool? online,
      bool socialAccount,
      bool? cguAccepted,
      @TimestampConverter() DateTime? birthdate,
      @TimestampConverter() DateTime? createdAt,
      String userType,
      R? userData});

  @override
  $SizedImageCopyWith<$Res>? get userProfileImage;
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<R, $Res>
    extends _$UserModelCopyWithImpl<R, $Res, _$UserModelImpl<R>>
    implements _$$UserModelImplCopyWith<R, $Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl<R> _value, $Res Function(_$UserModelImpl<R>) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? email = freezed,
    Object? credentialAppleClientID = freezed,
    Object? phone = freezed,
    Object? isValidate = freezed,
    Object? autoSaveMedia = null,
    Object? phoneNumber = freezed,
    Object? firstname = freezed,
    Object? lastname = freezed,
    Object? pseudo = freezed,
    Object? profileImage = freezed,
    Object? userProfileImage = freezed,
    Object? language = freezed,
    Object? gender = freezed,
    Object? online = freezed,
    Object? socialAccount = null,
    Object? cguAccepted = freezed,
    Object? birthdate = freezed,
    Object? createdAt = freezed,
    Object? userType = null,
    Object? userData = freezed,
  }) {
    return _then(_$UserModelImpl<R>(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      credentialAppleClientID: freezed == credentialAppleClientID
          ? _value.credentialAppleClientID
          : credentialAppleClientID // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      isValidate: freezed == isValidate
          ? _value.isValidate
          : isValidate // ignore: cast_nullable_to_non_nullable
              as bool?,
      autoSaveMedia: null == autoSaveMedia
          ? _value.autoSaveMedia
          : autoSaveMedia // ignore: cast_nullable_to_non_nullable
              as bool,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as PhoneNumber?,
      firstname: freezed == firstname
          ? _value.firstname
          : firstname // ignore: cast_nullable_to_non_nullable
              as String?,
      lastname: freezed == lastname
          ? _value.lastname
          : lastname // ignore: cast_nullable_to_non_nullable
              as String?,
      pseudo: freezed == pseudo
          ? _value.pseudo
          : pseudo // ignore: cast_nullable_to_non_nullable
              as String?,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      userProfileImage: freezed == userProfileImage
          ? _value.userProfileImage
          : userProfileImage // ignore: cast_nullable_to_non_nullable
              as SizedImage?,
      language: freezed == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as GenderEnum?,
      online: freezed == online
          ? _value.online
          : online // ignore: cast_nullable_to_non_nullable
              as bool?,
      socialAccount: null == socialAccount
          ? _value.socialAccount
          : socialAccount // ignore: cast_nullable_to_non_nullable
              as bool,
      cguAccepted: freezed == cguAccepted
          ? _value.cguAccepted
          : cguAccepted // ignore: cast_nullable_to_non_nullable
              as bool?,
      birthdate: freezed == birthdate
          ? _value.birthdate
          : birthdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userType: null == userType
          ? _value.userType
          : userType // ignore: cast_nullable_to_non_nullable
              as String,
      userData: freezed == userData
          ? _value.userData
          : userData // ignore: cast_nullable_to_non_nullable
              as R?,
    ));
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$UserModelImpl<R> extends _UserModel<R> {
  const _$UserModelImpl(
      {this.id,
      this.email,
      this.credentialAppleClientID,
      this.phone,
      this.isValidate = false,
      this.autoSaveMedia = false,
      @PhoneNumberConverter() this.phoneNumber,
      this.firstname,
      this.lastname,
      this.pseudo,
      @Deprecated("Use userProfileImage to get compressed image")
      this.profileImage,
      this.userProfileImage,
      this.language,
      this.gender,
      this.online,
      this.socialAccount = false,
      this.cguAccepted,
      @TimestampConverter() this.birthdate,
      @TimestampConverter() this.createdAt,
      this.userType = "default",
      this.userData})
      : super._();

  factory _$UserModelImpl.fromJson(
          Map<String, dynamic> json, R Function(Object?) fromJsonR) =>
      _$$UserModelImplFromJson(json, fromJsonR);

  @override
  final String? id;
  @override
  final String? email;
  @override
  final String? credentialAppleClientID;
  @override
  final String? phone;
  @override
  @JsonKey()
  final bool? isValidate;
  @override
  @JsonKey()
  final bool autoSaveMedia;
  @override
  @PhoneNumberConverter()
  final PhoneNumber? phoneNumber;
  @override
  final String? firstname;
  @override
  final String? lastname;
  @override
  final String? pseudo;
  @override
  @Deprecated("Use userProfileImage to get compressed image")
  final String? profileImage;
  @override
  final SizedImage? userProfileImage;
  @override
  final String? language;
  @override
  final GenderEnum? gender;
  @override
  final bool? online;
  @override
  @JsonKey()
  final bool socialAccount;
  @override
  final bool? cguAccepted;
  @override
  @TimestampConverter()
  final DateTime? birthdate;
  @override
  @TimestampConverter()
  final DateTime? createdAt;
  @override
  @JsonKey()
  final String userType;

  /// Special data for application
  @override
  final R? userData;

  @override
  String toString() {
    return 'UserModel<$R>(id: $id, email: $email, credentialAppleClientID: $credentialAppleClientID, phone: $phone, isValidate: $isValidate, autoSaveMedia: $autoSaveMedia, phoneNumber: $phoneNumber, firstname: $firstname, lastname: $lastname, pseudo: $pseudo, profileImage: $profileImage, userProfileImage: $userProfileImage, language: $language, gender: $gender, online: $online, socialAccount: $socialAccount, cguAccepted: $cguAccepted, birthdate: $birthdate, createdAt: $createdAt, userType: $userType, userData: $userData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl<R> &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(
                    other.credentialAppleClientID, credentialAppleClientID) ||
                other.credentialAppleClientID == credentialAppleClientID) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.isValidate, isValidate) ||
                other.isValidate == isValidate) &&
            (identical(other.autoSaveMedia, autoSaveMedia) ||
                other.autoSaveMedia == autoSaveMedia) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.firstname, firstname) ||
                other.firstname == firstname) &&
            (identical(other.lastname, lastname) ||
                other.lastname == lastname) &&
            (identical(other.pseudo, pseudo) || other.pseudo == pseudo) &&
            (identical(other.profileImage, profileImage) ||
                other.profileImage == profileImage) &&
            (identical(other.userProfileImage, userProfileImage) ||
                other.userProfileImage == userProfileImage) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.online, online) || other.online == online) &&
            (identical(other.socialAccount, socialAccount) ||
                other.socialAccount == socialAccount) &&
            (identical(other.cguAccepted, cguAccepted) ||
                other.cguAccepted == cguAccepted) &&
            (identical(other.birthdate, birthdate) ||
                other.birthdate == birthdate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.userType, userType) ||
                other.userType == userType) &&
            const DeepCollectionEquality().equals(other.userData, userData));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        email,
        credentialAppleClientID,
        phone,
        isValidate,
        autoSaveMedia,
        phoneNumber,
        firstname,
        lastname,
        pseudo,
        profileImage,
        userProfileImage,
        language,
        gender,
        online,
        socialAccount,
        cguAccepted,
        birthdate,
        createdAt,
        userType,
        const DeepCollectionEquality().hash(userData)
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<R, _$UserModelImpl<R>> get copyWith =>
      __$$UserModelImplCopyWithImpl<R, _$UserModelImpl<R>>(this, _$identity);

  @override
  Map<String, dynamic> toJson(Object? Function(R) toJsonR) {
    return _$$UserModelImplToJson<R>(this, toJsonR);
  }
}

abstract class _UserModel<R> extends UserModel<R> {
  const factory _UserModel(
      {final String? id,
      final String? email,
      final String? credentialAppleClientID,
      final String? phone,
      final bool? isValidate,
      final bool autoSaveMedia,
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
      final bool socialAccount,
      final bool? cguAccepted,
      @TimestampConverter() final DateTime? birthdate,
      @TimestampConverter() final DateTime? createdAt,
      final String userType,
      final R? userData}) = _$UserModelImpl<R>;
  const _UserModel._() : super._();

  factory _UserModel.fromJson(
          Map<String, dynamic> json, R Function(Object?) fromJsonR) =
      _$UserModelImpl<R>.fromJson;

  @override
  String? get id;
  @override
  String? get email;
  @override
  String? get credentialAppleClientID;
  @override
  String? get phone;
  @override
  bool? get isValidate;
  @override
  bool get autoSaveMedia;
  @override
  @PhoneNumberConverter()
  PhoneNumber? get phoneNumber;
  @override
  String? get firstname;
  @override
  String? get lastname;
  @override
  String? get pseudo;
  @override
  @Deprecated("Use userProfileImage to get compressed image")
  String? get profileImage;
  @override
  SizedImage? get userProfileImage;
  @override
  String? get language;
  @override
  GenderEnum? get gender;
  @override
  bool? get online;
  @override
  bool get socialAccount;
  @override
  bool? get cguAccepted;
  @override
  @TimestampConverter()
  DateTime? get birthdate;
  @override
  @TimestampConverter()
  DateTime? get createdAt;
  @override
  String get userType;
  @override

  /// Special data for application
  R? get userData;
  @override
  @JsonKey(ignore: true)
  _$$UserModelImplCopyWith<R, _$UserModelImpl<R>> get copyWith =>
      throw _privateConstructorUsedError;
}

UserMetadataModel _$UserMetadataModelFromJson(Map<String, dynamic> json) {
  return _UserMetadataModel.fromJson(json);
}

/// @nodoc
mixin _$UserMetadataModel {
  /// Required for bloqued data
  List<String> get bloquedUsers => throw _privateConstructorUsedError;

  /// Required for Social App
  List<String>? get friends => throw _privateConstructorUsedError;
  List<String>? get friendsRequest => throw _privateConstructorUsedError;
  List<String>? get friendsRequestedBy => throw _privateConstructorUsedError;

  /// Required for Tchat
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get lastSeen => throw _privateConstructorUsedError;

  /// Required for Position
  @GeoPointConverters()
  GeoPoint? get lastKnownPosition => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get lastKnownPositionUpdate => throw _privateConstructorUsedError;

  /// Push Notification
  bool? get enablePushNotification => throw _privateConstructorUsedError;
  String? get fcmToken => throw _privateConstructorUsedError;
  bool get enableEmailNotification => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserMetadataModelCopyWith<UserMetadataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserMetadataModelCopyWith<$Res> {
  factory $UserMetadataModelCopyWith(
          UserMetadataModel value, $Res Function(UserMetadataModel) then) =
      _$UserMetadataModelCopyWithImpl<$Res, UserMetadataModel>;
  @useResult
  $Res call(
      {List<String> bloquedUsers,
      List<String>? friends,
      List<String>? friendsRequest,
      List<String>? friendsRequestedBy,
      @TimestampConverter() DateTime? createdAt,
      @TimestampConverter() DateTime? lastSeen,
      @GeoPointConverters() GeoPoint? lastKnownPosition,
      @TimestampConverter() DateTime? lastKnownPositionUpdate,
      bool? enablePushNotification,
      String? fcmToken,
      bool enableEmailNotification});
}

/// @nodoc
class _$UserMetadataModelCopyWithImpl<$Res, $Val extends UserMetadataModel>
    implements $UserMetadataModelCopyWith<$Res> {
  _$UserMetadataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bloquedUsers = null,
    Object? friends = freezed,
    Object? friendsRequest = freezed,
    Object? friendsRequestedBy = freezed,
    Object? createdAt = freezed,
    Object? lastSeen = freezed,
    Object? lastKnownPosition = freezed,
    Object? lastKnownPositionUpdate = freezed,
    Object? enablePushNotification = freezed,
    Object? fcmToken = freezed,
    Object? enableEmailNotification = null,
  }) {
    return _then(_value.copyWith(
      bloquedUsers: null == bloquedUsers
          ? _value.bloquedUsers
          : bloquedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      friends: freezed == friends
          ? _value.friends
          : friends // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      friendsRequest: freezed == friendsRequest
          ? _value.friendsRequest
          : friendsRequest // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      friendsRequestedBy: freezed == friendsRequestedBy
          ? _value.friendsRequestedBy
          : friendsRequestedBy // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastKnownPosition: freezed == lastKnownPosition
          ? _value.lastKnownPosition
          : lastKnownPosition // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      lastKnownPositionUpdate: freezed == lastKnownPositionUpdate
          ? _value.lastKnownPositionUpdate
          : lastKnownPositionUpdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      enablePushNotification: freezed == enablePushNotification
          ? _value.enablePushNotification
          : enablePushNotification // ignore: cast_nullable_to_non_nullable
              as bool?,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
      enableEmailNotification: null == enableEmailNotification
          ? _value.enableEmailNotification
          : enableEmailNotification // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserMetadataModelImplCopyWith<$Res>
    implements $UserMetadataModelCopyWith<$Res> {
  factory _$$UserMetadataModelImplCopyWith(_$UserMetadataModelImpl value,
          $Res Function(_$UserMetadataModelImpl) then) =
      __$$UserMetadataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String> bloquedUsers,
      List<String>? friends,
      List<String>? friendsRequest,
      List<String>? friendsRequestedBy,
      @TimestampConverter() DateTime? createdAt,
      @TimestampConverter() DateTime? lastSeen,
      @GeoPointConverters() GeoPoint? lastKnownPosition,
      @TimestampConverter() DateTime? lastKnownPositionUpdate,
      bool? enablePushNotification,
      String? fcmToken,
      bool enableEmailNotification});
}

/// @nodoc
class __$$UserMetadataModelImplCopyWithImpl<$Res>
    extends _$UserMetadataModelCopyWithImpl<$Res, _$UserMetadataModelImpl>
    implements _$$UserMetadataModelImplCopyWith<$Res> {
  __$$UserMetadataModelImplCopyWithImpl(_$UserMetadataModelImpl _value,
      $Res Function(_$UserMetadataModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bloquedUsers = null,
    Object? friends = freezed,
    Object? friendsRequest = freezed,
    Object? friendsRequestedBy = freezed,
    Object? createdAt = freezed,
    Object? lastSeen = freezed,
    Object? lastKnownPosition = freezed,
    Object? lastKnownPositionUpdate = freezed,
    Object? enablePushNotification = freezed,
    Object? fcmToken = freezed,
    Object? enableEmailNotification = null,
  }) {
    return _then(_$UserMetadataModelImpl(
      bloquedUsers: null == bloquedUsers
          ? _value._bloquedUsers
          : bloquedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      friends: freezed == friends
          ? _value._friends
          : friends // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      friendsRequest: freezed == friendsRequest
          ? _value._friendsRequest
          : friendsRequest // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      friendsRequestedBy: freezed == friendsRequestedBy
          ? _value._friendsRequestedBy
          : friendsRequestedBy // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastKnownPosition: freezed == lastKnownPosition
          ? _value.lastKnownPosition
          : lastKnownPosition // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      lastKnownPositionUpdate: freezed == lastKnownPositionUpdate
          ? _value.lastKnownPositionUpdate
          : lastKnownPositionUpdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      enablePushNotification: freezed == enablePushNotification
          ? _value.enablePushNotification
          : enablePushNotification // ignore: cast_nullable_to_non_nullable
              as bool?,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
      enableEmailNotification: null == enableEmailNotification
          ? _value.enableEmailNotification
          : enableEmailNotification // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserMetadataModelImpl implements _UserMetadataModel {
  _$UserMetadataModelImpl(
      {final List<String> bloquedUsers = const [],
      final List<String>? friends,
      final List<String>? friendsRequest,
      final List<String>? friendsRequestedBy,
      @TimestampConverter() this.createdAt,
      @TimestampConverter() this.lastSeen,
      @GeoPointConverters() this.lastKnownPosition,
      @TimestampConverter() this.lastKnownPositionUpdate,
      this.enablePushNotification,
      this.fcmToken,
      this.enableEmailNotification = false})
      : _bloquedUsers = bloquedUsers,
        _friends = friends,
        _friendsRequest = friendsRequest,
        _friendsRequestedBy = friendsRequestedBy;

  factory _$UserMetadataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserMetadataModelImplFromJson(json);

  /// Required for bloqued data
  final List<String> _bloquedUsers;

  /// Required for bloqued data
  @override
  @JsonKey()
  List<String> get bloquedUsers {
    if (_bloquedUsers is EqualUnmodifiableListView) return _bloquedUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bloquedUsers);
  }

  /// Required for Social App
  final List<String>? _friends;

  /// Required for Social App
  @override
  List<String>? get friends {
    final value = _friends;
    if (value == null) return null;
    if (_friends is EqualUnmodifiableListView) return _friends;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _friendsRequest;
  @override
  List<String>? get friendsRequest {
    final value = _friendsRequest;
    if (value == null) return null;
    if (_friendsRequest is EqualUnmodifiableListView) return _friendsRequest;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _friendsRequestedBy;
  @override
  List<String>? get friendsRequestedBy {
    final value = _friendsRequestedBy;
    if (value == null) return null;
    if (_friendsRequestedBy is EqualUnmodifiableListView)
      return _friendsRequestedBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Required for Tchat
  @override
  @TimestampConverter()
  final DateTime? createdAt;
  @override
  @TimestampConverter()
  final DateTime? lastSeen;

  /// Required for Position
  @override
  @GeoPointConverters()
  final GeoPoint? lastKnownPosition;
  @override
  @TimestampConverter()
  final DateTime? lastKnownPositionUpdate;

  /// Push Notification
  @override
  final bool? enablePushNotification;
  @override
  final String? fcmToken;
  @override
  @JsonKey()
  final bool enableEmailNotification;

  @override
  String toString() {
    return 'UserMetadataModel(bloquedUsers: $bloquedUsers, friends: $friends, friendsRequest: $friendsRequest, friendsRequestedBy: $friendsRequestedBy, createdAt: $createdAt, lastSeen: $lastSeen, lastKnownPosition: $lastKnownPosition, lastKnownPositionUpdate: $lastKnownPositionUpdate, enablePushNotification: $enablePushNotification, fcmToken: $fcmToken, enableEmailNotification: $enableEmailNotification)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserMetadataModelImpl &&
            const DeepCollectionEquality()
                .equals(other._bloquedUsers, _bloquedUsers) &&
            const DeepCollectionEquality().equals(other._friends, _friends) &&
            const DeepCollectionEquality()
                .equals(other._friendsRequest, _friendsRequest) &&
            const DeepCollectionEquality()
                .equals(other._friendsRequestedBy, _friendsRequestedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen) &&
            (identical(other.lastKnownPosition, lastKnownPosition) ||
                other.lastKnownPosition == lastKnownPosition) &&
            (identical(
                    other.lastKnownPositionUpdate, lastKnownPositionUpdate) ||
                other.lastKnownPositionUpdate == lastKnownPositionUpdate) &&
            (identical(other.enablePushNotification, enablePushNotification) ||
                other.enablePushNotification == enablePushNotification) &&
            (identical(other.fcmToken, fcmToken) ||
                other.fcmToken == fcmToken) &&
            (identical(
                    other.enableEmailNotification, enableEmailNotification) ||
                other.enableEmailNotification == enableEmailNotification));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_bloquedUsers),
      const DeepCollectionEquality().hash(_friends),
      const DeepCollectionEquality().hash(_friendsRequest),
      const DeepCollectionEquality().hash(_friendsRequestedBy),
      createdAt,
      lastSeen,
      lastKnownPosition,
      lastKnownPositionUpdate,
      enablePushNotification,
      fcmToken,
      enableEmailNotification);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserMetadataModelImplCopyWith<_$UserMetadataModelImpl> get copyWith =>
      __$$UserMetadataModelImplCopyWithImpl<_$UserMetadataModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserMetadataModelImplToJson(
      this,
    );
  }
}

abstract class _UserMetadataModel implements UserMetadataModel {
  factory _UserMetadataModel(
      {final List<String> bloquedUsers,
      final List<String>? friends,
      final List<String>? friendsRequest,
      final List<String>? friendsRequestedBy,
      @TimestampConverter() final DateTime? createdAt,
      @TimestampConverter() final DateTime? lastSeen,
      @GeoPointConverters() final GeoPoint? lastKnownPosition,
      @TimestampConverter() final DateTime? lastKnownPositionUpdate,
      final bool? enablePushNotification,
      final String? fcmToken,
      final bool enableEmailNotification}) = _$UserMetadataModelImpl;

  factory _UserMetadataModel.fromJson(Map<String, dynamic> json) =
      _$UserMetadataModelImpl.fromJson;

  @override

  /// Required for bloqued data
  List<String> get bloquedUsers;
  @override

  /// Required for Social App
  List<String>? get friends;
  @override
  List<String>? get friendsRequest;
  @override
  List<String>? get friendsRequestedBy;
  @override

  /// Required for Tchat
  @TimestampConverter()
  DateTime? get createdAt;
  @override
  @TimestampConverter()
  DateTime? get lastSeen;
  @override

  /// Required for Position
  @GeoPointConverters()
  GeoPoint? get lastKnownPosition;
  @override
  @TimestampConverter()
  DateTime? get lastKnownPositionUpdate;
  @override

  /// Push Notification
  bool? get enablePushNotification;
  @override
  String? get fcmToken;
  @override
  bool get enableEmailNotification;
  @override
  @JsonKey(ignore: true)
  _$$UserMetadataModelImplCopyWith<_$UserMetadataModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSecurityMetadataModel _$UserSecurityMetadataModelFromJson(
    Map<String, dynamic> json) {
  return _UserSecurityMetadataModel.fromJson(json);
}

/// @nodoc
mixin _$UserSecurityMetadataModel {
  String? get email => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;

  /// Security
  bool? get profilCompleted => throw _privateConstructorUsedError;
  bool? get cguAccepted => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get cguAcceptedDate => throw _privateConstructorUsedError;
  bool get enableBiometricLogin => throw _privateConstructorUsedError;
  bool get forceEnableLoginAtEachAuth => throw _privateConstructorUsedError;
  bool? get isFirstLogin => throw _privateConstructorUsedError;

  /// Security Information
  @TimestampConverter()
  DateTime? get lastPasswordUpdate => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get lastVerifEmailAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSecurityMetadataModelCopyWith<UserSecurityMetadataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSecurityMetadataModelCopyWith<$Res> {
  factory $UserSecurityMetadataModelCopyWith(UserSecurityMetadataModel value,
          $Res Function(UserSecurityMetadataModel) then) =
      _$UserSecurityMetadataModelCopyWithImpl<$Res, UserSecurityMetadataModel>;
  @useResult
  $Res call(
      {String? email,
      String? phone,
      bool? profilCompleted,
      bool? cguAccepted,
      @TimestampConverter() DateTime? cguAcceptedDate,
      bool enableBiometricLogin,
      bool forceEnableLoginAtEachAuth,
      bool? isFirstLogin,
      @TimestampConverter() DateTime? lastPasswordUpdate,
      @TimestampConverter() DateTime? lastVerifEmailAt});
}

/// @nodoc
class _$UserSecurityMetadataModelCopyWithImpl<$Res,
        $Val extends UserSecurityMetadataModel>
    implements $UserSecurityMetadataModelCopyWith<$Res> {
  _$UserSecurityMetadataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = freezed,
    Object? phone = freezed,
    Object? profilCompleted = freezed,
    Object? cguAccepted = freezed,
    Object? cguAcceptedDate = freezed,
    Object? enableBiometricLogin = null,
    Object? forceEnableLoginAtEachAuth = null,
    Object? isFirstLogin = freezed,
    Object? lastPasswordUpdate = freezed,
    Object? lastVerifEmailAt = freezed,
  }) {
    return _then(_value.copyWith(
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      profilCompleted: freezed == profilCompleted
          ? _value.profilCompleted
          : profilCompleted // ignore: cast_nullable_to_non_nullable
              as bool?,
      cguAccepted: freezed == cguAccepted
          ? _value.cguAccepted
          : cguAccepted // ignore: cast_nullable_to_non_nullable
              as bool?,
      cguAcceptedDate: freezed == cguAcceptedDate
          ? _value.cguAcceptedDate
          : cguAcceptedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      enableBiometricLogin: null == enableBiometricLogin
          ? _value.enableBiometricLogin
          : enableBiometricLogin // ignore: cast_nullable_to_non_nullable
              as bool,
      forceEnableLoginAtEachAuth: null == forceEnableLoginAtEachAuth
          ? _value.forceEnableLoginAtEachAuth
          : forceEnableLoginAtEachAuth // ignore: cast_nullable_to_non_nullable
              as bool,
      isFirstLogin: freezed == isFirstLogin
          ? _value.isFirstLogin
          : isFirstLogin // ignore: cast_nullable_to_non_nullable
              as bool?,
      lastPasswordUpdate: freezed == lastPasswordUpdate
          ? _value.lastPasswordUpdate
          : lastPasswordUpdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastVerifEmailAt: freezed == lastVerifEmailAt
          ? _value.lastVerifEmailAt
          : lastVerifEmailAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSecurityMetadataModelImplCopyWith<$Res>
    implements $UserSecurityMetadataModelCopyWith<$Res> {
  factory _$$UserSecurityMetadataModelImplCopyWith(
          _$UserSecurityMetadataModelImpl value,
          $Res Function(_$UserSecurityMetadataModelImpl) then) =
      __$$UserSecurityMetadataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? email,
      String? phone,
      bool? profilCompleted,
      bool? cguAccepted,
      @TimestampConverter() DateTime? cguAcceptedDate,
      bool enableBiometricLogin,
      bool forceEnableLoginAtEachAuth,
      bool? isFirstLogin,
      @TimestampConverter() DateTime? lastPasswordUpdate,
      @TimestampConverter() DateTime? lastVerifEmailAt});
}

/// @nodoc
class __$$UserSecurityMetadataModelImplCopyWithImpl<$Res>
    extends _$UserSecurityMetadataModelCopyWithImpl<$Res,
        _$UserSecurityMetadataModelImpl>
    implements _$$UserSecurityMetadataModelImplCopyWith<$Res> {
  __$$UserSecurityMetadataModelImplCopyWithImpl(
      _$UserSecurityMetadataModelImpl _value,
      $Res Function(_$UserSecurityMetadataModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = freezed,
    Object? phone = freezed,
    Object? profilCompleted = freezed,
    Object? cguAccepted = freezed,
    Object? cguAcceptedDate = freezed,
    Object? enableBiometricLogin = null,
    Object? forceEnableLoginAtEachAuth = null,
    Object? isFirstLogin = freezed,
    Object? lastPasswordUpdate = freezed,
    Object? lastVerifEmailAt = freezed,
  }) {
    return _then(_$UserSecurityMetadataModelImpl(
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      profilCompleted: freezed == profilCompleted
          ? _value.profilCompleted
          : profilCompleted // ignore: cast_nullable_to_non_nullable
              as bool?,
      cguAccepted: freezed == cguAccepted
          ? _value.cguAccepted
          : cguAccepted // ignore: cast_nullable_to_non_nullable
              as bool?,
      cguAcceptedDate: freezed == cguAcceptedDate
          ? _value.cguAcceptedDate
          : cguAcceptedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      enableBiometricLogin: null == enableBiometricLogin
          ? _value.enableBiometricLogin
          : enableBiometricLogin // ignore: cast_nullable_to_non_nullable
              as bool,
      forceEnableLoginAtEachAuth: null == forceEnableLoginAtEachAuth
          ? _value.forceEnableLoginAtEachAuth
          : forceEnableLoginAtEachAuth // ignore: cast_nullable_to_non_nullable
              as bool,
      isFirstLogin: freezed == isFirstLogin
          ? _value.isFirstLogin
          : isFirstLogin // ignore: cast_nullable_to_non_nullable
              as bool?,
      lastPasswordUpdate: freezed == lastPasswordUpdate
          ? _value.lastPasswordUpdate
          : lastPasswordUpdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastVerifEmailAt: freezed == lastVerifEmailAt
          ? _value.lastVerifEmailAt
          : lastVerifEmailAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSecurityMetadataModelImpl implements _UserSecurityMetadataModel {
  _$UserSecurityMetadataModelImpl(
      {this.email,
      this.phone,
      this.profilCompleted,
      this.cguAccepted,
      @TimestampConverter() this.cguAcceptedDate,
      this.enableBiometricLogin = false,
      this.forceEnableLoginAtEachAuth = false,
      this.isFirstLogin,
      @TimestampConverter() this.lastPasswordUpdate,
      @TimestampConverter() this.lastVerifEmailAt});

  factory _$UserSecurityMetadataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSecurityMetadataModelImplFromJson(json);

  @override
  final String? email;
  @override
  final String? phone;

  /// Security
  @override
  final bool? profilCompleted;
  @override
  final bool? cguAccepted;
  @override
  @TimestampConverter()
  final DateTime? cguAcceptedDate;
  @override
  @JsonKey()
  final bool enableBiometricLogin;
  @override
  @JsonKey()
  final bool forceEnableLoginAtEachAuth;
  @override
  final bool? isFirstLogin;

  /// Security Information
  @override
  @TimestampConverter()
  final DateTime? lastPasswordUpdate;
  @override
  @TimestampConverter()
  final DateTime? lastVerifEmailAt;

  @override
  String toString() {
    return 'UserSecurityMetadataModel(email: $email, phone: $phone, profilCompleted: $profilCompleted, cguAccepted: $cguAccepted, cguAcceptedDate: $cguAcceptedDate, enableBiometricLogin: $enableBiometricLogin, forceEnableLoginAtEachAuth: $forceEnableLoginAtEachAuth, isFirstLogin: $isFirstLogin, lastPasswordUpdate: $lastPasswordUpdate, lastVerifEmailAt: $lastVerifEmailAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSecurityMetadataModelImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.profilCompleted, profilCompleted) ||
                other.profilCompleted == profilCompleted) &&
            (identical(other.cguAccepted, cguAccepted) ||
                other.cguAccepted == cguAccepted) &&
            (identical(other.cguAcceptedDate, cguAcceptedDate) ||
                other.cguAcceptedDate == cguAcceptedDate) &&
            (identical(other.enableBiometricLogin, enableBiometricLogin) ||
                other.enableBiometricLogin == enableBiometricLogin) &&
            (identical(other.forceEnableLoginAtEachAuth,
                    forceEnableLoginAtEachAuth) ||
                other.forceEnableLoginAtEachAuth ==
                    forceEnableLoginAtEachAuth) &&
            (identical(other.isFirstLogin, isFirstLogin) ||
                other.isFirstLogin == isFirstLogin) &&
            (identical(other.lastPasswordUpdate, lastPasswordUpdate) ||
                other.lastPasswordUpdate == lastPasswordUpdate) &&
            (identical(other.lastVerifEmailAt, lastVerifEmailAt) ||
                other.lastVerifEmailAt == lastVerifEmailAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      email,
      phone,
      profilCompleted,
      cguAccepted,
      cguAcceptedDate,
      enableBiometricLogin,
      forceEnableLoginAtEachAuth,
      isFirstLogin,
      lastPasswordUpdate,
      lastVerifEmailAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSecurityMetadataModelImplCopyWith<_$UserSecurityMetadataModelImpl>
      get copyWith => __$$UserSecurityMetadataModelImplCopyWithImpl<
          _$UserSecurityMetadataModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSecurityMetadataModelImplToJson(
      this,
    );
  }
}

abstract class _UserSecurityMetadataModel implements UserSecurityMetadataModel {
  factory _UserSecurityMetadataModel(
          {final String? email,
          final String? phone,
          final bool? profilCompleted,
          final bool? cguAccepted,
          @TimestampConverter() final DateTime? cguAcceptedDate,
          final bool enableBiometricLogin,
          final bool forceEnableLoginAtEachAuth,
          final bool? isFirstLogin,
          @TimestampConverter() final DateTime? lastPasswordUpdate,
          @TimestampConverter() final DateTime? lastVerifEmailAt}) =
      _$UserSecurityMetadataModelImpl;

  factory _UserSecurityMetadataModel.fromJson(Map<String, dynamic> json) =
      _$UserSecurityMetadataModelImpl.fromJson;

  @override
  String? get email;
  @override
  String? get phone;
  @override

  /// Security
  bool? get profilCompleted;
  @override
  bool? get cguAccepted;
  @override
  @TimestampConverter()
  DateTime? get cguAcceptedDate;
  @override
  bool get enableBiometricLogin;
  @override
  bool get forceEnableLoginAtEachAuth;
  @override
  bool? get isFirstLogin;
  @override

  /// Security Information
  @TimestampConverter()
  DateTime? get lastPasswordUpdate;
  @override
  @TimestampConverter()
  DateTime? get lastVerifEmailAt;
  @override
  @JsonKey(ignore: true)
  _$$UserSecurityMetadataModelImplCopyWith<_$UserSecurityMetadataModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UserStripeMetadataModel _$UserStripeMetadataModelFromJson(
    Map<String, dynamic> json) {
  return _UserStripeMetadataModel.fromJson(json);
}

/// @nodoc
mixin _$UserStripeMetadataModel {
  /// Stripe
  UserStripeModel? get stripe => throw _privateConstructorUsedError;
  UserSocietyModel? get society => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserStripeMetadataModelCopyWith<UserStripeMetadataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserStripeMetadataModelCopyWith<$Res> {
  factory $UserStripeMetadataModelCopyWith(UserStripeMetadataModel value,
          $Res Function(UserStripeMetadataModel) then) =
      _$UserStripeMetadataModelCopyWithImpl<$Res, UserStripeMetadataModel>;
  @useResult
  $Res call({UserStripeModel? stripe, UserSocietyModel? society});

  $UserStripeModelCopyWith<$Res>? get stripe;
  $UserSocietyModelCopyWith<$Res>? get society;
}

/// @nodoc
class _$UserStripeMetadataModelCopyWithImpl<$Res,
        $Val extends UserStripeMetadataModel>
    implements $UserStripeMetadataModelCopyWith<$Res> {
  _$UserStripeMetadataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stripe = freezed,
    Object? society = freezed,
  }) {
    return _then(_value.copyWith(
      stripe: freezed == stripe
          ? _value.stripe
          : stripe // ignore: cast_nullable_to_non_nullable
              as UserStripeModel?,
      society: freezed == society
          ? _value.society
          : society // ignore: cast_nullable_to_non_nullable
              as UserSocietyModel?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserStripeModelCopyWith<$Res>? get stripe {
    if (_value.stripe == null) {
      return null;
    }

    return $UserStripeModelCopyWith<$Res>(_value.stripe!, (value) {
      return _then(_value.copyWith(stripe: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $UserSocietyModelCopyWith<$Res>? get society {
    if (_value.society == null) {
      return null;
    }

    return $UserSocietyModelCopyWith<$Res>(_value.society!, (value) {
      return _then(_value.copyWith(society: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserStripeMetadataModelImplCopyWith<$Res>
    implements $UserStripeMetadataModelCopyWith<$Res> {
  factory _$$UserStripeMetadataModelImplCopyWith(
          _$UserStripeMetadataModelImpl value,
          $Res Function(_$UserStripeMetadataModelImpl) then) =
      __$$UserStripeMetadataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({UserStripeModel? stripe, UserSocietyModel? society});

  @override
  $UserStripeModelCopyWith<$Res>? get stripe;
  @override
  $UserSocietyModelCopyWith<$Res>? get society;
}

/// @nodoc
class __$$UserStripeMetadataModelImplCopyWithImpl<$Res>
    extends _$UserStripeMetadataModelCopyWithImpl<$Res,
        _$UserStripeMetadataModelImpl>
    implements _$$UserStripeMetadataModelImplCopyWith<$Res> {
  __$$UserStripeMetadataModelImplCopyWithImpl(
      _$UserStripeMetadataModelImpl _value,
      $Res Function(_$UserStripeMetadataModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stripe = freezed,
    Object? society = freezed,
  }) {
    return _then(_$UserStripeMetadataModelImpl(
      stripe: freezed == stripe
          ? _value.stripe
          : stripe // ignore: cast_nullable_to_non_nullable
              as UserStripeModel?,
      society: freezed == society
          ? _value.society
          : society // ignore: cast_nullable_to_non_nullable
              as UserSocietyModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserStripeMetadataModelImpl implements _UserStripeMetadataModel {
  _$UserStripeMetadataModelImpl({this.stripe, this.society});

  factory _$UserStripeMetadataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserStripeMetadataModelImplFromJson(json);

  /// Stripe
  @override
  final UserStripeModel? stripe;
  @override
  final UserSocietyModel? society;

  @override
  String toString() {
    return 'UserStripeMetadataModel(stripe: $stripe, society: $society)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserStripeMetadataModelImpl &&
            (identical(other.stripe, stripe) || other.stripe == stripe) &&
            (identical(other.society, society) || other.society == society));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, stripe, society);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserStripeMetadataModelImplCopyWith<_$UserStripeMetadataModelImpl>
      get copyWith => __$$UserStripeMetadataModelImplCopyWithImpl<
          _$UserStripeMetadataModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserStripeMetadataModelImplToJson(
      this,
    );
  }
}

abstract class _UserStripeMetadataModel implements UserStripeMetadataModel {
  factory _UserStripeMetadataModel(
      {final UserStripeModel? stripe,
      final UserSocietyModel? society}) = _$UserStripeMetadataModelImpl;

  factory _UserStripeMetadataModel.fromJson(Map<String, dynamic> json) =
      _$UserStripeMetadataModelImpl.fromJson;

  @override

  /// Stripe
  UserStripeModel? get stripe;
  @override
  UserSocietyModel? get society;
  @override
  @JsonKey(ignore: true)
  _$$UserStripeMetadataModelImplCopyWith<_$UserStripeMetadataModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UserStripeModel _$UserStripeModelFromJson(Map<String, dynamic> json) {
  return _UserStripeModel.fromJson(json);
}

/// @nodoc
mixin _$UserStripeModel {
  String? get accountId => throw _privateConstructorUsedError;
  String? get accountStatus => throw _privateConstructorUsedError;
  String? get customerId => throw _privateConstructorUsedError;
  bool get isAccountSubmited => throw _privateConstructorUsedError;
  bool get isChargeEnabled => throw _privateConstructorUsedError;
  bool get payoutEnabled => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserStripeModelCopyWith<UserStripeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserStripeModelCopyWith<$Res> {
  factory $UserStripeModelCopyWith(
          UserStripeModel value, $Res Function(UserStripeModel) then) =
      _$UserStripeModelCopyWithImpl<$Res, UserStripeModel>;
  @useResult
  $Res call(
      {String? accountId,
      String? accountStatus,
      String? customerId,
      bool isAccountSubmited,
      bool isChargeEnabled,
      bool payoutEnabled});
}

/// @nodoc
class _$UserStripeModelCopyWithImpl<$Res, $Val extends UserStripeModel>
    implements $UserStripeModelCopyWith<$Res> {
  _$UserStripeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = freezed,
    Object? accountStatus = freezed,
    Object? customerId = freezed,
    Object? isAccountSubmited = null,
    Object? isChargeEnabled = null,
    Object? payoutEnabled = null,
  }) {
    return _then(_value.copyWith(
      accountId: freezed == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String?,
      accountStatus: freezed == accountStatus
          ? _value.accountStatus
          : accountStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      customerId: freezed == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String?,
      isAccountSubmited: null == isAccountSubmited
          ? _value.isAccountSubmited
          : isAccountSubmited // ignore: cast_nullable_to_non_nullable
              as bool,
      isChargeEnabled: null == isChargeEnabled
          ? _value.isChargeEnabled
          : isChargeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      payoutEnabled: null == payoutEnabled
          ? _value.payoutEnabled
          : payoutEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserStripeModelImplCopyWith<$Res>
    implements $UserStripeModelCopyWith<$Res> {
  factory _$$UserStripeModelImplCopyWith(_$UserStripeModelImpl value,
          $Res Function(_$UserStripeModelImpl) then) =
      __$$UserStripeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? accountId,
      String? accountStatus,
      String? customerId,
      bool isAccountSubmited,
      bool isChargeEnabled,
      bool payoutEnabled});
}

/// @nodoc
class __$$UserStripeModelImplCopyWithImpl<$Res>
    extends _$UserStripeModelCopyWithImpl<$Res, _$UserStripeModelImpl>
    implements _$$UserStripeModelImplCopyWith<$Res> {
  __$$UserStripeModelImplCopyWithImpl(
      _$UserStripeModelImpl _value, $Res Function(_$UserStripeModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = freezed,
    Object? accountStatus = freezed,
    Object? customerId = freezed,
    Object? isAccountSubmited = null,
    Object? isChargeEnabled = null,
    Object? payoutEnabled = null,
  }) {
    return _then(_$UserStripeModelImpl(
      accountId: freezed == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String?,
      accountStatus: freezed == accountStatus
          ? _value.accountStatus
          : accountStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      customerId: freezed == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String?,
      isAccountSubmited: null == isAccountSubmited
          ? _value.isAccountSubmited
          : isAccountSubmited // ignore: cast_nullable_to_non_nullable
              as bool,
      isChargeEnabled: null == isChargeEnabled
          ? _value.isChargeEnabled
          : isChargeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      payoutEnabled: null == payoutEnabled
          ? _value.payoutEnabled
          : payoutEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserStripeModelImpl implements _UserStripeModel {
  _$UserStripeModelImpl(
      {this.accountId,
      this.accountStatus,
      this.customerId,
      this.isAccountSubmited = false,
      this.isChargeEnabled = false,
      this.payoutEnabled = false});

  factory _$UserStripeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserStripeModelImplFromJson(json);

  @override
  final String? accountId;
  @override
  final String? accountStatus;
  @override
  final String? customerId;
  @override
  @JsonKey()
  final bool isAccountSubmited;
  @override
  @JsonKey()
  final bool isChargeEnabled;
  @override
  @JsonKey()
  final bool payoutEnabled;

  @override
  String toString() {
    return 'UserStripeModel(accountId: $accountId, accountStatus: $accountStatus, customerId: $customerId, isAccountSubmited: $isAccountSubmited, isChargeEnabled: $isChargeEnabled, payoutEnabled: $payoutEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserStripeModelImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.accountStatus, accountStatus) ||
                other.accountStatus == accountStatus) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.isAccountSubmited, isAccountSubmited) ||
                other.isAccountSubmited == isAccountSubmited) &&
            (identical(other.isChargeEnabled, isChargeEnabled) ||
                other.isChargeEnabled == isChargeEnabled) &&
            (identical(other.payoutEnabled, payoutEnabled) ||
                other.payoutEnabled == payoutEnabled));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, accountId, accountStatus,
      customerId, isAccountSubmited, isChargeEnabled, payoutEnabled);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserStripeModelImplCopyWith<_$UserStripeModelImpl> get copyWith =>
      __$$UserStripeModelImplCopyWithImpl<_$UserStripeModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserStripeModelImplToJson(
      this,
    );
  }
}

abstract class _UserStripeModel implements UserStripeModel {
  factory _UserStripeModel(
      {final String? accountId,
      final String? accountStatus,
      final String? customerId,
      final bool isAccountSubmited,
      final bool isChargeEnabled,
      final bool payoutEnabled}) = _$UserStripeModelImpl;

  factory _UserStripeModel.fromJson(Map<String, dynamic> json) =
      _$UserStripeModelImpl.fromJson;

  @override
  String? get accountId;
  @override
  String? get accountStatus;
  @override
  String? get customerId;
  @override
  bool get isAccountSubmited;
  @override
  bool get isChargeEnabled;
  @override
  bool get payoutEnabled;
  @override
  @JsonKey(ignore: true)
  _$$UserStripeModelImplCopyWith<_$UserStripeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSocietyModel _$UserSocietyModelFromJson(Map<String, dynamic> json) {
  return _UserSocietyModel.fromJson(json);
}

/// @nodoc
mixin _$UserSocietyModel {
  String? get siret => throw _privateConstructorUsedError;
  String? get siren => throw _privateConstructorUsedError;
  String? get tvaNumber => throw _privateConstructorUsedError;
  String? get society => throw _privateConstructorUsedError;
  String? get addressLine => throw _privateConstructorUsedError;
  String? get postalCode => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSocietyModelCopyWith<UserSocietyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSocietyModelCopyWith<$Res> {
  factory $UserSocietyModelCopyWith(
          UserSocietyModel value, $Res Function(UserSocietyModel) then) =
      _$UserSocietyModelCopyWithImpl<$Res, UserSocietyModel>;
  @useResult
  $Res call(
      {String? siret,
      String? siren,
      String? tvaNumber,
      String? society,
      String? addressLine,
      String? postalCode,
      String? country,
      String? city});
}

/// @nodoc
class _$UserSocietyModelCopyWithImpl<$Res, $Val extends UserSocietyModel>
    implements $UserSocietyModelCopyWith<$Res> {
  _$UserSocietyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? siret = freezed,
    Object? siren = freezed,
    Object? tvaNumber = freezed,
    Object? society = freezed,
    Object? addressLine = freezed,
    Object? postalCode = freezed,
    Object? country = freezed,
    Object? city = freezed,
  }) {
    return _then(_value.copyWith(
      siret: freezed == siret
          ? _value.siret
          : siret // ignore: cast_nullable_to_non_nullable
              as String?,
      siren: freezed == siren
          ? _value.siren
          : siren // ignore: cast_nullable_to_non_nullable
              as String?,
      tvaNumber: freezed == tvaNumber
          ? _value.tvaNumber
          : tvaNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      society: freezed == society
          ? _value.society
          : society // ignore: cast_nullable_to_non_nullable
              as String?,
      addressLine: freezed == addressLine
          ? _value.addressLine
          : addressLine // ignore: cast_nullable_to_non_nullable
              as String?,
      postalCode: freezed == postalCode
          ? _value.postalCode
          : postalCode // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSocietyModelImplCopyWith<$Res>
    implements $UserSocietyModelCopyWith<$Res> {
  factory _$$UserSocietyModelImplCopyWith(_$UserSocietyModelImpl value,
          $Res Function(_$UserSocietyModelImpl) then) =
      __$$UserSocietyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? siret,
      String? siren,
      String? tvaNumber,
      String? society,
      String? addressLine,
      String? postalCode,
      String? country,
      String? city});
}

/// @nodoc
class __$$UserSocietyModelImplCopyWithImpl<$Res>
    extends _$UserSocietyModelCopyWithImpl<$Res, _$UserSocietyModelImpl>
    implements _$$UserSocietyModelImplCopyWith<$Res> {
  __$$UserSocietyModelImplCopyWithImpl(_$UserSocietyModelImpl _value,
      $Res Function(_$UserSocietyModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? siret = freezed,
    Object? siren = freezed,
    Object? tvaNumber = freezed,
    Object? society = freezed,
    Object? addressLine = freezed,
    Object? postalCode = freezed,
    Object? country = freezed,
    Object? city = freezed,
  }) {
    return _then(_$UserSocietyModelImpl(
      siret: freezed == siret
          ? _value.siret
          : siret // ignore: cast_nullable_to_non_nullable
              as String?,
      siren: freezed == siren
          ? _value.siren
          : siren // ignore: cast_nullable_to_non_nullable
              as String?,
      tvaNumber: freezed == tvaNumber
          ? _value.tvaNumber
          : tvaNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      society: freezed == society
          ? _value.society
          : society // ignore: cast_nullable_to_non_nullable
              as String?,
      addressLine: freezed == addressLine
          ? _value.addressLine
          : addressLine // ignore: cast_nullable_to_non_nullable
              as String?,
      postalCode: freezed == postalCode
          ? _value.postalCode
          : postalCode // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSocietyModelImpl implements _UserSocietyModel {
  _$UserSocietyModelImpl(
      {this.siret,
      this.siren,
      this.tvaNumber,
      this.society,
      this.addressLine,
      this.postalCode,
      this.country,
      this.city});

  factory _$UserSocietyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSocietyModelImplFromJson(json);

  @override
  final String? siret;
  @override
  final String? siren;
  @override
  final String? tvaNumber;
  @override
  final String? society;
  @override
  final String? addressLine;
  @override
  final String? postalCode;
  @override
  final String? country;
  @override
  final String? city;

  @override
  String toString() {
    return 'UserSocietyModel(siret: $siret, siren: $siren, tvaNumber: $tvaNumber, society: $society, addressLine: $addressLine, postalCode: $postalCode, country: $country, city: $city)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSocietyModelImpl &&
            (identical(other.siret, siret) || other.siret == siret) &&
            (identical(other.siren, siren) || other.siren == siren) &&
            (identical(other.tvaNumber, tvaNumber) ||
                other.tvaNumber == tvaNumber) &&
            (identical(other.society, society) || other.society == society) &&
            (identical(other.addressLine, addressLine) ||
                other.addressLine == addressLine) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.city, city) || other.city == city));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, siret, siren, tvaNumber, society,
      addressLine, postalCode, country, city);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSocietyModelImplCopyWith<_$UserSocietyModelImpl> get copyWith =>
      __$$UserSocietyModelImplCopyWithImpl<_$UserSocietyModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSocietyModelImplToJson(
      this,
    );
  }
}

abstract class _UserSocietyModel implements UserSocietyModel {
  factory _UserSocietyModel(
      {final String? siret,
      final String? siren,
      final String? tvaNumber,
      final String? society,
      final String? addressLine,
      final String? postalCode,
      final String? country,
      final String? city}) = _$UserSocietyModelImpl;

  factory _UserSocietyModel.fromJson(Map<String, dynamic> json) =
      _$UserSocietyModelImpl.fromJson;

  @override
  String? get siret;
  @override
  String? get siren;
  @override
  String? get tvaNumber;
  @override
  String? get society;
  @override
  String? get addressLine;
  @override
  String? get postalCode;
  @override
  String? get country;
  @override
  String? get city;
  @override
  @JsonKey(ignore: true)
  _$$UserSocietyModelImplCopyWith<_$UserSocietyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
