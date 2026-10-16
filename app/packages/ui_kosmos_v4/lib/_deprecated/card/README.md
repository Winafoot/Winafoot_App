### Add the following imports to your Dart code

```dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
```

![picture/cards.gif](picture/cards.gif)


```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: const [
    Cards.one(),
    Spacer(),
    Cards.one(center: true),
  ],
),
const SizedBox(height: 15),
const Cards.two(
  horizontal: true,
),
const SizedBox(height: 15),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: const [
    Cards.two(),
    Spacer(),
    Cards.three(),
  ],
),
const SizedBox(height: 15),
const Cards.fourth(horizontal: true),
const SizedBox(height: 15),
Row(
  children: const [
    Cards.fourth(),
    Spacer(),
  ],
),
const SizedBox(height: 15),
const Cards.five(
  bigImage: false,
),
const SizedBox(height: 15),
const Cards.six(),
const SizedBox(height: 15),
const Cards.seven(),
const SizedBox(height: 15),
const Cards.seven(
  variant: true,
),
const SizedBox(height: 15),
const Cards.eight(),
const SizedBox(height: 15),
const Cards.nine(),
```