import 'package:core_kosmos/core_kosmos.dart';
import 'package:freezed_annotation/freezed_annotation.dart';


class NumberHashConverter implements JsonConverter<num?, String?> {
  const NumberHashConverter();

  @override
  num? fromJson(String? json) {
    if (json == null) return null;
    if (json.isEmpty) return 0;
    return DoubleUtils.trimAndParse(KosmosHashController.decrypt(json));
  }

  @override
  String? toJson(num? object) {
    if (object == null) return null;
    return KosmosHashController.encrypt(object.toString());
  }
}