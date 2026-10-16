import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/items/theme/item_theme.dart';

/// {@category Widget}
/// {@category Item}
///
/// Permet d'afficher un item avec un titre et un contenu.
///
/// Exemple:
///
/// ![address_row](../../images/item/simple_string_item.png)
///
/// ```dart
/// SimpleStringRow(
///   title: "Titre",
///   content: "Contenu",
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [ItemThemeData] : "item".
class SimpleStringRow extends ConsumerStatefulWidget {
  final String title;
  final String content;

  /// Theme
  final ItemThemeData? theme;
  final String? themeName;

  const SimpleStringRow({
    super.key,
    required this.title,
    required this.content,
    this.theme,
    this.themeName,
  });

  @override
  ConsumerState<SimpleStringRow> createState() => _SimpleStringRowState();
}

class _SimpleStringRowState extends ConsumerState<SimpleStringRow> {
  late final themeData = loadThemeData(
      widget.theme, widget.themeName ?? "item", () => kDefaultItemTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: themeData.titleStyle),
        Text(widget.content, style: themeData.contentStyle),
      ],
    );
  }
}
