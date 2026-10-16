import 'package:freezed_annotation/freezed_annotation.dart';

part 'sized_image.freezed.dart';
part 'sized_image.g.dart';

@freezed
class SizedImage with _$SizedImage {
  factory SizedImage({
    final String? url,
    final String? compressedUrl,
  }) = _SizedImage;

  factory SizedImage.fromJson(Map<String, dynamic> json) => _$SizedImageFromJson(json);
}
