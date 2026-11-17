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

  // Semantic accents for data cards (stats, chart, status). The brand
  // green/gold stays the identity of the app; these only distinguish
  // *kinds of information* so four stat cards aren't four identical
  // green rectangles.
  static const brandSoft = Color(0xFFE3F0EC);
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFE6F6EC);
  static const indigo = Color(0xFF5B5BD6);
  static const indigoSoft = Color(0xFFECECFB);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFDF1DC);
  static const border = Color(0xFFE6E2D6);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFEDF3F1),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
        secondary: AppColors.gold,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xF2F6FAF9),
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.0,
          ),
        ),
        titleTextStyle: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          shadowColor: AppColors.brand.withValues(alpha: 0.35),
          minimumSize: const Size(48, 52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: AppColors.muted),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xCCFFFFFF), // Frosted glass acrylic translucency
        shadowColor: AppColors.brandDeep.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.92), width: 1.3),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF5FFFFFF),
        elevation: 16,
        shadowColor: AppColors.ink.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.95), width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xF7FFFFFF),
        elevation: 16,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandDeep.withValues(alpha: 0.94),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1.0),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.75),
        selectedColor: AppColors.brandSoft,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.9), width: 1.1),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        pressElevation: 1,
      ),
      fontFamily: 'Roboto',
    );
  }
}
