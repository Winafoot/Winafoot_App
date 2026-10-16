import 'package:core_kosmos/core_kosmos.dart';

/// {@category Extension}
/// Extension of [Duration] class.
///
/// - [toHHMMSS] : Return a string with the format HH:MM:SS.
/// - [toHHMM] : Return a string with the format HH:MM.
/// - [toMMSS] : Return a string with the format MM:SS.
/// - [formatTimeAgo] : Return a string with the format "now", "x seconds ago", "x minutes ago", "x hours ago", "x days ago", "x months ago", "x years ago".
///
extension DurationExtension on Duration {
  String get toHHMMSS {
    final hours = inHours;
    final minutes = inMinutes - hours * 60;
    final seconds = inSeconds - hours * 3600 - minutes * 60;
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  String get toHHMM {
    final hours = inHours;
    final minutes = inMinutes - hours * 60;
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}";
  }

  String get toMMSS {
    final minutes = inMinutes;
    final seconds = inSeconds - minutes * 60;
    return "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  String formatTimeAgo() {
    if (inSeconds < 30) {
      return "package.duration.now".tr();
    } else if (inMinutes < 1) {
      return "package.duration.seconds-ago".tr(args: [inSeconds.toString()]);
    } else if (inMinutes < 60) {
      return "package.duration.minutes-ago".tr(args: [inMinutes.toString()]);
    } else if (inHours < 24) {
      return "package.duration.hours-ago".tr(args: [inHours.toString()]);
    } else if (inDays < 30) {
      return "package.duration.days-ago".tr(args: [inDays.toString()]);
    } else if (inDays < 365) {
      for (int i = 1; i <= 12; i++) {
        if (inDays < 30 * i) {
          return "package.duration.month-ago".tr(args: [i.toString()]);
        }
      }
    } else {
      for (int i = 1; i <= 70; i++) {
        if (inDays < 365 * i) {
          return "package.duration.year-ago".tr(args: [i.toString()]);
        }
      }
    }
    return "package.duration.moment-ago".tr();
  }

  String formatWithCode() {
    if (inSeconds < 30) {
      return "package.duration.now".tr();
    } else if (inMinutes < 1) {
      return "package.duration.seconds-ago".tr(args: [inSeconds.toString()]);
    } else if (inMinutes < 60) {
      return "package.duration.minutes-ago".tr(args: [inMinutes.toString()]);
    } else if (inHours < 24) {
      return "package.duration.hours-ago".tr(args: [inHours.toString()]);
    } else if (inDays < 30) {
      return "package.duration.x-days".tr(args: [inDays.toString()]);
    } else if (inDays < 365) {
      for (int i = 1; i <= 12; i++) {
        if (inDays < 30 * i) {
          return "package.duration.month-ago".tr(args: [i.toString()]);
        }
      }
    } else {
      for (int i = 1; i <= 70; i++) {
        if (inDays < 365 * i) {
          return "package.duration.year-ago".tr(args: [i.toString()]);
        }
      }
    }
    return "package.duration.moment-ago".tr();
  }
}
