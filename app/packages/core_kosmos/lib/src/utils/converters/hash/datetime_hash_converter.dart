import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/src/controller/hash_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';


class DateTimeHashConverter implements JsonConverter<DateTime?, String?> {
  const DateTimeHashConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    if (json.isEmpty) return null;
    return Timestamp(int.parse(KosmosHashController.decrypt(json)) ~/ 1000, 0).toDate();
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    return KosmosHashController.encrypt(Timestamp.fromDate(object).millisecondsSinceEpoch.toString());
  }
}
