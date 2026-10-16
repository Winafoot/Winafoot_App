# Kosmos UI Package

Package de composants UI réutilisables pour les applications Kosmos Digital.

---

## 📋 Description

Ce package fournit :
- Boutons personnalisables (`KosmosButton`)
- Champs de formulaire (`KosmosFormField`)
- Composants de liste
- Utilitaires de style et couleurs

---

## ⚙️ Configuration

**Aucune clé de configuration** - Ce package n'utilise pas le système `PackageConfig`.

Les composants UI sont configurés via le système de thème.

---

## 🎨 Thèmes

### Thèmes de boutons

| Clé de thème | Type | Description |
| --- | --- | --- |
| `"button_primary"` | `KosmosButtonThemeData` | Bouton principal |
| `"button_secondary"` | `KosmosButtonThemeData` | Bouton secondaire |
| `"button_text"` | `KosmosButtonThemeData` | Bouton texte (sans fond) |
| `"button_icon"` | `KosmosButtonThemeData` | Bouton icône |

### Thème de champs de formulaire

| Clé de thème | Type | Description |
| --- | --- | --- |
| `"form_field"` | `FormFieldThemeData` | Thème des champs de saisie |

### Thème des cellules settings

| Clé de thème | Type | Description |
| --- | --- | --- |
| `"settings_cellule"` | `SettingsCelluleThemeData` | Thème des cellules de paramètres |

---

## 📖 Usage

### KosmosButton

```dart
// Avec thème par défaut
KosmosButton(
  text: "Valider",
  onPressed: () => print("Cliqué"),
)

// Avec thème personnalisé
KosmosButton(
  text: "Annuler",
  themeName: "button_secondary",
  onPressed: () => Navigator.pop(context),
)

// Avec thème inline
KosmosButton(
  text: "Custom",
  theme: KosmosButtonThemeData(
    backgroundColor: Colors.red,
    textStyle: TextStyle(color: Colors.white),
  ),
  onPressed: () {},
)
```

### KosmosButtonThemeData

```dart
KosmosButtonThemeData(
  textStyle: TextStyle?,
  backgroundColor: Color?,
  borderRadius: BorderRadius?,
  padding: EdgeInsets?,
  elevation: double?,
  disabledBackgroundColor: Color?,
  disabledTextStyle: TextStyle?,
  loadingIndicatorColor: Color?,
)
```

### KosmosFormField

```dart
KosmosFormField(
  controller: myController,
  fieldName: "Email",
  fieldHint: "Entrez votre email",
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty ?? true ? "Requis" : null,
)
```

### FormFieldThemeData

```dart
FormFieldThemeData(
  fieldNameStyle: TextStyle?,
  inputDecoration: InputDecoration?,
  textStyle: TextStyle?,
  errorStyle: TextStyle?,
)
```

---

## 🎯 Enregistrement des thèmes

```dart
void initTheme() {
  final appTheme = AppTheme();
  GetIt.instance.registerSingleton<AppTheme>(appTheme);

  // Bouton principal
  appTheme.addTheme("button_primary", KosmosButtonThemeData(
    backgroundColor: Colors.blue,
    textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    borderRadius: BorderRadius.circular(8),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ));

  // Bouton secondaire
  appTheme.addTheme("button_secondary", KosmosButtonThemeData(
    backgroundColor: Colors.grey.shade200,
    textStyle: TextStyle(color: Colors.black87),
    borderRadius: BorderRadius.circular(8),
  ));

  // Champ de formulaire
  appTheme.addTheme("form_field", FormFieldThemeData(
    fieldNameStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    inputDecoration: InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
  ));
}
```

---

## 🔗 Intégration

Ce package est utilisé par tous les autres packages pour les composants UI de base.

Les packages suivants dépendent de `ui` :
- `skeleton` - Pages d'authentification
- `settings` - Cellules de paramètres
- `tchat` - Interface de messagerie
- `commentary` - Formulaires de commentaires
