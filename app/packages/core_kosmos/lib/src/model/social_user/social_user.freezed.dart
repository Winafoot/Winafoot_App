// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SocialUser _$SocialUserFromJson(Map<String, dynamic> json) {
  return _SocialUser.fromJson(json);
}

/// @nodoc
mixin _$SocialUser {
  String get id => throw _privateConstructorUsedError;
  String get lastname => throw _privateConstructorUsedError;
  String get firstname => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get pseudo => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  @Deprecated("Use userProfileImage to get compressed image")
  String? get profileImage => throw _privateConstructorUsedError;
  SizedImage? get userProfileImage => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SocialUserCopyWith<SocialUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SocialUserCopyWith<$Res> {
  factory $SocialUserCopyWith(
          SocialUser value, $Res Function(SocialUser) then) =
      _$SocialUserCopyWithImpl<$Res, SocialUser>;
  @useResult
  $Res call(
      {String id,
      String lastname,
      String firstname,
      String? phone,
      String? pseudo,
      String email,
      double rating,
      @Deprecated("Use userProfileImage to get compressed image")
      String? profileImage,
      SizedImage? userProfileImage});

  $SizedImageCopyWith<$Res>? get userProfileImage;
}

/// @nodoc
class _$SocialUserCopyWithImpl<$Res, $Val extends SocialUser>
    implements $SocialUserCopyWith<$Res> {
  _$SocialUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lastname = null,
    Object? firstname = null,
    Object? phone = freezed,
    Object? pseudo = freezed,
    Object? email = null,
    Object? rating = null,
    Object? profileImage = freezed,
    Object? userProfileImage = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lastname: null == lastname
          ? _value.lastname
          : lastname // ignore: cast_nullable_to_non_nullable
              as String,
      firstname: null == firstname
          ? _value.firstname
          : firstname // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      pseudo: freezed == pseudo
          ? _value.pseudo
          : pseudo // ignore: cast_nullable_to_non_nullable
              as String?,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      userProfileImage: freezed == userProfileImage
          ? _value.userProfileImage
          : userProfileImage // ignore: cast_nullable_to_non_nullable
              as SizedImage?,
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
abstract class _$$SocialUserImplCopyWith<$Res>
    implements $SocialUserCopyWith<$Res> {
  factory _$$SocialUserImplCopyWith(
          _$SocialUserImpl value, $Res Function(_$SocialUserImpl) then) =
      __$$SocialUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String lastname,
      String firstname,
      String? phone,
      String? pseudo,
      String email,
      double rating,
      @Deprecated("Use userProfileImage to get compressed image")
      String? profileImage,
      SizedImage? userProfileImage});

  @override
  $SizedImageCopyWith<$Res>? get userProfileImage;
}

/// @nodoc
class __$$SocialUserImplCopyWithImpl<$Res>
    extends _$SocialUserCopyWithImpl<$Res, _$SocialUserImpl>
    implements _$$SocialUserImplCopyWith<$Res> {
  __$$SocialUserImplCopyWithImpl(
      _$SocialUserImpl _value, $Res Function(_$SocialUserImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lastname = null,
    Object? firstname = null,
    Object? phone = freezed,
    Object? pseudo = freezed,
    Object? email = null,
    Object? rating = null,
    Object? profileImage = freezed,
    Object? userProfileImage = freezed,
  }) {
    return _then(_$SocialUserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lastname: null == lastname
          ? _value.lastname
          : lastname // ignore: cast_nullable_to_non_nullable
              as String,
      firstname: null == firstname
          ? _value.firstname
          : firstname // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      pseudo: freezed == pseudo
          ? _value.pseudo
          : pseudo // ignore: cast_nullable_to_non_nullable
              as String?,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      userProfileImage: freezed == userProfileImage
          ? _value.userProfileImage
          : userProfileImage // ignore: cast_nullable_to_non_nullable
              as SizedImage?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SocialUserImpl implements _SocialUser {
  const _$SocialUserImpl(
      {required this.id,
      this.lastname = "",
      this.firstname = "",
      this.phone = "",
      this.pseudo,
      this.email = "",
      this.rating = 0,
      @Deprecated("Use userProfileImage to get compressed image")
      this.profileImage,
      this.userProfileImage});

  factory _$SocialUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$SocialUserImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String lastname;
  @override
  @JsonKey()
  final String firstname;
  @override
  @JsonKey()
  final String? phone;
  @override
  final String? pseudo;
  @override
  @JsonKey()
  final String email;
  @override
  @JsonKey()
  final double rating;
  @override
  @Deprecated("Use userProfileImage to get compressed image")
  final String? profileImage;
  @override
  final SizedImage? userProfileImage;

  @override
  String toString() {
    return 'SocialUser(id: $id, lastname: $lastname, firstname: $firstname, phone: $phone, pseudo: $pseudo, email: $email, rating: $rating, profileImage: $profileImage, userProfileImage: $userProfileImage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SocialUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lastname, lastname) ||
                other.lastname == lastname) &&
            (identical(other.firstname, firstname) ||
                other.firstname == firstname) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.pseudo, pseudo) || other.pseudo == pseudo) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.profileImage, profileImage) ||
                other.profileImage == profileImage) &&
            (identical(other.userProfileImage, userProfileImage) ||
                other.userProfileImage == userProfileImage));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, lastname, firstname, phone,
      pseudo, email, rating, profileImage, userProfileImage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SocialUserImplCopyWith<_$SocialUserImpl> get copyWith =>
      __$$SocialUserImplCopyWithImpl<_$SocialUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SocialUserImplToJson(
      this,
    );
  }
}

abstract class _SocialUser implements SocialUser {
  const factory _SocialUser(
      {required final String id,
      final String lastname,
      final String firstname,
      final String? phone,
      final String? pseudo,
      final String email,
      final double rating,
      @Deprecated("Use userProfileImage to get compressed image")
      final String? profileImage,
      final SizedImage? userProfileImage}) = _$SocialUserImpl;

  factory _SocialUser.fromJson(Map<String, dynamic> json) =
      _$SocialUserImpl.fromJson;

  @override
  String get id;
  @override
  String get lastname;
  @override
  String get firstname;
  @override
  String? get phone;
  @override
  String? get pseudo;
  @override
  String get email;
  @override
  double get rating;
  @override
  @Deprecated("Use userProfileImage to get compressed image")
  String? get profileImage;
  @override
  SizedImage? get userProfileImage;
  @override
  @JsonKey(ignore: true)
  _$$SocialUserImplCopyWith<_$SocialUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
