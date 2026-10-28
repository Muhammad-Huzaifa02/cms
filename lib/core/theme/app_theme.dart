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
      scaffoldBackgroundColor: const Color(0xFFF7F8F6),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
        secondary: AppColors.gold,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F8F6),
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 0,
          minimumSize: const Size(48, 52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: AppColors.muted),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
      ),
      // Dialogs, bottom sheets, snackbars and chips are themed globally so
      // every one of them floats the same way (rounded, elevated, clear of
      // the screen edge) without each call site restyling itself.
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 12,
        shadowColor: AppColors.ink.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 16,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandDeep,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.brandSoft,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        pressElevation: 2,
      ),
      fontFamily: 'Roboto',
    );
  }
}
