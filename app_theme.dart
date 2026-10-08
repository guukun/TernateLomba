import 'package:flutter/material.dart';

/// Palet warna mengikuti desain Figma TernateLomba (biru + laut Ternate).
class AppColors {
  static const primary = Color(0xFF1E6FE8); // tombol & aksen
  static const primaryDark = Color(0xFF0E4AB8); // gradasi logo
  static const navy = Color(0xFF0F1F45); // teks judul
  static const grey = Color(0xFF64748B); // teks sekunder
  static const lightBlue = Color(0xFF86D6FB); // aksen logo
  static const sea = Color(0xFF8ED3F5);
  static const seaDeep = Color(0xFF1E8FD8);
  static const fieldBg = Color(0xFFF8FAFC);
  static const fieldBorder = Color(0xFFE2E8F0);
  static const tabBg = Color(0xFFF1F5F9);
  static const green = Color(0xFF21946D);
  static const error = Color(0xFFD93025);
}

class AppTheme {
  static OutlineInputBorder _border(Color c, [double w = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.green,
        ),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fieldBg,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          border: _border(AppColors.fieldBorder),
          enabledBorder: _border(AppColors.fieldBorder),
          focusedBorder: _border(AppColors.primary, 1.6),
          errorBorder: _border(AppColors.error),
          focusedErrorBorder: _border(AppColors.error, 1.6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
}
