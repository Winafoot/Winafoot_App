import 'package:flutter/material.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:permissionrequest/permissons_package.dart';
import 'package:skeleton/skeleton.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:wina/view/widget/app_background.dart';

/// Hauteur à réserver en bas des zones défilables pour dégager la barre de
/// navigation flottante (elle chevauche le contenu) : hauteur 62 + marge
/// basse 16 + une respiration de 10. Les écrans passent derrière la barre,
/// mais leur dernier élément peut ainsi défiler au-dessus.
const double kBottomNavClearance = 88;

/// Palette Wina — extraite du design Figma (page « Tablette »).
///
/// Application 100% tablette (1194x834). Système monochrome vert + deux
/// accents maillots (cyan/bleu) + neutres. Seule exception chromatique : un
/// rouge destructif ([destructive]) réservé à « Supprimer le joueur ».
abstract class AppColor {
  // ── Marque ──────────────────────────────────────────────────────────────
  /// Vert Wina — boutons primaires, accents, états actifs, liens.
  static const Color primaryColor = Color(0xFF518948);

  /// Vert pelouse (illustration du terrain).
  static const Color pitchGreen = Color(0xFF547824);

  // ── Accents maillots / data-viz ──────────────────────────────────────────
  /// Cyan — maillots des titulaires, surbrillances.
  static const Color jerseyStarter = Color(0xFF2AC1DD);

  /// Bleu — maillots des remplaçants.
  static const Color jerseySub = Color(0xFF4780FF);

  /// Liseré jaune du badge capitaine (« Cap. ») sur le terrain.
  static const Color captainLine = Color(0xFFDFD82D);

  // ── Maillots : swatches des couleurs d'équipe sélectionnables ────────────
  // Teintes représentatives des options de maillot (écussons, pastilles).
  // Voir [JerseyColorOption] dans models/coach_profile.dart. Les shirt-*.png y
  // sont peints (test/jersey_assets_palette_test.dart) : changer une teinte ici
  // sans recolorer son PNG (et inversement) fait tomber ce test.
  static const Color jerseyRed = Color(0xFFE2342B);
  static const Color jerseyBlue = Color(0xFF2F6FED);

  /// Même teinte que [jerseyStarter] mais rôle distinct (option choisie par le
  /// coach), volontairement gardée séparée pour pouvoir diverger.
  static const Color jerseyLightBlue = Color(0xFF2AC1DD);
  static const Color jerseyGreen = Color(0xFF3FA34D);
  static const Color jerseyLightGreen = Color(0xFF8BD04F);
  static const Color jerseyYellow = Color(0xFFF2C200);
  static const Color jerseyOrange = Color(0xFFF2872E);
  static const Color jerseyPink = Color(0xFFEE5FA0);
  static const Color jerseyGrey = Color(0xFF9AA0A6);
  static const Color jerseyBlack = Color(0xFF2B2B2B);
  static const Color jerseyWhite = Color(0xFFD7DCE0);

  // ── Texte (ink) ──────────────────────────────────────────────────────────
  /// Texte principal (quasi-noir). Sert aussi de fond à la nav basse.
  static const Color primaryLabels = Color(0xFF212121);

  /// Texte secondaire / légendes (souvent rendu à ~65% d'opacité).
  static const Color secondaryLabels = Color(0xFF6E6E6E);

  /// Texte & placeholders des champs (navy, utilisé à ~40% d'opacité).
  static const Color inkNavy = Color(0xFF02132B);

  /// Token historique nommé par hex — descriptions de liens.
  static const Color grey5A6574 = Color(0xFF5A6574);

  // ── Surfaces / fonds ─────────────────────────────────────────────────────
  /// Fond d'écran de l'app (blanc cassé légèrement verdâtre).
  static const Color background = Color(0xFFEFF4EF);

  /// Surfaces : cartes, feuilles, dialogues.
  static const Color surface = Color(0xFFFFFFFF);

  /// Lignes de l'effectif : surface blanche laissant transparaître le terrain.
  static Color rosterRowSurface = surface.withValues(alpha: 0.85);

