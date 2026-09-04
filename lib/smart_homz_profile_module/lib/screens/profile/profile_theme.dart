import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Semantic styling data representing the active palette for the Profile screen.
@immutable
class ProfileThemeData {
  final Color background;
  final Color panel;
  final Color raised;
  final Color secondarySurface;

  final Color accent;
  final Color accentSoft;

  final Color warmAccent;
  final Color warmAccentSoft;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color border;
  final Color divider;

  final Color danger;
  final Color dangerSoft;

  final Color shadow;

  const ProfileThemeData({
    required this.background,
    required this.panel,
    required this.raised,
    required this.secondarySurface,
    required this.accent,
    required this.accentSoft,
    required this.warmAccent,
    required this.warmAccentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.danger,
    required this.dangerSoft,
    required this.shadow,
  });
}

/// Centralized theme provider for the Smart Homz Profile screen.
abstract final class ProfileTheme {
  // Corner Radii
  static const double largeRadius = 24.0;
  static const double mediumRadius = 18.0;
  static const double smallRadius = 14.0;

  /// Premium Light smart-home theme derived from global Hasomi tokens
  static const ProfileThemeData light = ProfileThemeData(
    background: AppColors.background, // #F8FBFB
    panel: AppColors.surface, // #FFFFFF
    raised: AppColors.surfaceElevated, // #F7F9FA
    secondarySurface: AppColors.primarySoft, // #E7F8F5
    accent: AppColors.primary, // #00A38E
    accentSoft: AppColors.primarySoft, // #E7F8F5
    warmAccent: AppColors.warning, // #FFB020
    warmAccentSoft: Color(0xFFFFF7ED),
    textPrimary: AppColors.textPrimary, // #0F172A
    textSecondary: AppColors.textSecondary, // #64748B
    textTertiary: AppColors.textFaint, // #94A3B8
    border: AppColors.divider, // #E8EEF0
    divider: AppColors.divider, // #E8EEF0
    danger: AppColors.danger, // #E5484D
    dangerSoft: Color(0xFFFEF2F2),
    shadow: Color(0x08000000),
  );

  /// Resolves the effective [ProfileThemeData] for the Profile screen.
  static ProfileThemeData of(BuildContext context) {
    return light;
  }
}
