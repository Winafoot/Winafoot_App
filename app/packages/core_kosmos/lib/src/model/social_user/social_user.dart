import 'package:core_kosmos/core_kosmos.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_user.freezed.dart';
part 'social_user.g.dart';

/// {@category Model}
///
/// Permet de récupérer les informations social de
/// l'utilisateur.
///
/// - [id] : L'identifiant de l'utilisateur.
/// - [lastname] : Le nom de l'utilisateur.
/// - [firstname] : Le prénom de l'utilisateur.
/// - [phone] : Le numéro de téléphone de l'utilisateur.
/// - [email] : L'email de l'utilisateur.
/// - [profileImage] : L'url de la photo de l'utilisateur.
///
@freezed
class SocialUser with _$SocialUser {
  const factory SocialUser({
    required String id,
    @Default("") String lastname,
    @Default("") String firstname,
    @Default("") final String? phone,
    final String? pseudo,
    @Default("") String email,
    @Default(0) double rating,
    @Deprecated("Use userProfileImage to get compressed image")
    String? profileImage,
    SizedImage? userProfileImage,
  }) = _SocialUser;

  factory SocialUser.fromJson(Map<String, dynamic> json) =>
      _$SocialUserFromJson(json);
}
