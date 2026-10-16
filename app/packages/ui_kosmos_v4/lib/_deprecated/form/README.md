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
TextFormUpdated.classic(
  fieldName: 'Titre*',
  focusNode: classicNode,
  nextFocusNode: dateNode,
),
const SizedBox(height: 15),
TextFormUpdated.dateTime(
  fieldName: 'Titre*',
  focusNode: dateNode,
  nextFocusNode: telephoneNode,
),
const SizedBox(height: 15),
TextFormUpdated.phoneNumber(
  fieldName: 'Titre*',
  focusNode: telephoneNode,
  nextFocusNode: immatriculationNode,
  onInputChanged: (phone) {},
),
const SizedBox(height: 15),
TextFieldImmatriculation(
  initialValue: 'GB-234-DE',
  stringSpacer: '-',
  onChanged: (p0) => print(p0),
  onFieldSubmitted: (p0) => print(p0),
  format: [
    Immatformat(flex: 4, maxChar: 2, hintText: 'AB'),
    Immatformat(flex: 7, maxChar: 3, hintText: '123'),
    Immatformat(flex: 4, maxChar: 2, hintText: 'CD'),
  ],
  fieldName: 'Titre*',
  focusNode: immatriculationNode,
  hintText: '00CBA00',
),
const SizedBox(height: 15),
const TextFormUpdated.select(
  fieldName: 'Select*',
),
const SizedBox(height: 15),
const TextFormUpdated.textarea(
  fieldName: 'Textarea*',
),
const SizedBox(height: 15),
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
const SizedBox(height: 15),
fieldWithSuggestion(onlyTitle, _typeAheadController),
const SizedBox(height: 15),
fieldWithSuggestion(titleAndSubtitle, _typeAheadController),
const SizedBox(height: 15),
fieldWithSuggestion(titleAndSubtitleAndPicture, _typeAheadController),



/// FIELD SUGGESTION

class CustomSuggestion {
  CustomSuggestion({
    required this.suggestion,
    required this.completion,
    this.sousCompletion,
    this.picture,
  });

  String suggestion;
  String completion;
  String? sousCompletion;
  ImageProvider? picture;
}

Widget fieldWithSuggestion(List<CustomSuggestion> list, TextEditingController controller) {
  return Row(
    children: [
      Expanded(
        child: TypeAheadField(
          hideOnLoading: true,
          noItemsFoundBuilder: (context) {
            return const Text('No Items Found!');
          },
          suggestionsBoxDecoration: SuggestionsBoxDecoration(
            elevation: 0,
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
          ),
          textFieldConfiguration: TextFieldConfiguration(
              style: const TextStyle(color: Color(0xFF02132B), fontSize: 15, fontWeight: FontWeight.w500),
              controller: controller,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10),
                prefixIcon: const Icon(
                  Iconsax.search_normal_1,
                  size: 24,
                  color: Color(0xFF9299A4),
                ),
                hintText: 'Pizza, italien, burger ..',
                hintStyle: const TextStyle(color: Color(0xFF9299A4), fontSize: 12, fontWeight: FontWeight.w500),
                fillColor: const Color(0xFF02132B).withOpacity(0.03),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(width: 0.0, style: BorderStyle.none)),
              )),
          suggestionsCallback: (String suggestion) {
            List<CustomSuggestion> matches = <CustomSuggestion>[];
            for (var element in list) {
              matches.add(CustomSuggestion(
                  suggestion: element.suggestion,
                  completion: element.completion,
                  sousCompletion: element.sousCompletion,
                  picture: element.picture));
            }

            matches.retainWhere((s) => s.suggestion.toLowerCase().contains(suggestion.toLowerCase()));
            return matches.length > 3 ? matches.getRange(0, 3).toList() : matches;
          },
          itemBuilder: (ctx, CustomSuggestion listSuggest) {
            return ListTile(
              visualDensity: const VisualDensity(vertical: -4),
              minLeadingWidth: 10,
              horizontalTitleGap: 6,
              contentPadding: const EdgeInsets.only(left: 18),
              title: Text(
                listSuggest.completion,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF02132B)),
              ),
              subtitle: listSuggest.sousCompletion != null
                  ? Text(
                      listSuggest.sousCompletion!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF5A6575)),
                    )
                  : null,
              leading: listSuggest.picture != null
                  ? Container(
                      height: double.infinity,
                      width: 26,
                      alignment: Alignment.center,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: listSuggest.picture!)),
                    )
                  : null,
            );
          },
          onSuggestionSelected: (CustomSuggestion suggestion) => controller.text = suggestion.completion,
        ),
      ),
      const SizedBox(width: 9),
      IconButton(
          iconSize: 24,
          icon: const Icon(
            Iconsax.setting_44,
            color: Color(0xFF02132B),
          ),
          onPressed: () {},
          padding: EdgeInsets.zero,
          splashRadius: 30),
    ],
  );
}
```
