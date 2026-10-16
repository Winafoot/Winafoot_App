import 'package:core_kosmos/core_kosmos.dart';

/// {@category Config}
/// {@category PackagesConfig}
/// 
/// Similaire à l'objet [AppTheme], mais pour les packages.
/// Celui-ci permet de stocker configurations de vos packages / dépendences et d'y avoir accès dans votre codes.
/// 
/// */!\ Attention*, vos packages iront récupérer leur configiration directement dans cet objet.
class DependenciesConfig {
  /// Liste des packages / dépendances de votre application.
  /// 
  /// - [String] Nom du pakcage, automatique défini dans l'objet [PackageConfig].
  /// - [PackageConfig] Objet de configuration du package.
  /// 
  final Map<String, PackageConfig> packages;

  const DependenciesConfig({
    required this.packages,
  });
}

/// {@category Config}
/// 
/// Objet de configuration d'un package / dépendance.
/// Tous les configurations d'un package doivent hériter de cette classe.
abstract class PackageConfig {
  /// Nom unique du package.
  final String packageName;

  const PackageConfig(this.packageName);

  @override
  toString() => "PackageConfig: $packageName";

  void print(String message) => printDebug("$packageName: $message");
}