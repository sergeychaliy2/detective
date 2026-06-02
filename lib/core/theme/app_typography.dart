import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Типографика: Orbitron для заголовков (техно), JetBrains Mono для данных,
/// Inter — основной текст интерфейса.
class AppTypography {
  AppTypography._();

  static TextTheme build() {
    final base = ThemeData.dark().textTheme;

    return TextTheme(
      displayLarge: GoogleFonts.orbitron(
        textStyle: base.displayLarge,
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.orbitron(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        letterSpacing: 4,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.orbitron(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        height: 1.55,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.45,
        color: AppColors.textMuted,
      ),
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: AppColors.neonCyan,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        letterSpacing: 1.0,
        color: AppColors.textMuted,
      ),
    );
  }
}
