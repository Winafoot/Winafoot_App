/// Champs du formulaire d'inscription (page 1), pour signaler ceux à corriger.
enum RegisterField { email, password, confirmation, firstname, cgu }

/// Validations locales de l'inscription. Le serveur (`registerCoach`) refait les
/// mêmes contrôles : ceux-ci évitent seulement un aller-retour réseau.
abstract class RegisterValidation {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Miroir de `PASSWORD_SPECIAL_CHARACTERS`
  /// (server/functions/src/callables/admin/_password_policy.ts).
  static const String passwordSpecialCharacters =
      r'''^$*.[]{}()?"!@#%&/\,><':;|_~`-''';

  static const int passwordMinLength = 6;
  static const int firstnameMaxLength = 80;

  static bool isValidEmail(String value) {
    final String email = value.trim();
    return email.length <= 254 && _email.hasMatch(email);
  }

  /// Exigences non remplies, en clair (liste vide : mot de passe conforme).
  static List<String> passwordViolations(String password) {
    final List<String> missing = <String>[];
    if (password.length < passwordMinLength) {
      missing.add('au moins $passwordMinLength caractères');
    }
    if (!RegExp('[a-z]').hasMatch(password)) missing.add('une minuscule');
    if (!RegExp('[A-Z]').hasMatch(password)) missing.add('une majuscule');
    if (!RegExp('[0-9]').hasMatch(password)) missing.add('un chiffre');
    if (!password.runes.any(
      (int c) => passwordSpecialCharacters.contains(String.fromCharCode(c)),
    )) {
      missing.add('un caractère spécial');
    }
    return missing;
  }

  /// Champs invalides du formulaire (ensemble vide : on peut envoyer).
  static Set<RegisterField> invalidFields({
    required String email,
    required String password,
    required String confirmation,
    required String firstname,
    required bool acceptedCgu,
  }) {
    final String name = firstname.trim();
    return <RegisterField>{
      if (!isValidEmail(email)) RegisterField.email,
      if (passwordViolations(password).isNotEmpty) RegisterField.password,
      if (confirmation != password) RegisterField.confirmation,
      if (name.isEmpty || name.length > firstnameMaxLength)
        RegisterField.firstname,
      if (!acceptedCgu) RegisterField.cgu,
    };
  }
}
