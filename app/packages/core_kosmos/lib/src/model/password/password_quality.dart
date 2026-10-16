/// {@category Model}
///
/// Objet permetttant de stocker la qualité d'un mot de passe.
///
class PasswordStrengthQuality {
  final bool isValidLength;
  final bool hasLowercase;
  final bool hasUppercase;
  final bool hasDigits;
  final bool hasSpecialCharacters;

  PasswordStrengthQuality({
    required this.isValidLength,
    required this.hasLowercase,
    required this.hasUppercase,
    required this.hasDigits,
    required this.hasSpecialCharacters,
  });
}
