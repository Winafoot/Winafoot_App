# ui_kosmos_v4 - Clés Config & Theme

Package: **ui_kosmos_v4** (v2.0.0-pre)

---

## Config Keys

Ce package ne définit pas de configs. Il fournit uniquement des composants UI avec thèmes.

---

## Theme Keys

| Clé | Type | Composant | Fichier |
|-----|------|-----------|---------|
| `UiThemeKeys.buttonPrimary` | `KosmosButtonThemeData` | `Button(buttonType: ButtonType.primary)` | `lib/button/theme/button_theme.dart` |
| `UiThemeKeys.buttonSecondary` | `KosmosButtonThemeData` | `Button(buttonType: ButtonType.secondary)` | `lib/button/theme/button_theme.dart` |
| `UiThemeKeys.buttonText` | `KosmosButtonThemeData` | `Button(buttonType: ButtonType.text)` | `lib/button/theme/button_theme.dart` |
| `UiThemeKeys.buttonIcon` | `KosmosButtonThemeData` | `Button(buttonType: ButtonType.icon)` | `lib/button/theme/button_theme.dart` |
| `UiThemeKeys.formField` | `FormFieldThemeData` | `ClassicField`, `PhoneNumberField`, etc. | `lib/field/theme/form_field_theme.dart` |
| `UiThemeKeys.settingsCellule` | `SettingsCelluleThemeData` | `SettingsCellule` | `lib/settings/theme/cellule_theme.dart` |

### Valeurs canoniques

```dart
class UiThemeKeys {
  static const buttonPrimary = "button_primary";
  static const buttonSecondary = "button_secondary";
  static const buttonText = "button_text";
  static const buttonIcon = "button_icon";
  static const formField = "form_field";
  static const settingsCellule = "settings_cellule";
}
```

---

## Integration in App

### Enregistrer les thèmes

```dart
// app/lib/config/theme.dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

AppTheme initTheme(BuildContext context, AppModel model) {
  final appTheme = AppTheme(...);
  
  // Boutons
  appTheme.addTheme(UiThemeKeys.buttonPrimary, KosmosButtonThemeData(
    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
    buttonTextStyle: TextStyle(color: Colors.white),
  ));
  
  appTheme.addTheme(UiThemeKeys.buttonSecondary, KosmosButtonThemeData(
    decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
  ));
  
  // Champs de formulaire
  appTheme.addTheme(UiThemeKeys.formField, FormFieldThemeData(
    fieldNameStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    inputDecoration: kDefaultInputDecoration.copyWith(fillColor: Colors.grey[100]),
  ));
  
  // Cellules settings
  appTheme.addTheme(UiThemeKeys.settingsCellule, SettingsCelluleThemeData(
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
  ));
  
  return appTheme;
}
```

---

## Examples

### Utiliser un bouton avec thème

```dart
// Utilise automatiquement le thème "button_primary"
Button(
  text: "Valider",
  onTap: () => print("tap"),
);

// Thème personnalisé
Button(
  text: "Annuler",
  themeName: UiThemeKeys.buttonSecondary,
  onTap: () => Navigator.pop(context),
);
```

### Wrapper loadTheme (recommandé)

```dart
KosmosButtonThemeData loadButtonTheme({
  KosmosButtonThemeData? theme,
  String? themeName,
  required bool isDark,
}) {
  return loadThemeData<KosmosButtonThemeData>(
    theme,
    themeName ?? UiThemeKeys.buttonPrimary,
    () => kDefaultButtonThemeData,
    isDark: isDark,
  );
}
```
