import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:json_annotation/json_annotation.dart';

class PhoneNumberConverter implements JsonConverter<PhoneNumber?, Map<String, dynamic>?> {
  const PhoneNumberConverter();

  @override
  PhoneNumber? fromJson(Map<String, dynamic>? json) {
    return json == null
        ? null
        : PhoneNumber(
            phoneNumber: json['phoneNumber'],
            dialCode: json['dialCode'],
            isoCode: json['isoCode'],
          );
  }

  @override
  Map<String, dynamic>? toJson(PhoneNumber? number) {
    if (number == null) return null;
    return {
      'phoneNumber': number.phoneNumber,
      'dialCode': number.dialCode,
      'isoCode': number.isoCode,
    };
  }
}
