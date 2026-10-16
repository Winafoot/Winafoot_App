import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/button/button.dart';
import 'package:ui_kosmos_v4/button/theme/button_theme.dart';
import 'package:ui_kosmos_v4/picker/theme/picker_theme.dart';

/// {@category Widget}
/// {@category PopUp}
/// {@category Date}
///
/// Picker de date, permet de récupérer une date via un Objet [DateTime].
/// Vous pouvez fournir une date sélectionné par défaut ([initialSelectedDate]),
/// ou une date [initialDate] qui permmet de fixer le premier mois affiché.
///
/// La fonction [onChanged] permet de réagir à chaque changement de date,
/// complète ou incomplète.
///
/// Vous pouvez également fournir une plage de date [minDate] et [maxDate] qui permet de limiter
/// les dates sélectionnables. Ainsi qu'une liste [lockedDate] de date qui ne seront pas sélectionnable.
///
/// Exemple:
/// ![range_picker](../../images/picker/single_picker.png)
///
/// ```dart
/// Button(
///   text: "Single Picker",
///   onTap: () {
///     PopUp.showGeneralPopUp(
///       context: context,
///       builder: (_, __) {
///         return const SingleDatePicker();
///       },
///     );
///   },
/// ),
/// ```
///
/// Vous pouvez également fournir un thème [theme] ou [themeName] pour personnaliser le picker.
/// Par défaut, le thème utilise un [KosmosDatePickerThemeData] via le tag "date_picker".
///
class SingleDatePicker extends ConsumerStatefulWidget {
  final DateTime? initialSelectedDate;
  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final void Function(DateTime?)? onChanged;
  final bool enableSelectTime;
  final List<DateTime>? lockedDate;

  /// Theme
  final String? themeName;
  final KosmosDatePickerThemeData? theme;
  final double? width;

  const SingleDatePicker({
    Key? key,
    this.initialDate,
    this.initialSelectedDate,
    this.minDate,
    this.maxDate,
    this.enableSelectTime = true,
    this.lockedDate,
    this.onChanged,

    /// Theme
    this.theme,
    this.themeName,
    this.width,
  }) : super(key: key);

  @override
  ConsumerState<SingleDatePicker> createState() => _SingleDatePickerState();
}

class _SingleDatePickerState extends ConsumerState<SingleDatePicker> {
  late final List<DateTime>? _lockedDate = widget.lockedDate;
  late DateTime _currentDate = widget.initialDate ?? DateTime.now();
  late DateTime? _selectedDate = widget.initialSelectedDate;