  /// Ligne d'effectif sélectionnée : le vert de marque à 12 % composé
  /// PAR-DESSUS [rosterRowSurface], jamais À LA PLACE — sinon la ligne perd son
  /// fond et redevient illisible sur la pelouse.
  static Color rosterRowHighlight = Color.alphaBlend(
    primaryColor.withValues(alpha: .12),
    rosterRowSurface,
  );

  /// Ligne d'effectif survolée par un glisser-déposer, même règle.
  static Color rosterRowHovered = Color.alphaBlend(
    primaryColor.withValues(alpha: .10),
    rosterRowSurface,
  );

  /// Nom du joueur dans les rosters : [primaryColor] plafonne à 4,18:1 même sur
  /// du blanc pur, sous l'AA exigé pour du 15 sp. Ce vert plus sombre atteint
  /// ~5,4:1 sur [rosterRowSurface].
  static const Color rosterName = Color(0xFF3E6A37);

  /// Cellules de liste / cartes.
  static const Color cellsBackground = Color(0xFFFFFFFF);

  /// Remplissage des champs de formulaire (blanc sur fond verdâtre).
  static const Color fieldsBackground = Color(0xFFFFFFFF);

  /// Fond décoratif.
  static const Color decorationColor = Color(0xFFEFF4EF);

  /// Fond des puces d'information (poste / pied fort) — vert très pâle.
  static const Color chipBackground = Color(0xFFDCE7DB);

  /// Dégradé des pilules translucides (date, résultat de match) : vert de
  /// marque à 12 % d'opacité posé sur une carte blanche (Figma).
  static const Color chipGradientTop = Color(0x1F5B9452);
  static const Color chipGradientBottom = Color(0x1F3F7A39);

  /// Dégradé plein des boutons d'action verts (« Consulter », CTA).
  static const Color buttonGradientTop = Color(0xFF5B9452);
  static const Color buttonGradientBottom = Color(0xFF3F7A39);

  /// Barre de navigation basse (sombre).
  static const Color navBar = Color(0xFF212121);

  /// Texte / icônes clairs posés sur une surface colorée ou sombre
  /// (boutons verts, barre de navigation).
  static const Color textLight = Color(0xFFFFFFFF);

  // ── Lignes / états ───────────────────────────────────────────────────────
  /// Séparateurs, hairlines.
  static const Color divider = Color(0xFFE3E3E3);

  /// Pistes d'interrupteurs, éléments désactivés.
  static const Color disabled = Color(0xFFD9D9D9);

  /// Contour des cellules de réglages au repos (ink à 30 %, tracé 0.5 px).
  static const Color cellBorder = Color(0x4D212121);

  /// Chevrons « voir plus » des cellules de réglages.
  static const Color chevron = Color(0xFFA4AAB2);

  /// Filets de l'entête de page (navy à 20 %, tracé 0.5 px).
  static const Color headerRule = Color(0x3302132B);

  /// Rouge destructif — action « Supprimer le joueur » (texte + icône).
  static const Color destructive = Color(0xFFFC4141);

  /// Voile modal (~30% noir) derrière les dialogues.
  static const Color scrim = Color(0x4D000000);
}

abstract class AppThemeStyle {
  static const String poppinsFont = "Poppins";

  static TextStyle defaultText(
    double fontSize,
    FontWeight fontWeight,
    double? opacity,
    TextOverflow? overflow,
    Color color,
    FontStyle? fontStyle, {
    String? fontFamily,
  }) => TextStyle(
    fontSize: sp(fontSize),
    fontStyle: fontStyle,
    fontWeight: fontWeight,
    overflow: overflow,
    color: opacity != null ? color.withValues(alpha: opacity) : color,
    fontFamily: fontFamily ?? poppinsFont,
  );
  static TextStyle lightStyle(
    double fontSize,
    Color color, {
    double opacity = 1,
    TextOverflow? overflow,
    FontStyle? fontStyle,
    String? fontFamily,
  }) {
    return defaultText(
      fontSize,
      FontWeight.w300,
      opacity,
      overflow,
      color,
      fontStyle,
      fontFamily: fontFamily,
    );
  }

