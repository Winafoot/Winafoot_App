import 'package:freezed_annotation/freezed_annotation.dart';


/// 
/// Permet de faire la liaison entre un [Object] de [Null] avec un bojet [Freezed].
class NullConverter<T> implements JsonConverter<Object?, T?> {
  const NullConverter();

  @override
  Object? fromJson(T? json) {
    return null;
  }

  @override
  T? toJson(Object? object) {
    return null;
  }
}