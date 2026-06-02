import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final colors = const ColorScheme.dark(
      primary: AppColors.neonCyan,
      onPrimary: AppColors.voidBlack,
      secondary: AppColors.magenta,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.deepNavy,
      onSurface: AppColors.textPrimary,
      error: AppColors.crimsonError,
      onError: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colors,
      scaffoldBackgroundColor: AppColors.voidBlack,
      textTheme: AppTypography.build(),
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      dividerColor: AppColors.panelBorder,
      iconTheme: const IconThemeData(color: AppColors.neonCyan, size: 20),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.neonCyan.withValues(alpha: 0.12),
          foregroundColor: AppColors.neonCyan,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: AppColors.neonCyan, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: AppTypography.build().labelLarge,
        ),
      ),
    );
  }
}

/// Радиусы / отступы / тайминги — стабильные тайм-функции для всех анимаций.
class AppMetrics {
  AppMetrics._();

  static const double radiusSm = 2;
  static const double radiusMd = 4;
  static const double radiusLg = 8;

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 640);
  static const Duration cinematic = Duration(milliseconds: 1200);

  static const Curve easeOutExpo = Curves.easeOutExpo;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
}
