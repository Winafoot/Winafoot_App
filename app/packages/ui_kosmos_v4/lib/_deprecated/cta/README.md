### Add the following imports to your Dart code

```dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
```

![picture/cta.jpg](picture/cta.jpg)

```dart
  const CTA.primary(),
  const SizedBox(height: 15),
  const CTA.primary(
    beforeIcon: Iconsax.export_3,
  ),
  const SizedBox(height: 15),
  const CTA.primary(
    afterIcon: Iconsax.export_3,
  ),
  const SizedBox(height: 15),
  const CTA.secondary(),
  const SizedBox(height: 15),
  const CTA.secondary(
    beforeIcon: Iconsax.export_3,
  ),
  const SizedBox(height: 15),
  const CTA.secondary(
    afterIcon: Iconsax.export_3,
  ),
  const SizedBox(height: 15),
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [
      CTA.tiers(circleOnTap: true, textButton: 'Titre'),
      SizedBox(width: 50),
      CTA.tiers(
        circleOnTap: true,
        icon: Icon(Iconsax.export_3),
        textButton: 'Titre',
      ),
      SizedBox(width: 50),
      CTA.tiers(circleOnTap: true, icon: Icon(Iconsax.export_3)),
    ],
  ),
  const SizedBox(height: 15),
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [
      CTA.back(),
      SizedBox(
        width: 50,
      ),
      CTA.back(
        backgroundColor: Colors.transparent,
      ),
    ],
  ),
```