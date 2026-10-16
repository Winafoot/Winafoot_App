# permissionrequest - Clés Config & Theme

Package: **permissionrequest**

---

## Config Keys

| Clé | Type | Description |
|-----|------|-------------|
| `PermissionConfig.key` | `PermissionConfig` | Configuration des demandes de permission |

### Valeur canonique

```dart
PermissionConfig.key = "permission-kosmos"
```

---

## Theme Keys

| Clé | Type | Usage |
|-----|------|-------|
| `PermissionThemeKeys.main` | `PermissionThemeData` | Écrans de permission |

### Valeur canonique

```dart
class PermissionThemeKeys {
  static const main = "permission";
}
```

---

## Integration in App

### 1. Enregistrer la config

```dart
packages: {
  PermissionConfig.key: PermissionConfig(
    permissions: [
      PermissionDataModel(permission: Permission.camera, ...),
      PermissionDataModel(permission: Permission.microphone, ...),
    ],
    showSkipButton: true,
  ),
}
```

### 2. Enregistrer le thème

```dart
appTheme.addTheme(PermissionThemeKeys.main, PermissionThemeData(...));
```

---

## Examples

### Récupérer PermissionConfig

```dart
PermissionConfig getPermissionConfig() {
  final config = getAppModel().dependencies.packages[PermissionConfig.key];
  assert(config == null || config is PermissionConfig, 'Type mismatch');
  return (config as PermissionConfig?) ?? PermissionConfig(permissions: []);
}
```
