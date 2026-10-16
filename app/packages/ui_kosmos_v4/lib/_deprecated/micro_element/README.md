### In the ``pubspec.yaml`` of your flutter project, add the following dependency:

```
dependencies:
  ...
  toggle_switch: ^2.0.1
```

### Add the following imports to your Dart code

```dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:toggle_switch/toggle_switch.dart';
```

![picture/micro_element.gif](picture/micro_element.gif)

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  mainAxisAlignment: MainAxisAlignment.center,
  children: const [
    LoaderClassique(),
    ThreeBounce(
      color: Color(0xFF02132B),
    ),
  ],
),
const SizedBox(height: 15),
const ProgressBar(
  customSmallTitle: 'Étape 2 /5',
  textStyle: TextStyle(
    color: Color(0xFF02132B),
    fontSize: 10,
    fontWeight: FontWeight.w600,
  ),
  current: 2,
  max: 5,
),
const SizedBox(height: 15),
ToggleSwitch(
  minWidth: 150,
  minHeight: 40,
  radiusStyle: true,
  cornerRadius: 7,
  fontSize: 12,
  labels: const ["Titre de l'item", "Titre de l'item"],
  activeBgColor: const [Color(0xFF02132B)],
  inactiveBgColor: const Color(0xFFF7F7F8),
  activeFgColor: Colors.white,
  inactiveFgColor: const Color(0xFF9299A4),
),
```