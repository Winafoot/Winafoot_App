import 'package:core_kosmos/src/controller/hash_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';


class StringHashConverter implements JsonConverter<String?, String?> {
  const StringHashConverter();

  @override
  String? fromJson(String? json) {
    if (json == null) return null;
    if (json.isEmpty) return json;
    return KosmosHashController.decrypt(json);
  }

  @override
  String? toJson(String? object) {
    if (object == null) return null;
    return KosmosHashController.encrypt(object);
  }
}