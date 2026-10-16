import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'disponibility_model.freezed.dart';
part 'disponibility_model.g.dart';

@freezed
class DisponibilityModel with _$DisponibilityModel {
  const factory DisponibilityModel({
    @Default(true) final bool isOpen,
    @Default([]) List<DisponibilityItemModel> items,
  }) = _DisponibilityModel;

  factory DisponibilityModel.fromJson(Map<String, dynamic> json) => _$DisponibilityModelFromJson(json);
}

@freezed
class DisponibilityItemModel with _$DisponibilityItemModel {
  const factory DisponibilityItemModel({
    @TimestampConverter() final DateTime? from,
    @TimestampConverter() final DateTime? to,
    @Default(false) bool isPaused,
  }) = _DisponibilityItemModel;

  factory DisponibilityItemModel.fromJson(Map<String, dynamic> json) => _$DisponibilityItemModelFromJson(json);
}
