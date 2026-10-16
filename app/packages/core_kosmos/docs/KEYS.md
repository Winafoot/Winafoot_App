# core_kosmos - Clés Config & Theme

Package: **core_kosmos** (v2.0.1-pre)

---

## Config Keys

| Clé | Type | Description | Fichier |
|-----|------|-------------|---------|
| `EventConfiguration.key` | `EventConfiguration` | Configuration des notifications push et événements | `lib/src/config/event_config.dart` |
| `GoogleMapConfig.key` | `GoogleMapConfig` | Configuration Google Maps | `lib/src/config/google_map.dart` |

### Valeurs canoniques

```dart
EventConfiguration.key = "kosmos_event_config"
GoogleMapConfig.key    = "google_map"
```

---

## Theme Keys

Le package core ne définit pas de clés de thème propres. Il fournit l'infrastructure (`AppTheme`, `loadThemeData`) utilisée par les autres packages.

---

## Integration in App

### 1. Enregistrer les configs

```dart
// app/lib/main.dart
import 'package:core_kosmos/core_kosmos.dart';

AppModel(
  dependencies: DependenciesConfig(
    packages: {
      EventConfiguration.key: EventConfiguration(
        enablePushNotificationConfig: true,
        onMessage: (ctx, ref, msg) { /* ... */ },
        onMessageBackground: (ctx, ref, msg) { /* ... */ },
      ),
      GoogleMapConfig.key: GoogleMapConfig(
        googleMapApiKey: "YOUR_API_KEY",
      ),
    },
  ),
);
```

### 2. Thèmes (infrastructure)

```dart
// app/lib/config/theme.dart
import 'package:core_kosmos/core_kosmos.dart';

AppTheme initTheme(BuildContext context, AppModel model) {
  final appTheme = AppTheme(
    themeData: ThemeData(...),
  );
  
  // Utiliser loadThemeData() dans les widgets pour récupérer les thèmes
  return appTheme;
}
```

---

## Examples

### Récupérer EventConfiguration

```dart
EventConfiguration getEventConfiguration() {
  final config = getAppModel().dependencies.packages[EventConfiguration.key];
  assert(
    config == null || config is EventConfiguration,
    'Type mismatch for ${EventConfiguration.key}: expected EventConfiguration, got ${config.runtimeType}',
  );
  return (config as EventConfiguration?) ?? EventConfiguration();
}
```

### Récupérer GoogleMapConfig

```dart
GoogleMapConfig getGoogleMapConfig() {
  final config = getAppModel().dependencies.packages[GoogleMapConfig.key];
  assert(
    config == null || config is GoogleMapConfig,
    'Type mismatch for ${GoogleMapConfig.key}: expected GoogleMapConfig, got ${config.runtimeType}',
  );
  return (config as GoogleMapConfig?) ?? GoogleMapConfig();
}
```

### Utiliser loadThemeData (dans un widget)

```dart
final themeData = loadThemeData<MyThemeData>(
  widget.theme,              // Priorité 1: paramètre direct
  widget.themeName ?? "key", // Priorité 2: clé dans registry
  () => kDefaultMyTheme,     // Priorité 3: fallback
  isDark: ref.watch(isDarkModeProvider).isDarkMode,
);
```