  static TextStyle regularStyle(
    double fontSize,
    Color color, {
    double opacity = 1,
    TextOverflow? overflow,
    FontStyle? fontStyle,
    String? fontFamily,
  }) {
    return defaultText(
      fontSize,
      FontWeight.w400,
      opacity,
      overflow,
      color,
      fontStyle,
      fontFamily: fontFamily,
    );
  }

  static TextStyle mediumStyle(
    double fontSize,
    Color color, {
    double opacity = 1,
    TextOverflow? overflow,
    FontStyle? fontStyle,
    String? fontFamily,
  }) {
    return defaultText(
      fontSize,
      FontWeight.w500,
      opacity,
      overflow,
      color,
      fontStyle,
      fontFamily: fontFamily,
    );
  }

  static TextStyle semiBStyle(
    double fontSize,
    Color color, {
    double opacity = 1,
    TextOverflow? overflow,
    FontStyle? fontStyle,
    String? fontFamily,
  }) {
    return defaultText(
      fontSize,
      FontWeight.w600,
      opacity,
      overflow,
      color,
      fontStyle,
      fontFamily: fontFamily,
    );
  }

  static TextStyle boldStyle(
    double fontSize,
    Color color, {
    double opacity = 1,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    String? fontFamily,
  }) {
    return defaultText(
      fontSize,
      FontWeight.w700,
      opacity,
      overflow,
      color,
      fontStyle,
      fontFamily: fontFamily,
    );
  }
}

/// Contour d'un champ de formulaire. Le rayon est identique pour les cinq
/// états, sinon le champ change de forme quand la validation échoue
/// (le socle Kosmos met `errorBorder` en rayon 6).
OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(r(12)),
  borderSide: BorderSide(color: color),
);

AppTheme initTheme(BuildContext context, AppModel model) {
  final appTheme = AppTheme(
    themeData: ThemeData(
      scaffoldBackgroundColor: AppColor.background,
      primaryColor: AppColor.primaryColor,
      fontFamily: AppThemeStyle.poppinsFont,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
    ),
  );

  appTheme.addTheme(
    UiThemeKeys.buttonPrimary,
    KosmosButtonThemeData(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r(999)),
        color: AppColor.primaryColor,
      ),
      height: formatHeight(54),
      width: double.infinity,
      buttonTextStyle: DefaultAppStyle.white(16),
    ),
  );
  appTheme.addTheme(
    UiThemeKeys.formField,
    FormFieldThemeData(
      fieldNameStyle: AppThemeStyle.mediumStyle(12, DefaultColor.darkBlue),
      inputDecoration: kDefaultInputDecoration.copyWith(
        fillColor: AppColor.fieldsBackground,
        // `kDefaultInputDecoration` laisse enabled / focused / disabled /
        // focusedError en `BorderSide.none` : Flutter résout ces états AVANT
        // `border` et n'y retombe jamais. Les cinq doivent donc être nommés un
        // par un, sinon la surcharge est morte et le champ n'a aucun contour.
        border: _fieldBorder(AppColor.divider),
        enabledBorder: _fieldBorder(AppColor.divider),
        focusedBorder: _fieldBorder(AppColor.primaryColor),
        disabledBorder: _fieldBorder(AppColor.divider),
        errorBorder: _fieldBorder(DefaultColor.error),
        focusedErrorBorder: _fieldBorder(DefaultColor.error),
        contentPadding: EdgeInsets.symmetric(
          horizontal: formatWidth(22),
          vertical: formatHeight(14),
        ),
      ),
    ),
  );
  appTheme.addTheme(
    SkeletonThemeKeys.authentication,
    AuthTemplateThemeData(
      subtitleStyle: AppThemeStyle.lightStyle(
        14.5,
        DefaultColor.darkBlue.withAlpha(65),
      ),
      linkDescriptionStyle: AppThemeStyle.lightStyle(14.5, AppColor.grey5A6574),
      linkStyle: AppThemeStyle.boldStyle(14.5, AppColor.primaryColor),
      // Fond terrain de la maquette. Rendu inconditionnellement par
      // `LegalInformationPage` : les 4 pages légales l'obtiennent bien.
      legalPageBackground: (BuildContext context) => const AppBackground(),
      // Dans le skeleton d'origine, `AuthParent` ne rend `backgroundPage` que
      // dans `_buildPhone` (< 800 dp), or l'app est verrouillée en paysage sur
      // un gabarit 1194x834 et passe toujours par `_buildWeb`. Le skeleton
      // intégré au dépôt rend ce fond dans `_buildWeb` aussi (modification
      // locale décrite dans packages/README.md) ; reprendre le skeleton
      // d'origine ferait disparaître le fond — `test/login_background_test.dart`
      // est là pour le détecter.
      emailLoginPageBackground:
          (BuildContext context, WidgetRef ref) => const AppBackground(),
    ),
  );

  // Sans cet enregistrement, `loadThemeData` retombe sur
  // `kDefaultPermissionTheme` : titre et lien « Passer » en marine Kosmos.
  // `backgroundColor`/`backgroundGradient` restent absents pour ne pas
  // recouvrir l'`AppBackground` posé par `backgroundChild`.
  appTheme.addTheme(
    PermissionThemeKeys.main,
    PermissionThemeData(
      titleStyle: AppThemeStyle.semiBStyle(24, AppColor.primaryLabels),
      descriptionStyle: AppThemeStyle.regularStyle(
        13,
        AppColor.secondaryLabels,
      ),
      skipButtonStyle: AppThemeStyle.mediumStyle(14, AppColor.secondaryLabels),
    ),
  );

  return appTheme;
}

