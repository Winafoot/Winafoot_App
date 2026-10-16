/// {@category Extension}
/// Extension of [num] :
///
/// - [autoPadLeft] : Return a string with the given padding (with the given character).
/// - [autoPadRight] : Return a string with the given padding (with the given character).
///
extension NumUtils on num {
  /// Return a string with the given padding, at left, (with the given character).
  ///
  /// [int] padding: Number of character to add.
  /// [String] padder: Character to use.
  ///
  String autoPadLeft(int length, [String padding = '0']) => toString().padLeft(length, padding);

  /// Return a string with the given padding, at right, (with the given character).
  ///
  /// [int] padding: Number of character to add.
  /// [String] padder: Character to use.
  ///
  String autoPadRight(int length, [String padding = '0']) => toString().padRight(length, padding);
}

/// {@category Extension}
/// Extension of [double] :
/// 
/// - [trimAndParse] : Return a double from a string.
/// 
extension DoubleUtils on double {
  static double? trimAndParse(String val) {
    return double.tryParse(val.replaceAll(' ', '').replaceAll(',', ".").replaceAll(RegExp(r"\s+"), ""));
}
  }

/// {@category Extension}
/// Extension of [int] :
/// 
/// - [trimAndParse] : Return a double from a string.
/// 
extension IntUtils on int {
  static int? trimAndParse(String val) {
    return int.tryParse(val.replaceAll(' ', '').replaceAll(',', ".").replaceAll(RegExp(r"\s+"), ""));
  }
}
