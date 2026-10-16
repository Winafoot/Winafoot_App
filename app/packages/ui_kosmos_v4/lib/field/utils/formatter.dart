import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:ui_kosmos_v4/field/field/date/date_from_string.dart';

///{@category Utils}
///{@subCategory Formatters}
///
/// Permet de formatter un champ de texte pour qu'il ne contienne que des chiffres avec les espaces entre les milliers
/// et les virgules entre les décimales
///
class NumericTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    try {
      if (newValue.text.isEmpty) {
        return newValue.copyWith(text: '');
      } else if (newValue.text.compareTo(oldValue.text) != 0) {
        final int selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;
        final f = NumberFormat("###,###.####");
        final tmp = newValue.text.replaceAll(',', ".");
        if (tmp.endsWith(".")) {
          return TextEditingValue(
            text: tmp,
            selection: TextSelection.collapsed(offset: tmp.length - selectionIndexFromTheRight),
          );
        }
        final number = double.parse(tmp);
        final newString = f.format(number);
        return TextEditingValue(
          text: newString,
          selection: TextSelection.collapsed(offset: newString.length - selectionIndexFromTheRight),
        );
      } else {
        return newValue;
      }
    } catch (_) {
      printExcept(_);
      return newValue;
    }
  }
}

///{@category Utils}
///{@subCategory Formatters}
///
/// Permet de formatter un champ de texte pour qu'il ne contienne qu'une date formatter.
/// En fonction du [DateType], on peut formatter une date, une heure ou une date et une heure.
///
/// - [DateType.date] : Affichage de la date (ex: DD/MM/YYYY)
/// - [DateType.time] : Affichage de l'heure (ex: HH:MM)
/// - [DateType.full] : Affichage de la date et de l'heure (ex: DD/MM/YYYY HH:MM)
///
class DateTextFormatter extends TextInputFormatter {
  final int _maxChars;

  final String _dateSeparator;
  final String _timeSeparator;
  final DateType _dateType;

  DateTextFormatter(
    this._dateType, [
    this._dateSeparator = "/",
    this._timeSeparator = ":",
  ]) : _maxChars = _dateType == DateType.full
            ? 12
            : _dateType == DateType.date
                ? 8
                : 4;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = _format(newValue.text);
    return newValue.copyWith(text: text, selection: updateCursorPosition(text));
  }

  String _format(String value) {
    value = value.replaceAll(_dateSeparator, '').replaceAll(_timeSeparator, '').replaceAll(' ', '');

    return {
      DateType.date: _formatDate,
      DateType.time: _formatTime,
      DateType.full: _formatFull,
    }[_dateType]!(value);
  }

  String _formatDate(String value) {
    var newString = '';

    for (int i = 0; i < math.min(value.length, _maxChars); i++) {
      newString += value[i];
      if ((i == 1 || i == 3) && i != value.length - 1) {
        newString += _dateSeparator;
      }
    }

    return newString;
  }

  String _formatTime(String value) {
    var newString = '';

    for (int i = 0; i < math.min(value.length, _maxChars); i++) {
      newString += value[i];
      if ((i == 1) && i != value.length - 1) {
        newString += _timeSeparator;
      }
    }

    return newString;
  }

  String _formatFull(String value) {
    var newString = '';

    for (int i = 0; i < math.min(value.length, _maxChars); i++) {
      newString += value[i];
      if ((i == 1 || i == 3) && i != value.length - 1) {
        newString += _dateSeparator;
      } else if (i == 7 && i != value.length - 1) {
        newString += ' ';
      } else if (i == 9 && i != value.length - 1) {
        newString += _timeSeparator;
      }
    }

    return newString;
  }

  /// Replace de cursor à la fin du texte
  TextSelection updateCursorPosition(String text) => TextSelection.fromPosition(TextPosition(offset: text.length));
}
