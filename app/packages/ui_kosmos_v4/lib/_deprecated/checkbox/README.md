### Add the following imports to your Dart code

```dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
```

![picture/checkbox.gif](picture/checkbox.gif)


```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Transform.scale(
      scale: 1.5,
      child: CustomCheckbox.square(
        isChecked: isChecked,
        onTap: () {
            setState(() {
                isChecked ? isChecked = false : isChecked = true;
            });
        },
      ),
    ),
    const SizedBox(width: 50),
    Transform.scale(
      scale: 1.5,
      child: CustomCheckbox.circle(
        isChecked: isChecked,
        onTap: () {
            setState(() {
                isChecked ? isChecked = false : isChecked = true;
            });
        },
      ),
    ),
    const SizedBox(width: 50),
    Transform.scale(
      scale: 1.2,
      child: CupertinoSwitch(
        activeColor: const Color(0xFF02132B),
        value: isChecked,
        onChanged: (check) {
            setState(() {
                isChecked = check;
            });
        }),
    ),
  ],
),
```