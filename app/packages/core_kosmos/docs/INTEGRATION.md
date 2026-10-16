# core_kosmos - Guide d'intégration

Guide pas-à-pas pour intégrer core_kosmos dans une application Kosmos.

---

## 1. Ajouter la dépendance

```yaml
# app/pubspec.yaml
dependencies:
  core_kosmos:
    path: ../core
    # ou git:
    #   url: git@github.com:KosmosDigital06270/Package-Core.git
    #   ref: v7
```

---

## 2. Configurer AppModel

```dart
// app/lib/main.dart
import 'package:core_kosmos/core_kosmos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Application.launch(
    initModel(),
    AppRouter(...),
    initTheme: initTheme,
    onInit: () async {
      await AppMetadataController.stockMetadataForApp();
    },
  );
}

AppModel initModel() {
  return AppModel(
    appTitle: "Mon App",
    userConfig: UserConfig(...),
    dependencies: DependenciesConfig(
      packages: {
        // Utiliser TOUJOURS les constantes de clé
        EventConfiguration.key: EventConfiguration(
          enablePushNotificationConfig: true,
          onMessage: (ctx, ref, msg) { /* ... */ },
        ),
        GoogleMapConfig.key: GoogleMapConfig(
          googleMapApiKey: "YOUR_KEY",
        ),
        // Autres configs de packages...
      },
    ),
  );
}
```

---

## 3. Configurer les thèmes

```dart
// app/lib/config/theme.dart
import 'package:core_kosmos/core_kosmos.dart';

AppTheme initTheme(BuildContext context, AppModel model) {
  final appTheme = AppTheme(
    themeData: ThemeData(
      scaffoldBackgroundColor: Colors.white,
      fontFamily: "Poppins",
    ),
  );
  
  // Enregistrer les thèmes des packages
  // appTheme.addTheme("button_primary", myButtonTheme);
  // appTheme.addTheme("form_field", myFormFieldTheme);
  
  return appTheme;
}
```

---

## 4. Dark Mode (optionnel)

```dart
// Enregistrer les versions light et dark
appTheme.addTheme("button_primary", lightButtonTheme, darkTheme: darkButtonTheme);

// Dans un widget
final isDark = ref.watch(isDarkModeProvider).isDarkMode;
final theme = loadThemeData<ButtonThemeData>(
  widget.theme,
  "button_primary",
  () => kDefaultButtonTheme,
  isDark: isDark,
);
```

---

## 5. Validation

```bash
cd app
flutter pub get
dart format .
dart analyze
flutter test
```
