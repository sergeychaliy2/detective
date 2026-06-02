import 'package:flutter/material.dart';

/// Палитра "Тень числа" — киберпанк / techno-thriller.
/// Глубокий тёмный фон, неоновый циан и магента, акценты янтаря.
class AppColors {
  AppColors._();

  // Базовые фоны
  static const Color voidBlack = Color(0xFF03060D);
  static const Color deepNavy = Color(0xFF071226);
  static const Color midnight = Color(0xFF0B1A33);
  static const Color panelBg = Color(0xCC0A1626);
  static const Color panelBorder = Color(0x4D49E0FF);

  // Неоновые акценты
  static const Color neonCyan = Color(0xFF49E0FF);
  static const Color electricBlue = Color(0xFF2A7BFF);
  static const Color hologramBlue = Color(0xFF7FDBFF);
  static const Color magenta = Color(0xFFFF3DCD);
  static const Color violet = Color(0xFF8A4BFF);

  // Статусные
  static const Color amberWarning = Color(0xFFFFB23F);
  static const Color crimsonError = Color(0xFFFF4D6D);
  static const Color jadeSuccess = Color(0xFF35F0A5);

  // Текст
  static const Color textPrimary = Color(0xFFE6F4FF);
  static const Color textSecondary = Color(0xFF8BA9C7);
  static const Color textMuted = Color(0xFF55708B);

  // Градиенты
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF03060D), Color(0xFF071226), Color(0xFF0A0F2E)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [neonCyan, electricBlue, magenta],
  );

  static const RadialGradient hologramGlow = RadialGradient(
    colors: [Color(0x6649E0FF), Color(0x0049E0FF)],
    radius: 0.8,
  );
}
