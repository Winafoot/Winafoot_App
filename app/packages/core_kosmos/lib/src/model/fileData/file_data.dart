import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_data.freezed.dart';
part 'file_data.g.dart';

@freezed
class FileData with _$FileData {
  factory FileData({
    final String? url,
    final String? fileName,
  }) = _FileData;

  factory FileData.fromJson(Map<String, dynamic> json) =>
      _$FileDataFromJson(json);
}
