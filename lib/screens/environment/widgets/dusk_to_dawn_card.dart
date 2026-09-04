import 'package:flutter/material.dart';

import '../environment_theme.dart';

/// Redesigned Dusk-to-Dawn Automation Card using Hasomi Light Theme design tokens.
class DuskToDawnCard extends StatelessWidget {
  final bool enabled;
  final String mode;
  final ValueChanged<bool> onChanged;

  const DuskToDawnCard({
    super.key,
    required this.enabled,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = EnvironmentTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(EnvironmentTheme.largeRadius),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(EnvironmentTheme.smallRadius),
            ),
            child: Icon(
              enabled ? Icons.nightlight_round : Icons.wb_sunny_outlined,
              color: colors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dusk-to-Dawn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? 'Night lights activate at sunset'
                      : 'Manual lighting mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mode.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: colors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: colors.accent,
            activeTrackColor: colors.accentSoft,
            inactiveThumbColor: colors.textTertiary,
            inactiveTrackColor: colors.raised,
          ),
        ],
      ),
    );
  }
}
