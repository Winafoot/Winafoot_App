/// Connexion par identifiant : un identifiant d'équipe (sans « @ ») devient l'adresse technique de son
/// compte Firebase, `<identifiant>@<domaine>`. Une adresse e-mail est laissée telle quelle.
abstract class LoginIdentifier {
  static String toEmail(String input, String domain) {
    final String value = input.trim();
    if (value.contains('@')) return value;
    return '${value.toLowerCase()}@$domain';
  }
}
