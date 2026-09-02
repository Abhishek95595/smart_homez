import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

/// Semantic styling data representing the active palette for the Profile screen.
@immutable
class ProfileThemeData {
  final bool isDark;
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
    required this.isDark,
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

/// Centralized theme provider for the Smart Homz Profile screen supporting
/// both Premium Dark and Premium Light themes seamlessly.
abstract final class ProfileTheme {
  // Corner Radii
  static const double largeRadius = 20.0;
  static const double mediumRadius = 14.0;
  static const double smallRadius = 10.0;

  /// Baseline Premium Dark theme
  static const ProfileThemeData dark = ProfileThemeData(
    isDark: true,
    background: Color(0xFF10151A),
    panel: Color(0xFF1A2027),
    raised: Color(0xFF20272F),
    secondarySurface: Color(0xFF14191F),
    accent: Color(0xFF4DE8C0),
    accentSoft: Color(0x1F4DE8C0), // #4DE8C0 at ~12% opacity
    warmAccent: Color(0xFFFFB169),
    warmAccentSoft: Color(0x1FFFB169), // #FFB169 at ~12% opacity
    textPrimary: Color(0xFFEEF2F4),
    textSecondary: Color(0xFF9AA6B0),
    textTertiary: Color(0xFF5D6871),
    border: Color(0x12FFFFFF), // white at 7% opacity
    divider: Color(0x12FFFFFF),
    danger: Color(0xFFFF6B6B),
    dangerSoft: Color(0x14FF6B6B), // #FF6B6B at ~8% opacity
    shadow: Color(0x40000000),
  );

  /// New Premium Light smart-home theme
  static const ProfileThemeData light = ProfileThemeData(
    isDark: false,
    background: Color(0xFFF5FAF9),
    panel: Color(0xFFFFFFFF),
    raised: Color(0xFFF0F5F4),
    secondarySurface: Color(0xFFEAF4F2),
    accent: Color(0xFF00A38E),
    accentSoft: Color(0xFFE3F7F2),
    warmAccent: Color(0xFFE88A35),
    warmAccentSoft: Color(0xFFFFF1E4),
    textPrimary: Color(0xFF14201F),
    textSecondary: Color(0xFF64726F),
    textTertiary: Color(0xFF929E9B),
    border: Color(0xFFE2EAE8),
    divider: Color(0xFFE2EAE8),
    danger: Color(0xFFD94A4A),
    dangerSoft: Color(0xFFFFEEEE),
    shadow: Color(0x0A000000), // very subtle 4% black shadow
  );

  /// Resolves the effective [ProfileThemeData] based on the current [BuildContext] theme brightness or [ThemeProvider].
  static ProfileThemeData of(BuildContext context) {
    try {
      final themeProvider = Provider.of<ThemeProvider?>(context);
      if (themeProvider != null) {
        if (themeProvider.themeMode == ThemeMode.dark) return dark;
        if (themeProvider.themeMode == ThemeMode.light) return light;
      }
    } catch (_) {}
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }
}
