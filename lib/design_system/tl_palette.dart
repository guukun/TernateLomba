import 'package:flutter/material.dart';

/// Mono Edition palette: warm white base, strong black surfaces, calm neutral
/// accents. Accent slots remain available so existing pages can reuse them
/// without needing new business logic.
@immutable
class TLPalette extends ThemeExtension<TLPalette> {
  final Color primary;
  final Color primaryDark;
  final Color primaryDeep;
  final Color cream;
  final Color creamDark;
  final Color creamLight;
  final Color lightBlue;
  final Color sea;
  final Color seaDeep;
  final Color coral;
  final Color yellow;
  final Color mint;
  final Color lavender;
  final Color orange;
  final Color background;
  final Color surface;
  final Color fieldBg;
  final Color navy;
  final Color grey;
  final Color muted;
  final Color fieldBorder;
  final Color tabBg;
  final Color green;
  final Color error;
  final Color statusGoodBg;
  final Color statusBadBg;
  final Color statusWarnBg;
  final Color statusNeutralBg;

  const TLPalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryDeep,
    required this.cream,
    required this.creamDark,
    required this.creamLight,
    required this.lightBlue,
    required this.sea,
    required this.seaDeep,
    required this.coral,
    required this.yellow,
    required this.mint,
    required this.lavender,
    required this.orange,
    required this.background,
    required this.surface,
    required this.fieldBg,
    required this.navy,
    required this.grey,
    required this.muted,
    required this.fieldBorder,
    required this.tabBg,
    required this.green,
    required this.error,
    required this.statusGoodBg,
    required this.statusBadBg,
    required this.statusWarnBg,
    required this.statusNeutralBg,
  });

  static const light = TLPalette(
    primary: Color(0xFF161616),
    primaryDark: Color(0xFF0F0F0F),
    primaryDeep: Color(0xFF090909),
    cream: Color(0xFFF4F1EA),
    creamDark: Color(0xFFE5DED1),
    creamLight: Color(0xFFFCFBF8),
    lightBlue: Color(0xFFEDEBE7),
    sea: Color(0xFFF1EFEA),
    seaDeep: Color(0xFF545953),
    coral: Color(0xFF655C54),
    yellow: Color(0xFF665E4E),
    mint: Color(0xFF516052),
    lavender: Color(0xFF5E5A68),
    orange: Color(0xFF6E5D4C),
    background: Color(0xFFF7F5F0),
    surface: Color(0xFFFFFFFF),
    fieldBg: Color(0xFFF3F1EC),
    navy: Color(0xFF181818),
    grey: Color(0xFF66635E),
    muted: Color(0xFF98938B),
    fieldBorder: Color(0xFFE7E1D8),
    tabBg: Color(0xFFF0ECE5),
    green: Color(0xFF5E7361),
    error: Color(0xFF7D4A4A),
    statusGoodBg: Color(0xFFEAF0EA),
    statusBadBg: Color(0xFFF5EBE8),
    statusWarnBg: Color(0xFFF5EFE2),
    statusNeutralBg: Color(0xFFF1EEEA),
  );

  @override
  TLPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryDeep,
    Color? cream,
    Color? creamDark,
    Color? creamLight,
    Color? lightBlue,
    Color? sea,
    Color? seaDeep,
    Color? coral,
    Color? yellow,
    Color? mint,
    Color? lavender,
    Color? orange,
    Color? background,
    Color? surface,
    Color? fieldBg,
    Color? navy,
    Color? grey,
    Color? muted,
    Color? fieldBorder,
    Color? tabBg,
    Color? green,
    Color? error,
    Color? statusGoodBg,
    Color? statusBadBg,
    Color? statusWarnBg,
    Color? statusNeutralBg,
  }) => TLPalette(
    primary: primary ?? this.primary,
    primaryDark: primaryDark ?? this.primaryDark,
    primaryDeep: primaryDeep ?? this.primaryDeep,
    cream: cream ?? this.cream,
    creamDark: creamDark ?? this.creamDark,
    creamLight: creamLight ?? this.creamLight,
    lightBlue: lightBlue ?? this.lightBlue,
    sea: sea ?? this.sea,
    seaDeep: seaDeep ?? this.seaDeep,
    coral: coral ?? this.coral,
    yellow: yellow ?? this.yellow,
    mint: mint ?? this.mint,
    lavender: lavender ?? this.lavender,
    orange: orange ?? this.orange,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    fieldBg: fieldBg ?? this.fieldBg,
    navy: navy ?? this.navy,
    grey: grey ?? this.grey,
    muted: muted ?? this.muted,
    fieldBorder: fieldBorder ?? this.fieldBorder,
    tabBg: tabBg ?? this.tabBg,
    green: green ?? this.green,
    error: error ?? this.error,
    statusGoodBg: statusGoodBg ?? this.statusGoodBg,
    statusBadBg: statusBadBg ?? this.statusBadBg,
    statusWarnBg: statusWarnBg ?? this.statusWarnBg,
    statusNeutralBg: statusNeutralBg ?? this.statusNeutralBg,
  );

  @override
  TLPalette lerp(ThemeExtension<TLPalette>? other, double t) {
    if (other is! TLPalette) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return TLPalette(
      primary: blend(primary, other.primary),
      primaryDark: blend(primaryDark, other.primaryDark),
      primaryDeep: blend(primaryDeep, other.primaryDeep),
      cream: blend(cream, other.cream),
      creamDark: blend(creamDark, other.creamDark),
      creamLight: blend(creamLight, other.creamLight),
      lightBlue: blend(lightBlue, other.lightBlue),
      sea: blend(sea, other.sea),
      seaDeep: blend(seaDeep, other.seaDeep),
      coral: blend(coral, other.coral),
      yellow: blend(yellow, other.yellow),
      mint: blend(mint, other.mint),
      lavender: blend(lavender, other.lavender),
      orange: blend(orange, other.orange),
      background: blend(background, other.background),
      surface: blend(surface, other.surface),
      fieldBg: blend(fieldBg, other.fieldBg),
      navy: blend(navy, other.navy),
      grey: blend(grey, other.grey),
      muted: blend(muted, other.muted),
      fieldBorder: blend(fieldBorder, other.fieldBorder),
      tabBg: blend(tabBg, other.tabBg),
      green: blend(green, other.green),
      error: blend(error, other.error),
      statusGoodBg: blend(statusGoodBg, other.statusGoodBg),
      statusBadBg: blend(statusBadBg, other.statusBadBg),
      statusWarnBg: blend(statusWarnBg, other.statusWarnBg),
      statusNeutralBg: blend(statusNeutralBg, other.statusNeutralBg),
    );
  }
}

extension TLThemeContext on BuildContext {
  TLPalette get tl => Theme.of(this).extension<TLPalette>() ?? TLPalette.light;
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
