# Kosmos Settings Package

Package de gestion des pages de paramètres pour les applications Kosmos Digital.

---

## 📋 Description

Ce package permet de :
- Créer des pages de paramètres structurées en sections
- Gérer les cellules de navigation (action, switch, info)
- Afficher le profil utilisateur avec modification d'image
- Créer des sous-pages de paramètres imbriquées

---

## ⚙️ Configuration

### Clé de configuration

| Clé | Type | Description |
| --- | --- | --- |
| `"kosmos-settings"` | `KosmosSettingsConfig` | Configuration du package |

> ⚠️ **Note** : La classe déclare `super("Kosmos-Settings")` mais est récupérée avec `"kosmos-settings"` (minuscule). Utilisez toujours la clé en minuscule.

### Récupération de la config

```dart
final config = getAppModel().dependencies.packages["kosmos-settings"] as KosmosSettingsConfig?;
```

### Exemple de configuration

```dart
KosmosSettingsConfig initKosmosSettingsConfig() {
  return KosmosSettingsConfig(
    showProfilInfo: true,
    showProfilImage: true,
    canModifyProfilImage: true,
    showFullName: true,
    showEmail: true,
    showAppLogo: false,
    showKosmosDigitalLine: true,
    pathSettingsNode: "app/profile/settings/",
    
    settingsSection: (ref) => [
      CelluleSection(
        title: (_, __) => "Général",
        cellules: [
          CelluleModel(
            tag: "notifications",
            title: (_, __) => "Notifications",
            subtitle: (_, __) => "Gérer les notifications",
            type: CelluleType.action,
            onTap: (ctx, ref) async {
              AutoRouter.of(ctx).pushNamed("/settings/notifications");
              return null;
            },
          ),
          CelluleModel(
            tag: "dark-mode",
            title: (_, __) => "Mode sombre",
            type: CelluleType.switchButton,
            switchValue: (ref) => ref.watch(isDarkModeProvider).isDarkMode,
            onSwitchChanged: (ctx, ref, value) async {
              ref.read(isDarkModeProvider).toggleDarkMode();
            },
          ),
        ],
      ),
      CelluleSection(
        title: (_, __) => "Sécurité",
        cellules: [
          CelluleModel(
            tag: "change-password",
            title: (_, __) => "Modifier le mot de passe",
            type: CelluleType.action,
            onTap: (ctx, ref) async {
              AutoRouter.of(ctx).pushNamed("app/profile/security/password");
              return null;
            },
          ),
        ],
      ),
    ],
  );
}
```

### Options de configuration principales

| Propriété | Type | Description |
| --- | --- | --- |
| `settingsSection` | `List<CelluleSection> Function(WidgetRef)` | Sections de paramètres |
| `showProfilInfo` | `bool` | Affiche les infos profil |
| `showProfilImage` | `bool` | Affiche l'image de profil |
| `canModifyProfilImage` | `bool` | Permet de modifier l'image |
| `showFullName` | `bool` | Affiche le nom complet |
| `showEmail` | `bool` | Affiche l'email |
| `showAppLogo` | `bool` | Affiche le logo de l'app |
| `pathSettingsNode` | `String` | Chemin de base pour les sous-pages |
| `canDeleteAccount` | `Future<bool> Function(WidgetRef)?` | Vérifie si suppression autorisée |

---

## 🎨 Thèmes

| Clé de thème | Type | Description |
| --- | --- | --- |
| `"kosmos-settings"` | `KosmosSettingsThemeData` | Thème de la page settings |
| `"settings_cellule"` | `SettingsCelluleThemeData` | Thème des cellules |

### KosmosSettingsThemeData

```dart
KosmosSettingsThemeData(
  fullNameStyle: TextStyle?,
  emailStyle: TextStyle?,
  sectionTitleStyle: TextStyle?,
  actionIconColor: Color?,
  pageBackgroundColor: Color?,
  sectionSpacing: double?,
  selectedByTextStyle: TextStyle?,
  cliquableTextStyle: TextStyle?,
  dialogBoxNoTextStyle: TextStyle?,
  formFieldThemeName: String?,
  settingsButtonThemeName: String?,
  settingsBackgroundPage: Widget Function(BuildContext, WidgetRef)?,
  settingsSubNodeBackgroundPage: Widget Function(BuildContext, WidgetRef)?,
  settingsBackgroundPageScrollable: bool?,
)
```

### SettingsCelluleThemeData

```dart
SettingsCelluleThemeData(
  decoration: BoxDecoration?,
  titleStyle: TextStyle?,
  subtitleStyle: TextStyle?,
  actionIconColor: Color?,
  spaceBetweenCellules: double?,
)
```

### Enregistrement des thèmes

```dart
appTheme.addTheme("kosmos-settings", KosmosSettingsThemeData(
  fullNameStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  sectionTitleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  pageBackgroundColor: Colors.grey.shade50,
));

appTheme.addTheme("settings_cellule", SettingsCelluleThemeData(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  ),
  spaceBetweenCellules: 8,
));
```

---

## 📖 Usage

### Types de cellules

```dart
// Action - Navigation vers une autre page
CelluleModel(
  tag: "my-action",
  title: (_, __) => "Mon action",
  type: CelluleType.action,
  onTap: (ctx, ref) async { /* ... */ return null; },
)

// Switch - Toggle on/off
CelluleModel(
  tag: "my-switch",
  title: (_, __) => "Mon switch",
  type: CelluleType.switchButton,
  switchValue: (ref) => ref.watch(myProvider),
  onSwitchChanged: (ctx, ref, value) async { /* ... */ },
)

// Info - Affichage simple
CelluleModel(
  tag: "my-info",
  title: (_, __) => "Mon info",
  type: CelluleType.info,
  infoText: (_, __) => "Valeur actuelle",
)
```

### Sous-sections imbriquées

```dart
CelluleModel(
  tag: "parent-node",
  title: (_, __) => "Section parent",
  type: CelluleType.action,
  sectionChild: CelluleSection(
    title: (_, __) => "Sous-section",
    cellules: [
      CelluleModel(
        tag: "child-item",
        title: (_, __) => "Élément enfant",
        type: CelluleType.action,
        onTap: (ctx, ref) async { /* ... */ return null; },
      ),
    ],
  ),
)
```

### Cacher conditionnellement une cellule

```dart
CelluleModel(
  tag: "conditional",
  title: (_, __) => "Conditionnelle",
  type: CelluleType.action,
  hide: (ctx, ref) => !ref.watch(featureFlagProvider),
)
```

---

## 🔗 Routes recommandées

```dart
AutoRoute(
  path: "profile",
  page: ProfileParentPage,
  children: [
    AutoRoute(path: "settings", page: SettingsPage, initial: true),
    AutoRoute(path: "settings/:nodeTag", page: SubNodePage),
    AutoRoute(path: "security/email", page: ChangeEmailPage),
    AutoRoute(path: "security/password", page: ChangePasswordPage),
    AutoRoute(path: "security/phone-number", page: ChangePhonePage),
  ],
),
```

---

## 🌐 Traductions requises

```
package.settings.edited-by
package.settings.kosmos-digital
utils.what-do-you-want-to-do
package.image.from-gallery
package.image.from-camera
utils.cancel
utils.error
utils.error-default
```
