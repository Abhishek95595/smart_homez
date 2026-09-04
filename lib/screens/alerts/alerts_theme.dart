import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Semantic styling tokens for the Safety & Alerts screen, deriving
/// directly from the app's global [AppColors] design system.
@immutable
class AlertsThemeData {
  final Color background;
  final Color panel;
  final Color raised;
  final Color secondarySurface;

  final Color accent;
  final Color accentSoft;
  final Color accentDark;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color border;
  final Color divider;
  final Color shadow;

  // Severity & Status Colors
  final Color criticalBg;
  final Color criticalText;

  final Color highBg;
  final Color highText;

  final Color mediumBg;
  final Color mediumText;

  final Color lowBg;
  final Color lowText;

  final Color ackBg;
  final Color ackText;

  final Color resolvedBg;
  final Color resolvedText;

  const AlertsThemeData({
    required this.background,
    required this.panel,
    required this.raised,
    required this.secondarySurface,
    required this.accent,
    required this.accentSoft,
    required this.accentDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.criticalBg,
    required this.criticalText,
    required this.highBg,
    required this.highText,
    required this.mediumBg,
    required this.mediumText,
    required this.lowBg,
    required this.lowText,
    required this.ackBg,
    required this.ackText,
    required this.resolvedBg,
    required this.resolvedText,
  });
}

/// Centralized theme resolver for the Safety & Alerts screen.
abstract final class AlertsTheme {
  static const double largeRadius = 24.0;
  static const double mediumRadius = 18.0;
  static const double smallRadius = 12.0;

  /// Light theme palette mapped to global [AppColors]
  static const AlertsThemeData light = AlertsThemeData(
    background: AppColors.background,
    panel: AppColors.surface,
    raised: AppColors.surfaceElevated,
    secondarySurface: AppColors.primarySoft,
    accent: AppColors.primary,
    accentSoft: AppColors.primarySoft,
    accentDark: AppColors.primaryDark,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textFaint,
    border: AppColors.divider,
    divider: AppColors.divider,
    shadow: Color(0x0A000000),
    criticalBg: Color(0x1DEF4444),
    criticalText: AppColors.critical,
    highBg: Color(0x1DF59E0B),
    highText: AppColors.warning,
    mediumBg: Color(0x1D3B82F6),
    mediumText: Color(0xFF0284C7),
    lowBg: AppColors.primarySoft,
    lowText: AppColors.primary,
    ackBg: Color(0x1D0284C7),
    ackText: Color(0xFF0284C7),
    resolvedBg: AppColors.primarySoft,
    resolvedText: AppColors.primary,
  );

  /// Resolves the active theme for the Safety & Alerts screen.
  static AlertsThemeData of(BuildContext context) {
    return light;
  }
}
