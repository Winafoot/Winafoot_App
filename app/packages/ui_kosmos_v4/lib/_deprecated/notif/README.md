### Add the following imports to your Dart code

```dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
```

![picture/intern-notif.gif](picture/intern-notif.gif)
![picture/attention-message.gif](picture/attention-message.gif)



```dart
CTA.primary(
  textButton: 'Show Banner',
  onTap: () => NotifBanner.showToast(fToast: FToast()),
),
const SizedBox(height: 15),
CTA.primary(
  textButton: 'Show Message',
  onTap: () => NotifBanner.showMessage(fToast: FToast()),
),
```