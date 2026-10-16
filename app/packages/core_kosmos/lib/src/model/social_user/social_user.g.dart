// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SocialUserImpl _$$SocialUserImplFromJson(Map json) => _$SocialUserImpl(
      id: json['id'] as String,
      lastname: json['lastname'] as String? ?? "",
      firstname: json['firstname'] as String? ?? "",
      phone: json['phone'] as String? ?? "",
      pseudo: json['pseudo'] as String?,
      email: json['email'] as String? ?? "",
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      profileImage: json['profileImage'] as String?,
      userProfileImage: json['userProfileImage'] == null
          ? null
          : SizedImage.fromJson(
              Map<String, dynamic>.from(json['userProfileImage'] as Map)),
    );

Map<String, dynamic> _$$SocialUserImplToJson(_$SocialUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lastname': instance.lastname,
      'firstname': instance.firstname,
      'phone': instance.phone,
      'pseudo': instance.pseudo,
      'email': instance.email,
      'rating': instance.rating,
      'profileImage': instance.profileImage,
      'userProfileImage': instance.userProfileImage?.toJson(),
    };
