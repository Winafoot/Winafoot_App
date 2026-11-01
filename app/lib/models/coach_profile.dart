import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/formation.dart' show PlayerCount;

/// Catégorie d'âge de l'équipe (page « Finalisez votre profil coach »).
///
/// Les `name` sont persistés tels quels (`users/{uid}.category` et
/// `opponent.category` de chaque match) : n'en renommer ni n'en retirer aucun,
/// seuls les libellés sont libres. L'ordre de déclaration est celui des menus.
enum TeamCategory {
  u6('U6'),
  u7('U7'),
  u8('U8'),
  u9('U9'),
  u10('U10'),
  u11('U11'),
  u12('U12'),
  u13('U13'),
  u14('U14'),
  u15('U15'),
  u16('U16'),
  u17('U17'),
  u18('U18'),
  u19('U19'),
  seniors('Séniors'),
  veterans('Vétérans');

  const TeamCategory(this.label);

  final String label;
}

/// Division de l'équipe. Mêmes règles que [TeamCategory] pour les `name`
/// (`division` du profil et de l'adversaire).
enum TeamDivision {
  r1('Régional 1'),
  r2('Régional 2'),
  r3('Régional 3'),
  d1('Départemental 1'),
  d2('Départemental 2'),
  d3('Départemental 3'),
  d4('Départemental 4'),
  d5('Départemental 5'),
  d6('Départemental 6'),
  d7('Départemental 7'),
  d8('Départemental 8');

  const TeamDivision(this.label);

  final String label;
}

/// Couleur de maillot (libellé + visuel `shirt-*.png` dans assets/images +
/// couleur représentative pour les teintes, ex. écusson d'équipe). Chaque
/// visuel est peint à cette teinte (le blanc a un corps `#F7F7F7` cerné de gris,
/// sinon il disparaît sur fond blanc) : à recolorer ensemble, PNG et constante.
enum JerseyColorOption {
  rouge('Rouge', 'assets/images/shirt-red.png', AppColor.jerseyRed),
  bleu('Bleu', 'assets/images/shirt-blue.png', AppColor.jerseyBlue),
  bleuClair(
    'Bleu clair',
    'assets/images/shirt-l-blue.png',
    AppColor.jerseyLightBlue,
  ),
  vert('Vert', 'assets/images/shirt-green.png', AppColor.jerseyGreen),
  vertClair(
    'Vert clair',
    'assets/images/shirt-l-grren.png',
    AppColor.jerseyLightGreen,
  ),
  jaune('Jaune', 'assets/images/shirt-yellow.png', AppColor.jerseyYellow),
  orange('Orange', 'assets/images/shirt-orange.png', AppColor.jerseyOrange),
  rose('Rose', 'assets/images/shirt-pink.png', AppColor.jerseyPink),
  gris('Gris', 'assets/images/shirt-grey.png', AppColor.jerseyGrey),
  noir('Noir', 'assets/images/shirt-black.png', AppColor.jerseyBlack),
  blanc('Blanc', 'assets/images/shirt-white.png', AppColor.jerseyWhite);

  const JerseyColorOption(this.label, this.asset, this.color);

  final String label;

  /// Chemin du maillot `shirt-*.png` représentant la couleur.
  final String asset;

  /// Couleur représentative (teintes : écusson, pastilles…).
  final Color color;
}

