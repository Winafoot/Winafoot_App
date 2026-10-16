import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    /// Required fields
    required final List<String> sendToIds,
    required final String title,
    final String? body,
    final String? type,
    @Default(false) final bool toTopic,
    final String? topic,
    final Map<String, dynamic>? metadata,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) => _$NotificationModelFromJson(json);
}
