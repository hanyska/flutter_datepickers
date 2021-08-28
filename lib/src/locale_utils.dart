import 'dart:ui' as ui;
import 'package:flutter/material.dart';

String getLocale(BuildContext context, {Locale? selectedLocale}) {
  return selectedLocale?.languageCode ?? ui.window.locale.languageCode;
}
