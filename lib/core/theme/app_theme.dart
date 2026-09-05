import 'package:flutter/material.dart';

/// Brand palette — matches the SRS / UI-concept documents.
class AppColors {
  static const brand = Color(0xFF0A6B57);
  static const brandDeep = Color(0xFF033D33);
  static const brandLight = Color(0xFF10866E);
  static const gold = Color(0xFFC7A25A);
  static const ink = Color(0xFF0F2A24);
  static const muted = Color(0xFF6B7570);
  static const danger = Color(0xFFC0473C);
  static const bg = Color(0xFFF4F2EC);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
        secondary: AppColors.gold,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brandDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 6,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: AppColors.ink.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      fontFamily: 'Roboto',
    );
  }
}
