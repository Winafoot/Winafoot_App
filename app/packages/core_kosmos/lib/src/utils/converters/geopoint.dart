import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';


/// 
/// Permet de faire la liaison entre un [GeoPoint] de [FirebaseFirestore] avec un bojet [Freezed].
class GeoPointConverters implements JsonConverter<GeoPoint?, GeoPoint?> {
  const GeoPointConverters();

  @override
  GeoPoint? fromJson(GeoPoint? geoPoint) {
    return geoPoint;
  }

  @override
  GeoPoint? toJson(GeoPoint? geoPoint) => geoPoint;
}