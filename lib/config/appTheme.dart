import 'package:flutter/material.dart';

class AppColors {
  // Warna utama aplikasi
  static const Color primary = Color(0xFF3478E5);
  static const Color primaryDark = Color(0xFF245DB5);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color sea = Color(0xFFDCE9FF);
  static const Color seaDeep = Color(0xFF3478E5);

  // Warna latar dan permukaan
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color fieldBg = Color(0xFFFAFBFD);

  // Warna teks
  static const Color navy = Color(0xFF202938);
  static const Color grey = Color(0xFF667085);
  static const Color muted = Color(0xFF98A2B3);

  // Warna garis dan komponen
  static const Color fieldBorder = Color(0xFFE2E8F0);
  static const Color tabBg = Color(0xFFF0F4FA);

  // Warna status
  static const Color green = Color(0xFF21866D);
  static const Color error = Color(0xFFD92D20);
}

class AppTheme {
  static OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static ThemeData get light {
    const colors = AppColors;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.green,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
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
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
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
          disabledBackgroundColor: const Color(0xFFB8CEF4),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: Color(0xFFD5E4FF)),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.fieldBorder),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.fieldBorder,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lightBlue,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
