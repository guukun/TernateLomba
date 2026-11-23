import 'package:flutter/material.dart';

import '../design_system/tl_palette.dart';
export '../design_system/tl_palette.dart';

class AppColors {
  static const Color primary = Color(0xFF161616);
  static const Color primaryDark = Color(0xFF0F0F0F);
  static const Color primaryDeep = Color(0xFF090909);
  static const Color cream = Color(0xFFF4F1EA);
  static const Color creamDark = Color(0xFFE5DED1);
  static const Color creamLight = Color(0xFFFCFBF8);
  static const Color lightBlue = Color(0xFFEDEBE7);
  static const Color sea = Color(0xFFF1EFEA);
  static const Color seaDeep = Color(0xFF545953);
  static const Color coral = Color(0xFF655C54);
  static const Color yellow = Color(0xFF665E4E);
  static const Color mint = Color(0xFF516052);
  static const Color lavender = Color(0xFF5E5A68);
  static const Color orange = Color(0xFF6E5D4C);
  static const Color background = Color(0xFFF7F5F0);
  static const Color surface = Colors.white;
  static const Color fieldBg = Color(0xFFF3F1EC);
  static const Color navy = Color(0xFF181818);
  static const Color grey = Color(0xFF66635E);
  static const Color muted = Color(0xFF98938B);
  static const Color fieldBorder = Color(0xFFE7E1D8);
  static const Color tabBg = Color(0xFFF0ECE5);
  static const Color green = Color(0xFF5E7361);
  static const Color error = Color(0xFF7D4A4A);
}

class AppTheme {
  static ThemeData get light => _build(TLPalette.light, Brightness.light);

  static ThemeData _build(TLPalette p, Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: Colors.white,
          secondary: p.coral,
          onSecondary: p.navy,
          surface: p.surface,
          onSurface: p.navy,
          error: p.error,
          onError: Colors.white,
          outline: p.fieldBorder,
        );
    final textTheme = base.textTheme
        .apply(bodyColor: p.navy, displayColor: p.navy)
        .copyWith(
          headlineSmall: TextStyle(
            color: p.navy,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
          titleLarge: TextStyle(
            color: p.navy,
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
          ),
          titleMedium: TextStyle(color: p.navy, fontWeight: FontWeight.w800),
        );
    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[p],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.navy,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: -.4,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: p.fieldBorder),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.fieldBorder),
        ),
        textStyle: TextStyle(
          color: p.navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.fieldBorder,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.fieldBorder,
          disabledForegroundColor: p.grey,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          backgroundColor: p.surface,
          side: BorderSide(color: p.fieldBorder),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.fieldBg,
        hintStyle: TextStyle(color: p.muted, fontSize: 13),
        labelStyle: TextStyle(color: p.grey, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: _border(p.fieldBorder),
        enabledBorder: _border(p.fieldBorder),
        focusedBorder: _border(p.primary, 1.4),
        errorBorder: _border(p.error),
        focusedErrorBorder: _border(p.error, 1.4),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: p.fieldBorder),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.fieldBg,
        selectedColor: p.primary,
        side: BorderSide(color: p.fieldBorder),
        labelStyle: TextStyle(
          color: p.navy,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.surface,
        contentTextStyle: TextStyle(color: p.navy, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(
        color: p.fieldBorder,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.tabBg,
      ),
      iconTheme: IconThemeData(color: p.navy),
      listTileTheme: ListTileThemeData(iconColor: p.primary, textColor: p.navy),
      dividerColor: p.fieldBorder,
    );
  }

  static OutlineInputBorder _border(Color c, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: c, width: width),
      );
}
