import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/items/theme/item_theme.dart';

/// {@category Widget}
/// {@category Item}
///
/// Permet d'afficher un item avec un titre et un child.
///
/// Exemple:
///
/// ![address_row](../../images/item/simple_string_item.png)
///
/// ```dart
/// WidgetRow(
///   title: "Titre",
///   content: Text("Contenu"),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [ItemThemeData] : "item".
class WidgetRow extends ConsumerStatefulWidget {
  final String title;
  final Widget content;

  /// Theme
  final ItemThemeData? theme;
  final String? themeName;

  const WidgetRow({
    super.key,
    required this.title,
    required this.content,
    this.theme,
    this.themeName,
  });

  @override
  ConsumerState<WidgetRow> createState() => _WidgetRowState();
}

class _WidgetRowState extends ConsumerState<WidgetRow> {
  late final themeData = loadThemeData(
      widget.theme, widget.themeName ?? "item", () => kDefaultItemTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: themeData.titleStyle),
        widget.content,
      ],
    );
  }
}
