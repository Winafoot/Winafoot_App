import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:skeleton/skeleton.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

part 'auth_theme.freezed.dart';

@freezed
class AuthTemplateThemeData with _$AuthTemplateThemeData {
  const factory AuthTemplateThemeData({
    final TextStyle? titleStyle,
    final TextStyle? popupTitleStyle,
    final TextStyle? subtitleStyle,
    final TextStyle? focusableStyle,
    final TextStyle? htmlTextStyle,
    final Color? dividerColor,
    final EdgeInsetsGeometry? formPadding,
    final EdgeInsetsGeometry? titlePadding,
    final ShapeBorder? modalBottomSheetShapeBorder,
    final Color? popupBackgroundColor,
    final double? titleAndFormSpacing,

    /// Alignement du sous-titre/compteur (pages code SMS), `null` = centré.
    final AlignmentGeometry? subtitleAlignment,

    /// Espacement titre → sous-titre/compteur (pages code SMS),
    /// `null` = formatHeight(15).
    final double? titleAndSubtitleSpacing,

    /// Espacement sous-titre/compteur → champ code (pages code SMS),
    /// `null` = formatHeight(60).
    final double? subtitleAndFormSpacing,
    final Size? logoSize,
    final TextStyle? linkStyle,
    final TextStyle? linkDescriptionStyle,
    final TextStyle? appBarPreActionWidgetTitleStyle,
    final TextStyle? appBarActionWidgetTitleStyle,
    final String? pinCodeFieldThemeName,
    final PinTheme? pinTheme,
    final Widget Function(BuildContext, WidgetRef)? emailLoginPageBackground,
    final Widget Function(BuildContext, WidgetRef)? phoneLoginPageBackground,
    final Widget Function(BuildContext, WidgetRef)? setPhonePageBackground,
    final Widget Function(BuildContext, WidgetRef)?
        pinLoginVerficationLoginPageBackground,
    final Widget Function(BuildContext, WidgetRef)?
        pinSignupVerficationLoginPageBackground,
    final Widget Function(BuildContext, WidgetRef)? signupPageBckground,
    final Widget Function(BuildContext)? legalPageBackground,
    // Web only
    final BoxConstraints? webformConstraints,
    final BoxDecoration? webBoxDecoration,
    final EdgeInsetsGeometry? webBoxPadding,

    // Auth Tiers : Apple and Google
    final EdgeInsetsGeometry? authTiersPadding,
    final double? authTiersHeight,
    @Default(false) final bool authTiersExtended,
    final double? authTiersRadius,
  }) = _AuthTemplateThemeData;
}
