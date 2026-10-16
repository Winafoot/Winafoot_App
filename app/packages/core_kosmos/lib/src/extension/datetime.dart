extension DateTimeUtils on DateTime {
  /// Check if same day
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if same month
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Check if same year
  bool isSameYear(DateTime other) {
    return year == other.year;
  }
}
