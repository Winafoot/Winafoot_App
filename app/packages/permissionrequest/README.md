# Kosmos Permission Package

Package de gestion des demandes de permissions pour les applications Kosmos Digital.

---

## 📋 Description

Ce package permet de :
- Afficher des écrans de demande de permissions (géolocalisation, notifications, etc.)
- Créer des flows de permissions personnalisés
- Gérer l'état de complétion des permissions

---

## ⚙️ Configuration

### Clé de configuration

| Clé | Type | Description |
| --- | --- | --- |
| `"permission-kosmos"` | `PermissionConfig` | Configuration du package |

### Récupération de la config

```dart
final config = getAppModel().dependencies.packages["permission-kosmos"] as PermissionConfig?;
```

### Exemple de configuration

```dart
AppModel(
  dependencies: DependenciesConfig(
    packages: {
      "permission-kosmos": PermissionConfig(
        permissions: [
          PermissionDataModel(
            title: () => "Notifications",
            description: () => "Recevez des alertes importantes",
            imagePath: "assets/images/notif.png",
            buttonText: () => "Autoriser",
            onActionButtonPressed: (ctx, ref, controller, isLast) async {
              await NotificationPermissionController.requestPermission();
              if (isLast) {
                await PermissionController.setPermissionAsComplete();
                AutoRouter.of(ctx).replaceNamed("/");
              } else {
                controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            },
          ),
        ],
        showBackButton: true,
        showSkipButton: true,
        onSkipButtonPressed: (controller, ctx) async {
          await PermissionController.setPermissionAsComplete();
          AutoRouter.of(ctx).replaceNamed("/");
        },
      ),
    },
  ),
);
```

### Options de configuration

| Propriété | Type | Description |
| --- | --- | --- |
| `permissions` | `List<PermissionDataModel>` | Liste des permissions à demander |
| `showBackButton` | `bool?` | Affiche le bouton retour |
| `showSkipButton` | `bool?` | Affiche le bouton "Passer" |
| `onSkipButtonPressed` | `Function?` | Callback au clic sur "Passer" |
| `backgroundChild` | `Widget Function(BuildContext)?` | Widget de fond personnalisé |

---

## 🎨 Thèmes

| Clé de thème | Type | Description |
| --- | --- | --- |
| `"permission"` | `PermissionThemeData` | Thème des écrans de permission |

### Propriétés du thème

```dart
PermissionThemeData(
  skipButtonStyle: TextStyle?,
  backButtonThemeName: String?,
  titleStyle: TextStyle?,
  descriptionStyle: TextStyle?,
  childSize: Size?,
  logoSize: Size?,
  backgroundColor: Color?,
  backgroundGradient: Gradient?,
)
```

### Enregistrement du thème

```dart
appTheme.addTheme("permission", PermissionThemeData(
  titleStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  descriptionStyle: TextStyle(fontSize: 14, color: Colors.grey),
  backgroundGradient: LinearGradient(
    colors: [Colors.blue.shade100, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
));
```

---

## 📖 Usage

### Widget de permissions

```dart
PermissionWidget(
  permissions: [
    PermissionDataModel(
      title: () => "Géolocalisation",
      description: () => "Pour vous proposer des services proches de vous",
      svgPath: "assets/svg/location.svg",
      buttonText: () => "Autoriser",
      onActionButtonPressed: (ctx, ref, controller, isLast) async {
        // Demander la permission
      },
    ),
  ],
  appLogoAsset: "assets/images/logo.png",
)
```

### Widgets prédéfinis

```dart
// Permission de géolocalisation
GeolocPermission()

// Permission de notifications
NotificationsPermission()

// PageView avec les deux
PermissionsPageView()

// PageView personnalisé
PermissionsPageViewCustom(permissions: [...])
```

### Vérifier si les permissions sont complètes

```dart
final isComplete = await PermissionController.isPermissionComplete();
if (!isComplete) {
  AutoRouter.of(context).pushNamed("/permissions");
}
```

### Marquer les permissions comme complètes

```dart
await PermissionController.setPermissionAsComplete();
```

---

## 🌐 Traductions requises

```
package.permission.skip
```
