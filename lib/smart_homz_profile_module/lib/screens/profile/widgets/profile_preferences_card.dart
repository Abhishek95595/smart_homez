import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/profile_provider.dart';
import '../../../providers/theme_provider.dart';
import '../profile_theme.dart';
import 'avatar_picker_sheet.dart';

/// Card showing application preferences like Theme, Units, Language, and Companion Avatar.
class ProfilePreferencesCard extends StatelessWidget {
  const ProfilePreferencesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final avatar = profileProvider.currentAvatar;
    final currentThemeMode = themeProvider.themeName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PREFERENCES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(ProfileTheme.largeRadius),
            border: Border.all(color: colors.border, width: 1.0),
            boxShadow: colors.isDark
                ? null
                : [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // Companion Avatar row
              InkWell(
                onTap: () => AvatarPickerSheet.show(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ProfileTheme.largeRadius),
                ),
                splashColor: colors.accent.withValues(alpha: 0.08),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.raised,
                          borderRadius: BorderRadius.circular(
                            ProfileTheme.smallRadius,
                          ),
                        ),
                        child: Icon(
                          Icons.smart_toy_outlined,
                          color: colors.accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Companion Avatar',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.raised,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                avatar.assetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            avatar.name,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.textTertiary,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _RowDivider(color: colors.divider),
              // Theme row with interactive segmented selector
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.raised,
                        borderRadius: BorderRadius.circular(
                          ProfileTheme.smallRadius,
                        ),
                      ),
                      child: Icon(
                        colors.isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: colors.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$currentThemeMode Mode',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ThemeSegmentedChoice(
                      values: const ['Light', 'Dark'],
                      selected: currentThemeMode,
                      onSelected: (value) {
                        if (value == 'Light') {
                          themeProvider.setThemeMode(ThemeMode.light);
                        } else if (value == 'Dark') {
                          themeProvider.setThemeMode(ThemeMode.dark);
                        }
                      },
                    ),
                  ],
                ),
              ),
              _RowDivider(color: colors.divider),
              // Temperature Units row
              const _PreferenceRow(
                icon: Icons.thermostat_rounded,
                label: 'Units',
                value: '°C (Metric)',
              ),
              _RowDivider(color: colors.divider),
              // Language row
              const _PreferenceRow(
                icon: Icons.language_rounded,
                label: 'Language',
                value: 'English (US)',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeSegmentedChoice extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ThemeSegmentedChoice({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: values.map((value) {
          final isSelected = selected == value;
          final Color activeText = colors.isDark
              ? colors.background
              : Colors.white;

          return InkWell(
            onTap: () => onSelected(value),
            borderRadius: BorderRadius.circular(11),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: isSelected && !colors.isDark
                    ? [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: isSelected ? activeText : colors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.raised,
              borderRadius: BorderRadius.circular(ProfileTheme.smallRadius),
            ),
            child: Icon(icon, color: colors.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textTertiary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  final Color color;

  const _RowDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
      color: color,
    );
  }
}
