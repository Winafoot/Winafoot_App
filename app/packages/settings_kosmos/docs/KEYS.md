# settings_kosmos - Clés Config & Theme

Package: **settings_kosmos** (v4.0.0-pre)

---

## Config Keys

| Clé | Type | Description |
|-----|------|-------------|
| `KosmosSettingsConfig.key` | `KosmosSettingsConfig` | Configuration des pages settings |

### Valeur canonique

```dart
KosmosSettingsConfig.key = "kosmos-settings"
```

> ⚠️ **Bug legacy**: Le code source utilise `super("Kosmos-Settings")`. La clé canonique est `"kosmos-settings"` (lowercase). Migration appliquée.

---

## Theme Keys

| Clé | Type | Usage |
|-----|------|-------|
| `SettingsThemeKeys.main` | `KosmosSettingsThemeData` | Page settings |

### Valeur canonique

```dart
class SettingsThemeKeys {
  static const main = "kosmos-settings";
}
```

---

## Integration in App

### 1. Enregistrer la config

```dart
// app/lib/main.dart
import 'package:settings_kosmos/settings_kosmos.dart';

packages: {
  KosmosSettingsConfig.key: KosmosSettingsConfig(
    showProfilImage: true,
    showFullName: true,
    settingsSection: (ref) => [...],
  ),
}
```

### 2. Enregistrer le thème

```dart
// app/lib/config/theme.dart
appTheme.addTheme(SettingsThemeKeys.main, KosmosSettingsThemeData(...));
```

---

## Examples

### Récupérer KosmosSettingsConfig

```dart
KosmosSettingsConfig getKosmosSettingsConfig() {
  // Support legacy key + canonical key
  var config = getAppModel().dependencies.packages[KosmosSettingsConfig.key];
  config ??= getAppModel().dependencies.packages["Kosmos-Settings"]; // legacy
  assert(config == null || config is KosmosSettingsConfig, 'Type mismatch');
  return (config as KosmosSettingsConfig?) ?? KosmosSettingsConfig(
    settingsSection: (ref) => [],
  );
}
```
