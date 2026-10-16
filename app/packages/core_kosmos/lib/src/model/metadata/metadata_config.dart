import 'package:core_kosmos/core_kosmos.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'metadata_config.freezed.dart';
part 'metadata_config.g.dart';

/// {@category Model}
///
/// Configuration secondaire de l'application.
/// Permet de configurer les liens / contenu / sécurité de l'application.
/// Cette classe est surtout utiliser pour récupérer les configurations depuis Firebase.
///
@freezed
class AppMetadataConfig with _$AppMetadataConfig {
  const factory AppMetadataConfig({
    /// Security
    final String? appHash,

    /// Share
    final String? shareMessage,

    /// Legal documents
    final String? cgvu,
    final String? confidentialityPolicy,
    final String? legalNotice,
    final String? about,

    /// Contact
    final String? contactEmail,
    final String? contactPhone,

    /// Social Network
    final String? facebookUrl,
    final String? instagramUrl,
    final String? twitterUrl,
    final String? youtubeUrl,
    final String? linkedinUrl,
    final String? snapchatUrl,
    final String? tiktokUrl,
    @Default(true) final bool activateInAppPurchase,

    /// Security Strenght
    @Default(PasswordSecurityConfig())
    final PasswordSecurityConfig passwordSecurityConfig,
    final StripeConfig? stripeConfig,
  }) = _AppMetadataConfig;

  factory AppMetadataConfig.fromJson(Map<String, dynamic> json) =>
      _$AppMetadataConfigFromJson(json);
}

@freezed
class PasswordSecurityConfig with _$PasswordSecurityConfig {
  const factory PasswordSecurityConfig({
    @Default(true) final bool atLeast6Char,
    @Default(6) final num passwordMinimalLength,
    @Default(true) final bool atLeast1Number,
    @Default(true) final bool atLeast1SpecialChar,
    @Default(true) final bool atLeast1Uppercase,
    @Default(true) final bool atLeast1Lowercase,
  }) = _PasswordSecurityConfig;

  factory PasswordSecurityConfig.fromJson(Map<String, dynamic> json) =>
      _$PasswordSecurityConfigFromJson(json);
}
