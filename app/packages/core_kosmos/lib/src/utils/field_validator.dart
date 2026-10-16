import 'package:core_kosmos/core_kosmos.dart';

/// {@category Utils}
/// {@category Validator}
///
/// FormField Validator sur les champs d'authentification.
abstract class AuthValidator {
  static String? validEmail(String? email) {
    if (email == null || email.isEmpty) return "package.validator.must-have-value".tr();
    final parsedEmail = email.trim().toLowerCase();
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-.]+\.[a-zA-Z]+").hasMatch(parsedEmail)) {
      return "package.validator.email-invalid".tr();
    }
    return null;
  }

  /// Vérifie que le mot de passe est valide (> 6 caractères, contient au moins une majuscule, une minuscule, un chiffre et un caractère spécial)
  static String? validPassword(String? password, [PasswordSecurityConfig? config]) {
    if (password == null || password.isEmpty) return "package.validator.must-have-value".tr();
    if ((config?.atLeast6Char ?? true) && password.length < 6) return "package.validator.password-invalid-length".tr();
    if ((config?.atLeast1Uppercase ?? true) && !password.contains(RegExp(r'^(?=.*?[A-Z])'))) return "package.validator.password-invalid-maj".tr();
    if ((config?.atLeast1Lowercase ?? true) && !password.contains(RegExp(r'^(?=.*?[a-z])'))) return "package.validator.password-invalid-min".tr();
    if ((config?.atLeast1Number ?? true) && !password.contains(RegExp(r'^(?=.*?[0-9])'))) return "package.validator.password-invalid-number".tr();
    if ((config?.atLeast1SpecialChar ?? true) && !password.contains(RegExp(r'[^A-Za-z0-9\s]'))) {
      return "package.validator.password-invalid-special-char".tr();
    }
    return null;
  }

  /// Retourne les sécurité manquante pour le mot de passe
  static PasswordStrengthQuality passwordStrength(String? password, [PasswordSecurityConfig? config]) {
    bool isValidLength = (password?.length ?? 0) >= 6;
    bool hasLowercase = password?.contains(RegExp(r'^(?=.*?[a-z])')) ?? false;
    bool hasUppercase = password?.contains(RegExp(r'^(?=.*?[A-Z])')) ?? false;
    bool hasDigits = password?.contains(RegExp(r'^(?=.*?[0-9])')) ?? false;
    bool hasSpecialCharacters = password?.contains(RegExp(r'[^A-Za-z0-9\s]')) ?? false;

    return PasswordStrengthQuality(
      isValidLength: isValidLength,
      hasLowercase: hasLowercase,
      hasUppercase: hasUppercase,
      hasDigits: hasDigits,
      hasSpecialCharacters: hasSpecialCharacters,
    );
  }

  /// Vérifie que les 2 mots de passes sont identiques.
  static String? validSamePassword(String? password, String? secondPassword) {
    if (password == null || password.isEmpty) return "package.validator.must-have-value".tr();
    if (secondPassword == null || secondPassword.isEmpty) return "package.validator.must-have-value".tr();
    if (password != secondPassword) return "package.validator.password-not-match".tr();
    return null;
  }
}

/// {@category Utils}
///
/// FormField Validator sur les champs de formulaire.
abstract class FieldValidator {
  /// Vérifie que le champ n'est pas null.
  static String? fieldNotNull<T>(T? value) {
    if (value == null) return "package.validator.must-have-value".tr();
    return null;
  }

