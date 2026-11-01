import 'package:freezed_annotation/freezed_annotation.dart';
part 'user_app_data.freezed.dart';
part 'user_app_data.g.dart';

@freezed
class UserAppData with _$UserAppData {
  factory UserAppData({@Default([]) final List<String> test}) = _UserAppData;
  factory UserAppData.fromJson(Map<String, dynamic> json) =>
      _$UserAppDataFromJson(json);
}
