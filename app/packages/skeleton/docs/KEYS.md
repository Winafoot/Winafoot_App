# skeleton - Clés Config & Theme

Package: **skeleton** (v4.0.0-pre)

---

## Config Keys

| Clé | Type | Description |
|-----|------|-------------|
| `SkeletonAppConfig.key` | `SkeletonAppConfig` | Configuration principale du skeleton |
| `OnboardingConfig.key` | `OnboardingConfig` | Configuration de l'onboarding |

### Valeurs canoniques

```dart
SkeletonAppConfig.key = "skeleton_app_config"
OnboardingConfig.key  = "kosmos-onboarding"
```

---

## Theme Keys

| Clé | Type | Usage |
|-----|------|-------|
| `SkeletonThemeKeys.authentication` | `AuthTemplateThemeData` | Pages d'authentification |
| `SkeletonThemeKeys.footer` | `SkeletonWebThemeData` | Footer web |

### Valeurs canoniques

```dart
class SkeletonThemeKeys {
  static const authentication = "authentication_theme";
  static const footer = "skeleton_footer";
}
```

---

## Integration in App

### 1. Enregistrer les configs

```dart
// app/lib/main.dart
import 'package:skeleton/skeleton.dart';

AppModel(
  dependencies: DependenciesConfig(
    packages: {
      SkeletonAppConfig.key: SkeletonAppConfig(
        mainRouteInfo: HomeRoute(),
        logoPath: "assets/logo.svg",
        authentificationConfig: SkeletonAuthentificationConfig(
          canCreateAccount: true,
          canLoginWithPhone: true,
          authTiers: [AuthTiers.apple, AuthTiers.google],
        ),
      ),
      OnboardingConfig.key: OnboardingConfig(...),
    },
  ),
);
```

### 2. Enregistrer les thèmes

```dart
// app/lib/config/theme.dart
appTheme.addTheme(SkeletonThemeKeys.authentication, AuthTemplateThemeData(
  subtitleStyle: TextStyle(...),
  linkStyle: TextStyle(...),
));
```

---

## Examples

### Récupérer SkeletonAppConfig

```dart
SkeletonAppConfig getSkeletonAppConfig() {
  final config = getAppModel().dependencies.packages[SkeletonAppConfig.key];
  assert(config == null || config is SkeletonAppConfig, 'Type mismatch');
  return (config as SkeletonAppConfig?) ?? SkeletonAppConfig(
    mainRouteInfo: null,
    logoPath: "",
  );
}
```