  /// Vérifie que le champ n'est pas vide.
  static String? fieldNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return "package.validator.must-have-value".tr();
    return null;
  }

  /// Vérifie que le champ est un nombre (peut contenir '.' ou ',' pour les décimaux).
  static String? validNumericValue(String? value, [bool allowSpace = true]) {
    if (value == null || value.isEmpty) return "package.validator.must-have-value".tr();
    final parsedValue = value.trim();
    if (allowSpace) {
      if (!RegExp(r"^[0-9 ,.]+$").hasMatch(parsedValue)) return "package.validator.number-invalid".tr();
    } else {
      if (!RegExp(r"^[0-9,.]+$").hasMatch(parsedValue)) return "package.validator.number-invalid".tr();
    }
    return null;
  }

  /// Vérifie que le champ est un nombre compris dans une range (peut contenir '.' ou ',' pour les décimaux).
  static String? validNumericValueWithRange(String? value, double min, double max, [bool allowSpace = true]) {
    if (value == null || value.isEmpty) return "package.validator.must-have-value".tr();
    final parsedValue = value.trim();
    if (allowSpace) {
      if (!RegExp(r"^[0-9 ,.]+$").hasMatch(parsedValue)) return "package.validator.number-invalid".tr();
    } else {
      if (!RegExp(r"^[0-9,.]+$").hasMatch(parsedValue)) return "package.validator.number-invalid".tr();
    }
    final doubleValue = double.parse(parsedValue.replaceAll(",", "."));
    if (doubleValue < min || doubleValue > max) return "package.validator.number-out-of-range".tr(namedArgs: {"min": min.toString(), "max": max.toString()});
    return null;
  }

  /// Vérifie que le champ est un nombre supérieur à [min] (peut contenir '.' ou ',' pour les décimaux).
  static String? validNumericValueWithMin(String? value, double min, [bool allowSpace = true]) {
    if (value == null || value.isEmpty) return "package.validator.must-have-value".tr();
    final parsedValue = value.trim();
    if (allowSpace) {
      if (!RegExp(r"^[0-9 ,.]+$").hasMatch(parsedValue)) return "package.validator.number-invalid".tr();
    } else {
      if (!RegExp(r"^[0-9,.]+$").hasMatch(parsedValue)) return "package.validator.number-invalid".tr();
    }
    final doubleValue = double.parse(parsedValue.replaceAll(",", "."));
    if (doubleValue < min) return "package.validator.number-out-of-min".tr(namedArgs: {"min": min.toString()});
    return null;
  }

  /// Vérifie que le champ est un nombre inférieur à [max] (peut contenir '.' ou ',' pour les décimaux).
  static String? validNumericValueWithMax(String? value, double max, [bool allowSpace = true]) {
    if (value == null || value.isEmpty) return "package.validator.must-have-value".tr();
    final parsedValue = value.trim();
    if (allowSpace) {
      if (!RegExp(r"^[0-9 ,.]+$").hasMatch(parsedValue)) return "package.validator.number-invalid".tr();
    } else {
      if (!RegExp(r"^[0-9,.]+$").hasMatch(parsedValue)) return "package.validator.number-invalid".tr();
    }
    final doubleValue = double.parse(parsedValue.replaceAll(",", "."));
    if (doubleValue > max) return "package.validator.number-out-of-max".tr(namedArgs: {"max": max.toString()});
    return null;
  }

  /// Vérifie que le champ est un mot / une phrase  (pouvant contenir '.' ou ',').
  static String? validAlphaValue(String? value, [bool allowSpace = true]) {
    if (value == null || value.isEmpty) return "package.validator.must-have-value".tr();
    final parsedValue = value.trim();
    if (allowSpace) {
      if (!RegExp(r"^[a-zA-Z ,.]+$").hasMatch(parsedValue)) return "package.validator.alpha-invalid".tr();
    } else {
      if (!RegExp(r"^[a-zA-Z,.]+$").hasMatch(parsedValue)) return "package.validator.alpha-invalid".tr();
    }
    return null;
  }

  /// Vérifie que le champ est une date valide.
  static String? validDate(DateTime? date) {
    if (date == null) return "package.validator.date-invalud".tr();
    return null;
  }

  /// Vérifie que le champ est une date valide et qu'elle est comprise dans la range [minDate] et [maxDate].
  static String? validDateRange(DateTime? date, DateTime? minDate, DateTime? maxDate) {
    if (date == null) return "package.validator.must-have-valid-date".tr();
    if (minDate != null && date.isBefore(minDate)) return "package.validator.date-out-of-min".tr(namedArgs: {"min": minDate.toIso8601String()});
    if (maxDate != null && date.isAfter(maxDate)) return "package.validator.date-out-of-max".tr(namedArgs: {"max": maxDate.toIso8601String()});
    return null;
  }

  /// Vérifie que le champ est une date valide et qu'elle est supérieure à [minDate].
  static String? validDateMin(DateTime? date, DateTime? minDate) {
    if (date == null) return "package.validator.must-have-valid-date".tr();
    if (minDate != null && date.isBefore(minDate)) return "package.validator.date-out-of-min".tr(namedArgs: {"min": minDate.toIso8601String()});
    return null;
  }

  /// Vérifie que le champ est une date valide et qu'elle est inférieure à [maxDate].
  static String? validDateMax(DateTime? date, DateTime? maxDate) {
    if (date == null) return "package.validator.must-have-valid-date".tr();
    if (maxDate != null && date.isAfter(maxDate)) return "package.validator.date-out-of-max".tr(namedArgs: {"max": maxDate.toIso8601String()});
    return null;
  }

  /// Permet de vérifier qu'il y au moins un élément dans la liste.
  static String? validListNotEmpty<T>(List<T>? list) {
    if (list == null || list.isEmpty) return "package.validator.must-have-value".tr();
    return null;
  }

  /// Permet de vérifier que les [PlatformFile] dans la list sont bien des types autorisés.
  static String? validFileTypes(List<PlatformFile>? files, List<String> allowedTypes) {
    if (files == null || files.isEmpty) return "package.validator.must-have-value".tr();
    for (final file in files) {
      if (!allowedTypes.contains(file.extension)) return "package.validator.file-type-not-allowed".tr(namedArgs: {"type": file.extension ?? ""});
    }
    return null;
  }
}
