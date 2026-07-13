import 'package:flutter/material.dart';

/// One place for color and typography. Keep widgets free of raw hex values.
class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E5BFF),
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E5BFF),
      brightness: Brightness.dark,
    );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }
}
