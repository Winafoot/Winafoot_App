import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_model.freezed.dart';
part 'filter_model.g.dart';

/// {@category Model}
/// {@subCategory Research}
@freezed
class FilterModel with _$FilterModel {
  const factory FilterModel({
    final String? tag,
    final String? value,
  })=_FilterModel;

  factory FilterModel.fromJson(Map<String, dynamic> json) => _$FilterModelFromJson(json);
}
