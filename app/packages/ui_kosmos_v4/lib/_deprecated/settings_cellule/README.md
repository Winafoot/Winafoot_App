### Add the following imports to your Dart code

```dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
```

![picture/cellule-settings.jpg](picture/cellule-settings.jpg)


```dart
SettingsCellule(
  onClick: () {},
  subtitle: 'prenom.nom@example.com',
  title: 'Anna Clark',
  image: const NetworkImage(
      'https://static.remove.bg/remove-bg-web/19c2a5c2699621496a98aec1b8fd0618590c36e2/assets/start-1abfb4fe2980eabfbbaaa4365a0692539f7cd2725f324f904565a9a744f8e214.jpg'),
),
const SizedBox(height: 15),
SettingsCellule(
  subtitle: 'prenom.nom@example.com',
  title: 'Anna Clark',
  onClick: () {},
),
const SizedBox(height: 15),
SettingsCellule(
  title: 'Sécurité',
  subtitle: 'Adresse email, tel, mot de passe',
  onClick: () {},
  icon: const Icon(
    Icons.lock_outline,
    color: Colors.white,
    size: 16,
  ),
),
const SizedBox(height: 15),
SettingsCellule(onClick: () {}, subtitle: 'Sous-titre'),
const SizedBox(height: 15),
SettingsCellule(onClick: () {}),
```