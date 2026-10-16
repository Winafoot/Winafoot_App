### In the ``pubspec.yaml`` of your flutter project, add the following dependency:

dependencies:
  ...
  toggle_switch: ^2.0.1

### Add the following imports to your Dart code

```dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
```

![picture/form.gif](picture/form.gif)

```dart
const Input.image(),
const SizedBox(height: 15),
Input.image(
  image: image,
  onTap: (() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      image = File(pickedFile!.path);
    });
  }),
),
const SizedBox(height: 15),
const Input.files(),
const SizedBox(height: 15),
Input.files(
  listNameFiles: [
    FileNameItem(
      fileName: 'test.png',
      onClear: () {},
    ),
    FileNameItem(
      fileName: 'test1.png',
      onClear: () {},
    ),
    FileNameItem(
      fileName: 'test2.png',
      onClear: () {},
    ),
  ],
  onTap: (() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      image = File(pickedFile!.path);
    });
  }),
),



```