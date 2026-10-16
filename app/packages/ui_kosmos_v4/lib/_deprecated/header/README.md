### Add the following imports to your Dart code

```dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
```

![picture/header.gif](picture/header.gif)


```dart
const Header.primary(),
const SizedBox(height: 15),
const Header.primary(
  reverse: true,
),
const SizedBox(height: 15),
const Header.primary(icon: Icon(Icons.search)),
const SizedBox(height: 15),
const Header.primary(icon: Icon(Icons.search), reverse: true),
const SizedBox(height: 15),
const Header.secondary(),
const SizedBox(height: 15),
const Header.secondary(reverse: true),
const SizedBox(height: 15),
const Header.third(),
const SizedBox(height: 15),
Header.third(
  onTapBack: () {},
),
const SizedBox(height: 15),
Header.third(
  onTapIcon: () {},
),
const SizedBox(height: 15),
Header.third(
  onTapBack: () {},
  onTapIcon: () {},
),
```