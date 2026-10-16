# ui_kosmos_v4 - Guide d'intégration

## 1. Ajouter la dépendance

```yaml
# app/pubspec.yaml
dependencies:
  ui_kosmos_v4:
    path: ../ui
```

## 2. Enregistrer les thèmes

```dart
// app/lib/config/theme.dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

AppTheme initTheme(BuildContext context, AppModel model) {
  final appTheme = AppTheme(...);
  
  // Boutons
  appTheme.addTheme(UiThemeKeys.buttonPrimary, KosmosButtonThemeData(
    decoration: BoxDecoration(
      color: AppColor.primaryColor,
      borderRadius: BorderRadius.circular(r(8)),
    ),
    height: formatHeight(54),
    width: double.infinity,
    buttonTextStyle: TextStyle(color: Colors.white, fontSize: sp(16)),
  ));
  
  appTheme.addTheme(UiThemeKeys.buttonSecondary, KosmosButtonThemeData(
    decoration: BoxDecoration(
      color: Colors.transparent,
      border: Border.all(color: AppColor.primaryColor),
      borderRadius: BorderRadius.circular(r(8)),
    ),
  ));
  
  // Champs
  appTheme.addTheme(UiThemeKeys.formField, FormFieldThemeData(
    fieldNameStyle: AppThemeStyle.mediumStyle(12, DefaultColor.darkBlue),
    inputDecoration: kDefaultInputDecoration.copyWith(
      fillColor: AppColor.fieldsBackground,
    ),
  ));
  
  // Settings
  appTheme.addTheme(UiThemeKeys.settingsCellule, kDefaultCellule);
  
  return appTheme;
}
```

## 3. Dark Mode (optionnel)

```dart
appTheme.addTheme(
  UiThemeKeys.buttonPrimary, 
  lightButtonTheme,
  darkTheme: darkButtonTheme,
);
```

## 4. Utilisation dans les widgets

```dart
// Les composants utilisent automatiquement leurs thèmes
Button(
  text: "Valider",
  onTap: () => submit(),
);

// Override ponctuel
Button(
  text: "Annuler",
  themeName: UiThemeKeys.buttonSecondary,
  onTap: () => cancel(),
);

// Thème inline (priorité max)
Button(
  text: "Custom",
  theme: KosmosButtonThemeData(
    decoration: BoxDecoration(color: Colors.red),
  ),
  onTap: () {},
);
```

## 5. Validation

```bash
cd app
flutter pub get
dart format .
dart analyze
flutter test
```
