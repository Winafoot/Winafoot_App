# ui_kosmos_v4 - Troubleshooting

## Thème non appliqué

### Symptôme

Le composant utilise le style par défaut au lieu du thème personnalisé.

### Diagnostic

```dart
// Vérifier les thèmes enregistrés
GetIt.instance<AppTheme>().dumpLog();
```

### Solutions

1. **Thème non enregistré**: Ajouter dans `initTheme()`:
   ```dart
   appTheme.addTheme(UiThemeKeys.buttonPrimary, myTheme);
   ```

2. **Mauvaise clé**: Utiliser `UiThemeKeys.*` au lieu de string

3. **Dark mode non géré**: 
   ```dart
   appTheme.addTheme(key, lightTheme, darkTheme: darkTheme);
   ```

## Bouton avec mauvais style

### Vérifier le ButtonType

```dart
// ButtonType détermine la clé de thème par défaut
Button(buttonType: ButtonType.primary)  // → "button_primary"
Button(buttonType: ButtonType.secondary) // → "button_secondary"
```

### Override explicite

```dart
Button(
  themeName: UiThemeKeys.buttonSecondary,
  // ...
);
```

## FormField style incorrect

### Vérifier l'enregistrement

```dart
appTheme.addTheme(UiThemeKeys.formField, FormFieldThemeData(
  inputDecoration: kDefaultInputDecoration.copyWith(...),
));
```

## Erreurs courantes

### 1. String inline

```dart
// ❌ Typo possible
themeName: "button_primay"

// ✅ Constante
themeName: UiThemeKeys.buttonPrimary
```

### 2. Fallback manquant

Les composants UI ont des fallbacks intégrés (`kDefaultButtonThemeData`, etc.) donc pas de crash, mais le style sera par défaut.
