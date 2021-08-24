import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_datepickers/month_picker_dialog.dart';
import 'package:flutter_datepickers/year_picker_dialog.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FlutterDatepickers {
  static Future<DateTime?> showMonthPicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    Locale? locale,
  }) async {
    final localizations = locale == null
        ? MaterialLocalizations.of(context)
        : await GlobalMaterialLocalizations.delegate.load(locale);

    return await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthPickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        locale: locale,
        localizations: localizations,
      ),
    );
  }

  static Future<DateTime?> showYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    Locale? locale,
  }) async {
    final localizations = locale == null
        ? MaterialLocalizations.of(context)
        : await GlobalMaterialLocalizations.delegate.load(locale);

    return await showDialog<DateTime>(
      context: context,
      builder: (context) => YearPickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        locale: locale,
        localizations: localizations,
      ),
    );
  }
}