  @override
  Widget build(BuildContext context) {
    final KosmosDatePickerThemeData themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "single_date_picker",
      () => kDefaultDatePickerTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Container(
      width: widget.width ?? (MediaQuery.of(context).size.width * 8),
      constraints: themeData.boxConstraints,
      padding: themeData.boxPadding,
      decoration: themeData.boxDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _createHeaderDatePicker(context, themeData),
          sh(18),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["mo", "tu", "we", "th", "fr", "sa", "su"]
                .map((e) => SizedBox(
                      width: formatWidth(35),
                      child: Center(
                          child: Text("date.day.$e".tr(),
                              style: themeData.dayTextStyle)),
                    ))
                .toList(),
          ),
          sh(12),
          _buildDayBox(context, themeData),
          sh(4),
          _buildEventButton(context),
          sh(4),
        ],
      ),
    );
  }

  _buildButton(Widget child, VoidCallback callback) {
    return InkWell(
      onTap: callback,
      child: Container(
        padding: EdgeInsets.all(formatWidth(4)),
        decoration: BoxDecoration(
          border: Border.all(width: .5, color: Colors.black.withOpacity(.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }

  _getMonthString(int month) {
    if (month == 1) {
      return "date.month.january".tr();
    } else if (month == 2) {
      return "date.month.february".tr();
    } else if (month == 3) {
      return "date.month.march".tr();
    } else if (month == 4) {
      return "date.month.april".tr();
    } else if (month == 5) {
      return "date.month.may".tr();
    } else if (month == 6) {
      return "date.month.june".tr();
    } else if (month == 7) {
      return "date.month.july".tr();
    } else if (month == 8) {
      return "date.month.august".tr();
    } else if (month == 9) {
      return "date.month.september".tr();
    } else if (month == 10) {
      return "date.month.october".tr();
    } else if (month == 11) {
      return "date.month.november".tr();
    } else if (month == 12) {
      return "date.month.december".tr();
    }
  }

  Widget _createHeaderDatePicker(
          BuildContext context, KosmosDatePickerThemeData themeData) =>
      Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildButton(
            Icon(Icons.keyboard_double_arrow_left_rounded,
                size: formatWidth(22),
                color: themeData.dateNavigationButtonColor),
            () => setState(() => _currentDate = DateTime(
                _currentDate.year - 1, _currentDate.month, _currentDate.day)),
          ),
          sw(4),
          _buildButton(
            Icon(Icons.keyboard_arrow_left_rounded,
                size: formatWidth(22),
                color: themeData.dateNavigationButtonColor),
            () => setState(() => _currentDate = DateTime(
                _currentDate.year, _currentDate.month - 1, _currentDate.day)),
          ),
          sw(4),
          Expanded(
              child: Text(
                  "${_getMonthString(_currentDate.month)}\n${_currentDate.year}",
                  style: themeData.dateTextStyle,
                  textAlign: TextAlign.center)),
          _buildButton(
            Icon(Icons.keyboard_arrow_right_rounded,
                size: formatWidth(22),
                color: themeData.dateNavigationButtonColor),
            () => setState(() => _currentDate = DateTime(
                _currentDate.year, _currentDate.month + 1, _currentDate.day)),
          ),
          sw(4),
          _buildButton(
            Icon(Icons.keyboard_double_arrow_right_rounded,
                size: formatWidth(22),
                color: themeData.dateNavigationButtonColor),
            () => setState(() => _currentDate = DateTime(
                _currentDate.year + 1, _currentDate.month, _currentDate.day)),
          ),
        ],
      );

  Widget _buildDayBox(
      BuildContext context, KosmosDatePickerThemeData themeData) {
    var firstDay = DateTime(_currentDate.year, _currentDate.month, 1);
    if (firstDay.weekday > 1) {
      firstDay = DateTime(
          _currentDate.year, _currentDate.month, -(firstDay.weekday - 2));
    }

    var lastDay = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    if (lastDay.weekday != 1) {
      lastDay = DateTime(_currentDate.year, _currentDate.month + 1,
          1 + (7 - (lastDay.weekday - 1)));
    }

    List<Widget> children = [];
    List<Widget> tmpDay = [];

    for (DateTime i = firstDay;
        i.isBefore(lastDay);
        i = DateTime(i.year, i.month, i.day + 1)) {
      tmpDay.add(
        InkWell(
          onTap: () {
            if (_lockedDate?.contains(i) ?? false) return;
            if (widget.maxDate != null && widget.maxDate!.isBefore(i)) return;
            if (widget.minDate != null && widget.minDate!.isAfter(i)) return;
            setState(() {
              if (i.month == _currentDate.month) {
                _selectedDate = i;
              } else {
                if (i.month < _currentDate.month) {
                  _currentDate = DateTime(_currentDate.year,
                      _currentDate.month - 1, _currentDate.day);
                  _selectedDate = i;
                } else {
                  _currentDate = DateTime(_currentDate.year,
                      _currentDate.month + 1, _currentDate.day);
                  _selectedDate = i;
                }
              }
            });
            if (widget.onChanged != null) widget.onChanged!(selectedDate);
          },
          child: Container(
            width: formatWidth(35),
            height: formatWidth(35),
            decoration: selectedDate == i
                ? themeData.activeDateBackgroundDecoration
                : themeData.inactiveDateBackgroundDecoration,
            child: Center(
              child: Text(
                i.day.toString(),
                style: (_lockedDate?.contains(i) ?? false) ||
                        (widget.maxDate != null &&
                            widget.maxDate!.isBefore(i)) ||
                        (widget.minDate != null && widget.minDate!.isAfter(i))
                    ? themeData.lockedDateTextStyle
                    : i.month != _currentDate.month
                        ? themeData.otherMonthDateTextStyle
                        : selectedDate == i
                            ? themeData.activeDateTextStyle
                            : themeData.defaultDateTextStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
      if (i.weekday == 7) {
        children.add(Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [...tmpDay],
            ),
            sh(3),
          ],
        ));
        tmpDay.clear();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildEventButton(BuildContext context) {
    var primaryTheme = loadThemeData<KosmosButtonThemeData>(
        null, "button_primary", () => const KosmosButtonThemeData());
    primaryTheme = primaryTheme.copyWith(
      buttonTextStyle: primaryTheme.buttonTextStyle
              ?.copyWith(fontSize: sp(13), fontWeight: FontWeight.w500) ??
          TextStyle(
            color: DefaultColor.darkBlue,
            fontSize: sp(13),
            fontWeight: FontWeight.w500,
          ),
    );

    var secondaryTheme = loadThemeData<KosmosButtonThemeData>(
        null, "button_secondary", () => const KosmosButtonThemeData());
    secondaryTheme = secondaryTheme.copyWith(
      buttonTextStyle: secondaryTheme.buttonTextStyle
              ?.copyWith(fontSize: sp(13), fontWeight: FontWeight.w500) ??
          TextStyle(
            color: DefaultColor.darkBlue,
            fontSize: sp(13),
            fontWeight: FontWeight.w500,
          ),
    );

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Button(
            onTap: () => Navigator.of(context).pop(null),
            buttonType: ButtonType.secondary,
            padding: EdgeInsets.zero,
            height: formatHeight(35),
            theme: secondaryTheme,
            text: "date.event.cancel".tr(),
          ),
        ),
        sw(22),
        Expanded(
          child: Button(
            onTap: () => Navigator.of(context).pop(selectedDate),
            buttonType: ButtonType.primary,
            padding: EdgeInsets.zero,
            theme: primaryTheme,
            height: formatHeight(35),
            text: "date.event.validate".tr(),
          ),
        ),
      ],
    );
  }

  /// Recupère la date sélectionnée
  DateTime? get selectedDate => _selectedDate;
}
