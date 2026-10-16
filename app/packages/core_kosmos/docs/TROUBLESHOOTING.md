# core_kosmos - Troubleshooting

Guide de dépannage pour les problèmes courants.

---

## Config manquante

### Symptôme

```
NoSuchMethodError: The getter 'myOption' was called on null.
```

### Diagnostic

```dart
// Afficher toutes les clés enregistrées
print(getAppModel().dependencies.packages.keys);

// Vérifier le type
final raw = getAppModel().dependencies.packages["ma-cle"];
print("Type: ${raw.runtimeType}");
```

### Solutions

1. **Clé non enregistrée**: Ajouter la config dans `AppModel.dependencies.packages`
2. **Typo dans la clé**: Utiliser `XConfig.key` au lieu d'une string inline
3. **Mauvais type**: Vérifier que la config est du bon type avec `as XConfig?`

### Pattern recommandé

```dart
XConfig getXConfig() {
  final config = getAppModel().dependencies.packages[XConfig.key];
  assert(
    config == null || config is XConfig,
    'Type mismatch for ${XConfig.key}: expected XConfig, got ${config.runtimeType}',
  );
  return (config as XConfig?) ?? const XConfig();
}
```

---

## Thème manquant

### Symptôme

Le widget utilise le thème par défaut au lieu du thème personnalisé.

### Diagnostic

```dart
// Afficher tous les thèmes enregistrés
GetIt.instance<AppTheme>().dumpLog();

// Vérifier si le thème existe
final theme = GetIt.instance<AppTheme>().fetchTheme<MyThemeData>("ma-cle");
print("Theme trouvé: ${theme != null}");
```

### Solutions

1. **Thème non enregistré**: Ajouter dans `initTheme()`:
   ```dart
   appTheme.addTheme("ma-cle", MyThemeData(...));
   ```

2. **Dark mode non géré**: Ajouter la version dark:
   ```dart
   appTheme.addTheme("ma-cle", lightTheme, darkTheme: darkTheme);
   ```

3. **Mauvaise clé**: Utiliser `XThemeKeys.main` au lieu d'une string inline

4. **loadThemeData mal configuré**: Vérifier l'ordre des paramètres:
   ```dart
   loadThemeData<T>(
     widget.theme,     // Peut être null
     "key",            // Clé dans registry
     () => kDefault,   // Fallback obligatoire
     isDark: isDark,
   );
   ```

---

## Erreurs fréquentes

### 1. String inline au lieu de constante

```dart
// ❌ INTERDIT - typo possible
packages["kosmos_event_config"]

// ✅ CORRECT
packages[EventConfiguration.key]
```

### 2. Pas de fallback

```dart
// ❌ DANGEREUX - NPE si non enregistré
final config = getAppModel().dependencies.packages["key"] as MyConfig;

// ✅ CORRECT
final config = (getAppModel().dependencies.packages[MyConfig.key] as MyConfig?) 
    ?? const MyConfig();
```

### 3. AppTheme non enregistré dans GetIt

```dart
// Vérifier
if (!GetIt.instance.isRegistered<AppTheme>()) {
  print("AppTheme non enregistré!");
}
```

### 4. Dark mode ignoré

```dart
// ❌ INCORRECT - isDark toujours false
loadThemeData<T>(theme, key, fallback);

// ✅ CORRECT
loadThemeData<T>(theme, key, fallback, isDark: ref.watch(isDarkModeProvider).isDarkMode);
```

---

## Debug avancé

### Afficher l'état complet

```dart
void debugKosmosState() {
  print("=== CONFIGS ===");
  getAppModel().dependencies.packages.forEach((key, value) {
    print("  $key: ${value.runtimeType}");
  });
  
  print("\n=== THEMES ===");
  if (GetIt.instance.isRegistered<AppTheme>()) {
    GetIt.instance<AppTheme>().dumpLog();
  } else {
    print("  AppTheme non enregistré");
  }
}
```
