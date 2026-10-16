import 'package:core_kosmos/core_kosmos.dart';

final localAuthVerifiedProvider = StateProvider<bool>((ref) {
  return false;
});

bool notificationFcmProvider = false;
