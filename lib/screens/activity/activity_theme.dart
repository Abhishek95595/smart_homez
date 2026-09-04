import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Semantic styling tokens for the Activity Stream screen, deriving
/// directly from the app's global [AppColors] design system.
@immutable
class ActivityThemeData {
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

  // Status & Severity Colors
  final Color criticalBg;
  final Color criticalText;

  final Color warningBg;
  final Color warningText;

  final Color ackBg;
  final Color ackText;

  final Color resolvedBg;
  final Color resolvedText;

  const ActivityThemeData({
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
    required this.warningBg,
    required this.warningText,
    required this.ackBg,
    required this.ackText,
    required this.resolvedBg,
    required this.resolvedText,
  });
}

/// Centralized theme resolver for the Activity Stream screen.
abstract final class ActivityTheme {
  static const double largeRadius = 24.0;
  static const double mediumRadius = 16.0;
  static const double smallRadius = 12.0;

  /// Light theme palette mapped to global [AppColors]
  static const ActivityThemeData light = ActivityThemeData(
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
    warningBg: Color(0x1DF59E0B),
    warningText: AppColors.warning,
    ackBg: Color(0x1D0284C7),
    ackText: Color(0xFF0284C7),
    resolvedBg: AppColors.primarySoft,
    resolvedText: AppColors.primary,
  );

  /// Resolves the active theme for the Activity Stream screen.
  static ActivityThemeData of(BuildContext context) {
    return light;
  }
}
