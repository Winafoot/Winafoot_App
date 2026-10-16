import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';


/// 
/// Permet de faire la liaison entre un [DocumentReference] de [FirebaseFirestore] avec un bojet [Freezed].
class DocumentReferenceJsonConverter implements JsonConverter<DocumentReference?, Object?> {
  const DocumentReferenceJsonConverter();

  @override
  DocumentReference? fromJson(Object? json) {
    return (json as DocumentReference?);
  }

  @override
  Object? toJson(DocumentReference? documentReference) => documentReference;
}