/// {@category Config}
///
/// Contient les informations des objets user de votre application
class UserConfig<T extends Object?> {
  /// Permet de convertir un Json en votre objet user (ex: UserModel.fromJson) tout en ajoutant l'ID.
  final T Function(Map<String, dynamic>? json, String? userType) fromJson;

  /// Collection Firebase où son stocké les users. Par défaut: "users".
  final String userCollectionName;

  const UserConfig({
    required this.fromJson,
    this.userCollectionName = "users",
  });
}
