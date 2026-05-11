import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── BRAND — same in both themes ──────────────────────────────
  static const Color primary        = Color(0xFF5B4FD4); // Deep purple
  static const Color primaryLight   = Color(0xFF7B6FEE); // Soft purple
  static const Color primaryDark    = Color(0xFF3D33A8); // Dark purple
  static const Color accent         = Color(0xFF00C8A0); // Teal green
  static const Color missed         = Color(0xFFE84B4B); // Red (missed call)
  static const Color bubbleSent     = Color(0xFF5B4FD4); // Always purple
  static const Color online         = Color(0xFF00C8A0); // Online status green

  // ── DARK THEME ───────────────────────────────────────────────
  static const Color darkBg         = Color(0xFF0D0D1E); 
  static const Color darkCard       = Color(0xFF181830); 
  static const Color darkSurface    = Color(0xFF22223A); 
  static const Color darkInput      = Color(0xFF1C1C38); 
  static const Color darkDivider    = Color(0xFF2A2A4A); 
  static const Color darkText1      = Color(0xFFFFFFFF); 
  static const Color darkText2      = Color(0xFFB0AADD); 
  static const Color darkText3      = Color(0xFF6B6490); 
  static const Color darkNavBg      = Color(0xFF0D0D1E); 

  // ── LIGHT THEME ──────────────────────────────────────────────
  static const Color lightBg        = Color(0xFFF5F4FF); 
  static const Color lightCard      = Color(0xFFEEEAFF); // Soft purple tint (app bar + nav)
  static const Color lightSurface   = Color(0xFFEDE9FF); 
  static const Color lightInput     = Color(0xFFF0EEFF); 
  static const Color lightDivider   = Color(0xFFD4CFFF); // Deeper, more visible
  static const Color lightText1     = Color(0xFF1A1640); 
  static const Color lightText2     = Color(0xFF5C558C); 
  static const Color lightText3     = Color(0xFF9B96C4); 
  static const Color lightNavBg     = Color(0xFFFDFDFF); // Very subtle lavender tint
}

@immutable
class SawaColors extends ThemeExtension<SawaColors> {
  final Color background;
  final Color card;
  final Color surface;
  final Color input;
  final Color divider;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color navBg;

  const SawaColors({
    required this.background,
    required this.card,
    required this.surface,
    required this.input,
    required this.divider,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.navBg,
  });

  @override
  SawaColors copyWith({
    Color? background,
    Color? card,
    Color? surface,
    Color? input,
    Color? divider,
    Color? text1,
    Color? text2,
    Color? text3,
    Color? navBg,
  }) {
    return SawaColors(
      background: background ?? this.background,
      card: card ?? this.card,
      surface: surface ?? this.surface,
      input: input ?? this.input,
      divider: divider ?? this.divider,
      text1: text1 ?? this.text1,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      navBg: navBg ?? this.navBg,
    );
  }

  @override
  SawaColors lerp(ThemeExtension<SawaColors>? other, double t) {
    if (other is! SawaColors) return this;
    return SawaColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      input: Color.lerp(input, other.input, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      text1: Color.lerp(text1, other.text1, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
    );
  }

  static const dark = SawaColors(
    background: AppColors.darkBg,
    card: AppColors.darkCard,
    surface: AppColors.darkSurface,
    input: AppColors.darkInput,
    divider: AppColors.darkDivider,
    text1: AppColors.darkText1,
    text2: AppColors.darkText2,
    text3: AppColors.darkText3,
    navBg: AppColors.darkNavBg,
  );

  static const light = SawaColors(
    background: AppColors.lightBg,
    card: AppColors.lightCard,
    surface: AppColors.lightSurface,
    input: AppColors.lightInput,
    divider: AppColors.lightDivider,
    text1: AppColors.lightText1,
    text2: AppColors.lightText2,
    text3: AppColors.lightText3,
    navBg: AppColors.lightNavBg,
  );
}

extension SawaThemeContext on BuildContext {
  SawaColors get sawaColors => Theme.of(this).extension<SawaColors>()!;
}
