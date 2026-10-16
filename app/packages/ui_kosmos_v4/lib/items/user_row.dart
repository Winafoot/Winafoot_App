import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/items/theme/item_theme.dart';

/// {@category Widget}
/// {@category Item}
///
/// Permet d'afficher un item contenant les informations d'un utilisateur.
/// Vous pouvez ajouter un suffix custom pour gérer des événements
/// supplémentaires.
///
/// Exemple:
///
/// ![address_row](../../images/item/user_row.png)
///
/// ```dart
/// UserRow(
///   fullName: "John Doe",
///   profilPicture: "https://picsum.photos/200",
///   subtitle: "Texte d'exemple",
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [ItemThemeData] : "item".
class UserRow extends ConsumerStatefulWidget {
  final String fullName;
  final String? profilPicture;
  final String? subtitle;

  final Widget? suffix;

  final bool showProfilPictureIfNull;

  /// Theme
  final ItemThemeData? theme;
  final String? themeName;

  const UserRow({
    super.key,
    required this.fullName,
    this.profilPicture,
    this.subtitle,
    this.suffix,
    this.showProfilPictureIfNull = true,
    this.theme,
    this.themeName,
  });

  @override
  ConsumerState<UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<UserRow> {
  late final themeData = loadThemeData(
      widget.theme, widget.themeName ?? "item", () => kDefaultItemTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.profilPicture != null || widget.showProfilPictureIfNull)
          Container(
            width: formatWidth(46),
            height: formatWidth(46),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(23)),
            child: widget.profilPicture != null
                ? CachedNetworkImage(
                    imageUrl: widget.profilPicture!, fit: BoxFit.cover)
                : Image.asset("assets/images/blank_user.jpeg",
                    fit: BoxFit.cover),
          ),
        sw(13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.fullName, style: themeData.headTitleStyle),
              if (widget.subtitle != null)
                Text(widget.subtitle!, style: themeData.titleStyle),
            ],
          ),
        ),
        sw(12),
        if (widget.suffix != null) widget.suffix!
      ],
    );
  }
}
