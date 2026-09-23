import 'package:flutter/material.dart';

import 'models.dart';

const cream = Color(0xFFFFF8EC);
const navy = Color(0xFF174F7F);
const ink = Color(0xFF223D50);
Color profileColor(ChildProfile? profile) {
  final choice = profile?.palette ?? PaletteChoice.automatic;
  return switch (choice) {
    PaletteChoice.ocean => const Color(0xFF2170B5),
    PaletteChoice.berry => const Color(0xFF794D91),
    PaletteChoice.forest => const Color(0xFF27764A),
    PaletteChoice.automatic =>
      profile?.gender == ChildGender.girl
          ? const Color(0xFF794D91)
          : const Color(0xFF2170B5),
  };
}

ThemeData adventureTheme(ChildProfile? profile) {
  final primary = profileColor(profile);
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    fontFamilyFallback: const ['Cairo'],
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      surface: cream,
      onSurface: ink,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 38,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 22, color: ink),
      bodyMedium: TextStyle(fontSize: 22, color: ink),
      labelLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 64),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 64),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        side: BorderSide(color: primary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
    ),
  );
}
