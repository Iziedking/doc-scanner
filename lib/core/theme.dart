// The EMIKINGS brand system: near-black surfaces, one gold accent, silver-grey
// text. Gold is the only accent on any screen; everything else stays neutral
// so the accent keeps its weight. No gradients, no glow.

import 'package:flutter/material.dart';

class BrandColors {
  // Canvas and surfaces.
  static const Color black = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF141418);
  static const Color surfaceRaised = Color(0xFF1C1C21);
  static const Color hairline = Color(0xFF2A2A31);

  // The one accent, sampled from the emblem's gold.
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldDeep = Color(0xFF8C6D24);
  static const Color onGold = Color(0xFF151003);

  // Text, from silver down to muted.
  static const Color textHigh = Color(0xFFF2F2F4);
  static const Color textMid = Color(0xFFA3A3AC);
  static const Color textLow = Color(0xFF6C6C76);

  static const Color danger = Color(0xFFE5484D);

  // Light theme counterparts: warm paper, ink, deep gold for contrast.
  static const Color paper = Color(0xFFF7F6F3);
  static const Color paperRaised = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1B1B1F);
  static const Color inkMid = Color(0xFF5B5B63);
  static const Color paperHairline = Color(0xFFE4E2DC);
}

class BrandAssets {
  static const String emblem = 'assets/brand/emblem.png';
}

class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      surface: BrandColors.black,
      surfaceContainer: BrandColors.surface,
      surfaceContainerHigh: BrandColors.surfaceRaised,
      primary: BrandColors.gold,
      onPrimary: BrandColors.onGold,
      secondary: BrandColors.textMid,
      onSecondary: BrandColors.black,
      onSurface: BrandColors.textHigh,
      onSurfaceVariant: BrandColors.textMid,
      outline: BrandColors.textLow,
      outlineVariant: BrandColors.hairline,
      error: BrandColors.danger,
      onError: Colors.white,
    );
    return _base(scheme, fill: BrandColors.surface);
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      surface: BrandColors.paper,
      surfaceContainer: BrandColors.paperRaised,
      surfaceContainerHigh: BrandColors.paperRaised,
      primary: BrandColors.goldDeep,
      onPrimary: Colors.white,
      secondary: BrandColors.inkMid,
      onSecondary: Colors.white,
      onSurface: BrandColors.ink,
      onSurfaceVariant: BrandColors.inkMid,
      outline: BrandColors.inkMid,
      outlineVariant: BrandColors.paperHairline,
      error: BrandColors.danger,
      onError: Colors.white,
    );
    return _base(scheme, fill: BrandColors.paperRaised);
  }

  static ThemeData _base(ColorScheme scheme, {required Color fill}) {
    final radius12 = BorderRadius.circular(12);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius12,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: radius12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
      ),
    );
  }
}
