import 'package:freezed_annotation/freezed_annotation.dart';

part 'stripe_fees_model.freezed.dart';
part 'stripe_fees_model.g.dart';

@freezed
class StripeFeesModel with _$StripeFeesModel {
  const factory StripeFeesModel({
    num? percent,
    num? fixAmount,
  }) = _StripeFeesModel;

  factory StripeFeesModel.fromJson(Map<String, dynamic> json) =>
      _$StripeFeesModelFromJson(json);
}
