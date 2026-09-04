import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Semantic styling tokens for the Smart Environment screen, deriving
/// directly from the app's global [AppColors] design system.
@immutable
class EnvironmentThemeData {
  final Color background;
  final Color panel;
  final Color raised;
  final Color secondarySurface;

  final Color accent;
  final Color accentSoft;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color border;
  final Color divider;
  final Color shadow;

  // Centralized Semantic Environment Accent Colors
  final Color tempCardBg;
  final Color tempAccent;

  final Color humidityCardBg;
  final Color humidityAccent;

  final Color aqiCardBg;
  final Color aqiAccent;

  final Color uvCardBg;
  final Color uvAccent;

  const EnvironmentThemeData({
    required this.background,
    required this.panel,
    required this.raised,
    required this.secondarySurface,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.tempCardBg,
    required this.tempAccent,
    required this.humidityCardBg,
    required this.humidityAccent,
    required this.aqiCardBg,
    required this.aqiAccent,
    required this.uvCardBg,
    required this.uvAccent,
  });
}

/// Centralized theme resolver for the Smart Environment screen.
abstract final class EnvironmentTheme {
  static const double largeRadius = 24.0;
  static const double mediumRadius = 18.0;
  static const double smallRadius = 14.0;

  /// Light theme palette mapped to global [AppColors]
  static const EnvironmentThemeData light = EnvironmentThemeData(
    background: AppColors.background,
    panel: AppColors.surface,
    raised: AppColors.surfaceElevated,
    secondarySurface: AppColors.primarySoft,
    accent: AppColors.primary,
    accentSoft: AppColors.primarySoft,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textFaint,
    border: AppColors.divider,
    divider: AppColors.divider,
    shadow: Color(0x0A000000),
    tempCardBg: AppColors.primarySoft,
    tempAccent: AppColors.primary,
    humidityCardBg: Color(0xFFEFF6FF),
    humidityAccent: Color(0xFF0284C7),
    aqiCardBg: AppColors.primarySoft,
    aqiAccent: AppColors.primary,
    uvCardBg: Color(0xFFFFFBEB),
    uvAccent: Color(0xFFD97706),
  );

  /// Resolves the active theme for the Smart Environment screen.
  static EnvironmentThemeData of(BuildContext context) {
    return light;
  }
}
