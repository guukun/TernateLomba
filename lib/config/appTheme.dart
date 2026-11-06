
import 'package:flutter/material.dart';

class AppColors {
  // PRIMARY BRAND: DEEP NAVY BLUE
  static const Color primary = Color(0xFF123F78);
  static const Color primaryDark = Color(0xFF0D3262);
  static const Color primaryDeep = Color(0xFF092748);

  // CREAM PALETTE
  static const Color cream = Color(0xFFF5EFE3);
  static const Color creamDark = Color(0xFFE9DEC9);
  static const Color creamLight = Color(0xFFFBF8F1);

  // BLUE SUPPORTING COLORS
  static const Color lightBlue = Color(0xFFEAF0F7);
  static const Color sea = Color(0xFFDCE6F0);
  static const Color seaDeep = Color(0xFF315C89);

  // BACKGROUND AND SURFACE
  static const Color background = Color(0xFFFAF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color fieldBg = Color(0xFFFFFCF6);

  // TEXT COLORS
  static const Color navy = Color(0xFF1C2B3D);
  static const Color grey = Color(0xFF667085);
  static const Color muted = Color(0xFF98A2B3);

  // BORDERS AND COMPONENTS
  static const Color fieldBorder = Color(0xFFE8E1D5);
  static const Color tabBg = Color(0xFFF1EBDF);

  // STATUS COLORS
  static const Color green = Color(0xFF21866D);
  static const Color error = Color(0xFFD92D20);
}

class AppTheme {
  static OutlineInputBorder _border(
    Color color, [
    double width = 1,
  ]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.creamDark,
        onSecondary: AppColors.navy,
        surface: AppColors.surface,
        onSurface: AppColors.navy,
        error: AppColors.error,
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBg,
        hintStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 13,
        ),
        labelStyle: const TextStyle(
          color: AppColors.grey,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 17,
        ),
        border: _border(AppColors.fieldBorder),
        enabledBorder: _border(AppColors.fieldBorder),
        focusedBorder: _border(AppColors.primary, 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 1.5),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8C5D5),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.creamLight,
          side: const BorderSide(
            color: AppColors.creamDark,
          ),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: AppColors.fieldBorder,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.fieldBorder,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.creamDark,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