/// Règle des pastilles « maillot + numéro » du sous-flux « Gérer mon équipe »
/// (attribution des numéros, placement) : le maillot peint dépend du rôle et de la
/// couleur portée, l'encre du numéro se déduit ensuite du maillot RÉELLEMENT
/// peint — jamais du maillot de l'équipe, qui peut être remplacé (rôle
/// remplaçant, joueur sélectionné…).
///
/// `match_live_screen` (banc de la popup de remplacement) et
/// `match_stats_board` appliquent la règle via `subJerseyAsset` — et donc, par
/// ricochet, `match_break_screen`, `match_finished_screen` et
/// `bilan_individuel_screen`, qui hébergent ce tableau.
///
/// `statistiques_matchs_screen` applique aussi la règle : son roster liste un
/// groupe « Remplaçants » bâti sur
/// `substituteIds`, en plus des groupes de postes bâtis sur `assignments`.
/// Son terrain, lui, reste bâti sur `assignments` — un remplaçant n'occupe
/// aucun emplacement, il n'y est donc pas représenté.
///
/// Ne s'applique pas aux vues qui n'ont pas de notion de rôle :
/// `formation_pitch` (marqueurs de schéma, aucun joueur) et
/// `tester_equipe_screen` (bac à sable, tout le monde est candidat).
///
/// Titulaires : la couleur portée par l'équipe. Remplaçants : le bleu de la
/// maquette (design 1:424), rabattu sur le bleu clair si l'équipe porte déjà
/// du bleu, sans quoi les deux rôles seraient indiscernables.
String jerseyAssetFor({required bool isSub, JerseyColorOption? own}) =>
    isSub
        ? subJerseyAsset(own?.asset)
        : (own?.asset ?? JerseyColorOption.bleuClair.asset);

/// Même règle, pour les vues de match qui ne connaissent que l'asset porté
/// (et pas l'option) : elles reçoivent un `jerseyAsset` unique et l'appliquaient
/// à tout le monde, remplaçants compris.
String subJerseyAsset(String? ownAsset) =>
    ownAsset == JerseyColorOption.bleu.asset
        ? JerseyColorOption.bleuClair.asset
        : JerseyColorOption.bleu.asset;

/// Encre lisible du numéro posé sur `asset` : celle des deux (blanc ou encre
/// sombre) qui contraste le plus avec le maillot. Les visuels `shirt-*.png`
/// sont peints aux teintes `JerseyColorOption.color` (verrouillé par
/// test/jersey_assets_palette_test.dart), on lit donc la luminance de la
/// teinte. Asset sans option (`shirt-empty*`) : blanc.
Color numberColorForJerseyAsset(String asset) {
  for (final JerseyColorOption o in JerseyColorOption.values) {
    if (o.asset != asset) continue;
    return _contrast(o.color, AppColor.textLight) >=
            _contrast(o.color, AppColor.primaryLabels)
        ? AppColor.textLight
        : AppColor.primaryLabels;
  }
  return AppColor.textLight;
}

/// Rapport de contraste WCAG entre deux couleurs opaques (1 à 21).
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance(), lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

/// Un maillot configuré par le coach (nom + couleur).
@immutable
class Jersey {
  const Jersey({required this.name, required this.color});

  final String name;
  final JerseyColorOption color;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'color': color.name,
  };

  /// Construit un maillot depuis un document Firestore (tolérant aux valeurs
  /// inconnues).
  factory Jersey.fromDoc(Map<String, dynamic> json) {
    return Jersey(
      name: (json['name'] as String?) ?? '',
      color:
          JerseyColorOption.values.asNameMap()[json['color']] ??
          JerseyColorOption.bleu,
    );
  }
}

/// Profil coach / équipe affiché dans l'entête de « Mon équipe ».
/// Renseigné à la complétion de profil, stocké sur le document `users/{uid}`.
@immutable
class CoachProfile {
  const CoachProfile({
    this.coachName,
    this.teamName,
    this.category,
    this.division,
    this.teamFormat,
  });

  final String? coachName;
  final String? teamName;
  final TeamCategory? category;
  final TeamDivision? division;

  /// Format du club (5 / 8 / 11 joueurs), fixé à la création du compte par le
  /// back-office. Lecture seule : l'app ne l'écrit jamais (les règles Firestore
  /// l'interdisent au coach). `null` sur les comptes existants.
  final PlayerCount? teamFormat;

  /// Prénom du coach (premier mot du nom complet), pour la puce « Coach … ».
  String? get coachFirstName {
    final String? n = coachName?.trim();
    if (n == null || n.isEmpty) return null;
    return n.split(RegExp(r'\s+')).first;
  }

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    return CoachProfile(
      coachName: json['coachName'] as String?,
      teamName: json['teamName'] as String?,
      category: TeamCategory.values.asNameMap()[json['category']],
      division: TeamDivision.values.asNameMap()[json['division']],
      teamFormat: PlayerCount.fromValue(json['teamFormat']),
    );
  }
}
