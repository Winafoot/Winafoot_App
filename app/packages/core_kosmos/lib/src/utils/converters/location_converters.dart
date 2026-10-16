import 'package:core_kosmos/core_kosmos.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class LocationModelConverterNullable
    implements JsonConverter<LocationModel?, Map<String, dynamic>?> {
  const LocationModelConverterNullable();

  @override
  LocationModel? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return LocationModel.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(LocationModel? object) {
    return object?.toJson();
  }
}

class LocationModelConverter
    implements JsonConverter<LocationModel, Map<String, dynamic>> {
  const LocationModelConverter();

  @override
  LocationModel fromJson(Map<String, dynamic> json) {
    return LocationModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(LocationModel object) {
    return object.toJson();
  }
}
