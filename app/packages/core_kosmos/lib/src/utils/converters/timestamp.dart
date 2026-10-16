import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';


///
/// Permet de faire la liaison entre un [Timestamp] de [FirebaseFirestore] avec un bojet [Freezed].
class TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) {
      return null;
    } else if (json is Timestamp) {
      return json.toDate();
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    } else {
      throw ArgumentError('Invalid type for DateTime conversion');
    }
  }

  @override
  dynamic toJson(DateTime? object) {
    return object == null ? null : Timestamp.fromDate(object);
  }
}

class TimestampConverterNotNullable
    implements JsonConverter<DateTime, dynamic> {
  const TimestampConverterNotNullable();

  @override
  DateTime fromJson(dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    } else {
      throw ArgumentError('Invalid type for DateTime conversion');
    }
  }

  @override
  dynamic toJson(DateTime object) {
    return Timestamp.fromDate(object);
  }
}
