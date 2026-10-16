# Kosmos Core Package

Package central contenant les utilitaires, modèles et configurations de base pour l'écosystème Kosmos Digital.

---

## 📋 Description

Ce package est le **cœur de l'écosystème Kosmos**. Il fournit :
- `AppModel` - Modèle principal de l'application
- `Application.launch()` - Point d'entrée pour lancer l'app
- `PackageConfig` - Classe de base pour les configurations de packages
- `loadThemeData()` - Utilitaire pour charger les thèmes
- Providers Riverpod (`userProvider`, `isDarkModeProvider`)
- Utilitaires (formatage, validation, Firebase, etc.)

---

## ⚙️ Configuration

### Clé de configuration principale

| Clé | Type | Description |
| --- | --- | --- |
| `"kosmos_event_config"` | `EventConfiguration` | Configuration des notifications push |

### Structure de l'AppModel

```dart
AppModel(
  appTitle: "Mon Application",
  userConfig: UserConfig<MyUserModel>(
    userModel: MyUserModel.fromJson,
    metadataModel: MyMetadataModel.fromJson,
  ),
  localization: LocalizationConfig(
    supportedLocales: [Locale("fr", "FR"), Locale("en", "US")],
    defaultLocale: Locale("fr", "FR"),
  ),
  responsive: ResponsiveConfig(
    size: Size(375, 812), // Taille de design
  ),
  dependencies: DependenciesConfig(
    packages: {
      // Toutes les configs de packages ici
      "kosmos_event_config": EventConfiguration(...),
      "skeleton_app_config": SkeletonAppConfig(...),
      // etc.
    },
  ),
);
```

### EventConfiguration (Push Notifications)

```dart
EventConfiguration(
  enablePushNotificationConfig: true,
  soundIos: "notification.caf",
  soundAndroid: "notification",
  onMessage: (ctx, ref, message) {
    // Notification reçue en foreground
  },
  onMessageBackground: (ctx, ref, message) {
    // Notification cliquée depuis background
  },
  onSelectNotification: (ctx, ref, response) {
    // Notification locale cliquée
  },
)
```

---

## 🎨 Système de Thèmes

### Principe de fonctionnement

Le système de thème utilise `GetIt` pour stocker une instance `AppTheme` globale :

```dart
// Initialisation (dans theme.dart de l'app)
final appTheme = AppTheme();
GetIt.instance.registerSingleton<AppTheme>(appTheme);

// Ajout d'un thème
appTheme.addTheme("button_primary", KosmosButtonThemeData(...));
appTheme.addTheme("form_field", FormFieldThemeData(...));
```

### Récupération d'un thème dans un widget

```dart
final themeData = loadThemeData<KosmosButtonThemeData>(
  widget.theme,           // Thème passé en paramètre (prioritaire)
  "button_primary",       // Clé du thème par défaut
  () => kDefaultButtonThemeData,  // Fallback si non trouvé
  isDark: ref.watch(isDarkModeProvider).isDarkMode,
);
```

### Thèmes avec Dark Mode

```dart
// Ajouter un thème avec version dark
appTheme.addTheme("button_primary", lightThemeData);
appTheme.addThemeDark("button_primary", darkThemeData);
```

---

## 📖 Utilitaires principaux

### Application.launch()

```dart
void main() async {
  await Application.launch(
    model: appModel,
    router: AppRouter(),
    onInit: () async {
      await AppMetadataController.stockMetadataForApp();
    },
    theme: initTheme,
  );
}
```

### getAppModel()

```dart
// Récupérer l'AppModel depuis n'importe où
final appModel = getAppModel();
final config = appModel.getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");
```

### Providers Riverpod

```dart
// Provider utilisateur
final user = ref.watch(userProvider).user;
final metadata = ref.watch(userProvider).metadata;

// Provider dark mode
final isDark = ref.watch(isDarkModeProvider).isDarkMode;
```

### Formatage responsive

```dart
formatWidth(100)   // Largeur responsive
formatHeight(50)   // Hauteur responsive
r(10)              // Radius responsive
sp(16)             // Font size responsive
sh(20)             // SizedBox height
sw(15)             // SizedBox width
pw(27.5)           // Padding horizontal
ph(15)             // Padding vertical
pwh(27.5, 15)      // Padding horizontal + vertical
```

---

## 🏗️ Architecture des Packages

### Classe PackageConfig

Tous les packages doivent étendre `PackageConfig` :

```dart
class MyPackageConfig extends PackageConfig {
  final String myOption;
  
  const MyPackageConfig({
    this.myOption = "default",
  }) : super("my-package-key"); // Clé unique
}
```

### Récupération dans un package

```dart
// Pattern recommandé : créer une fonction utilitaire
MyPackageConfig getMyPackageConfig() =>
    (getAppModel().dependencies.packages["my-package-key"]
        as MyPackageConfig?) ?? MyPackageConfig();
```

---

## 📊 Tableau récapitulatif des clés

| Package | Clé de config | Clé(s) de thème |
| --- | --- | --- |
| core | `"kosmos_event_config"` | - |
| skeleton | `"skeleton_app_config"` | `"authentication_theme"`, `"skeleton_footer"` |
| settings | `"kosmos-settings"` | `"kosmos-settings"`, `"settings_cellule"` |
| permission | `"permission-kosmos"` | `"permission"` |
| tchat | `"tchat_frontend"`, `"tchat_backend"` | `"tchat_theme"` |
| commentary | `"kosmos-commentary"` | `"kosmos-commentary"` |
| blocked | `"blocked_users"` | (utilise settings) |
| payment | `"kosmos-payment"` | `"payment-theme"` |
| signalement | - | `"signal_theme"` |

---

## 🔗 Dépendances

```yaml
dependencies:
  core_kosmos:
    git:
      url: git@github.com:KosmosDigital06270/Package-Core.git
      ref: v7
```
