import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/items/theme/item_theme.dart';

/// {@category Widget}
/// {@category Item}
///
/// Permet d'afficher une date, avec une date de fin en option.
///
/// Exemple:
///
/// ![address_row](../../images/item/date_item.png)
///
/// ```dart
/// DateRow(
///   date: DateTime.now(),
///   endDate: DateTime.now().add(Duration(days: 2)),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [ItemThemeData] : "item".
class DateRow extends ConsumerStatefulWidget {
  final String? title;
  final DateTime date;
  final DateTime? endDate;

  final bool showHour;

  /// Theme
  final ItemThemeData? theme;
  final String? themeName;

  const DateRow({
    super.key,
    this.title,
    required this.date,
    this.endDate,
    this.theme,
    this.themeName,
    this.showHour = true,
  });

  @override
  ConsumerState<DateRow> createState() => _DateRowState();
}

class _DateRowState extends ConsumerState<DateRow> {
  late final themeData = loadThemeData(
      widget.theme, widget.themeName ?? "item", () => kDefaultItemTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title ?? "item.date.title".tr(),
            style: themeData.titleStyle),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: "${"item.date.from".tr()} ",
                  style: themeData.titleStyle),
              TextSpan(
                  text:
                      "${widget.date.day.autoPadLeft(2)}.${widget.date.month.autoPadLeft(2)}.${widget.date.year} ",
                  style: themeData.contentStyle),
              if (widget.showHour)
                TextSpan(
                    text:
                        "${widget.date.hour.autoPadLeft(2)}:${widget.date.minute.autoPadLeft(2)}h ",
                    style: themeData.contentStyle),
              if (widget.endDate != null) ...[
                TextSpan(
                    text:
                        "${widget.endDate!.day.autoPadLeft(2)}.${widget.endDate!.month.autoPadLeft(2)}.${widget.endDate!.year} ",
                    style: themeData.contentStyle),
                if (widget.showHour)
                  TextSpan(
                      text:
                          "${widget.endDate!.hour.autoPadLeft(2)}:${widget.endDate!.minute.autoPadLeft(2)}h ",
                      style: themeData.contentStyle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