// =============================================================================
// 🎨 THÈMES DISPONIBLES DANS TOUS LES PACKAGES
// =============================================================================
//
// UI PACKAGE (ui_kosmos_v4)
// -------------------------
// appTheme.addTheme(UiThemeKeys.buttonPrimary, KosmosButtonThemeData(...));
// appTheme.addTheme(UiThemeKeys.buttonSecondary, KosmosButtonThemeData(...));
// appTheme.addTheme(UiThemeKeys.buttonText, KosmosButtonThemeData(...));
// appTheme.addTheme(UiThemeKeys.buttonIcon, KosmosButtonThemeData(...));
// appTheme.addTheme(UiThemeKeys.formField, FormFieldThemeData(...));
// appTheme.addTheme(UiThemeKeys.settingsCellule, SettingsCelluleThemeData(...));
//
// SKELETON PACKAGE
// -----------------
// appTheme.addTheme(SkeletonThemeKeys.authentication, AuthTemplateThemeData(...));
// appTheme.addTheme(SkeletonThemeKeys.footer, SkeletonWebThemeData(...));
//
// SETTINGS PACKAGE (kosmos_settings)
// ----------------------------------
// appTheme.addTheme(SettingsThemeKeys.main, KosmosSettingsThemeData(...));
//
// PERMISSION PACKAGE (permissionrequest)
// --------------------------------------
// appTheme.addTheme(PermissionThemeKeys.main, PermissionThemeData(...));
//
// =============================================================================
// ⚙️ CONFIGURATIONS DISPONIBLES DANS TOUS LES PACKAGES
// =============================================================================
//
// CORE PACKAGE
// ------------
// EventConfiguration.key: initNotificationPush()
// GoogleMapConfig.key: GoogleMapConfig(googleMapApiKey: "...")
//
// SKELETON PACKAGE
// -----------------
// SkeletonAppConfig.key: initSkeletonAppConfig()
//
// SETTINGS PACKAGE (kosmos_settings)
// ----------------------------------
// KosmosSettingsConfig.key: initKosmosSettingsConfig()
//
// PERMISSION PACKAGE (permissionrequest)
// --------------------------------------
// PermissionConfig.key: initPermissionConfig()
//
// =============================================================================
