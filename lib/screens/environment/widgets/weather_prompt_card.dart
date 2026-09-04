import 'package:flutter/material.dart';

import '../environment_theme.dart';

/// Redesigned Weather Recommendation Prompt Card using Hasomi Light Theme design tokens.
class WeatherPromptCard extends StatelessWidget {
  final Map<String, dynamic> prompt;

  const WeatherPromptCard({super.key, required this.prompt});

  @override
  Widget build(BuildContext context) {
    final colors = EnvironmentTheme.of(context);

    final title = prompt['title']?.toString() ?? 'Climate Tip';
    final desc =
        prompt['description']?.toString() ??
        'Optimized for natural comfort & savings.';
    final type = prompt['type']?.toString() ?? '';

    IconData icon;
    Color accentColor;
    switch (type.toLowerCase()) {
      case 'rain':
      case 'humidity':
        icon = Icons.water_drop_rounded;
        accentColor = colors.humidityAccent;
        break;
      case 'heat':
      case 'temperature':
        icon = Icons.thermostat_rounded;
        accentColor = colors.tempAccent;
        break;
      case 'wind':
        icon = Icons.air_rounded;
        accentColor = colors.accent;
        break;
      case 'uv':
      case 'sun':
        icon = Icons.wb_sunny_rounded;
        accentColor = colors.uvAccent;
        break;
      default:
        icon = Icons.tips_and_updates_rounded;
        accentColor = colors.accent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(EnvironmentTheme.mediumRadius),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(EnvironmentTheme.smallRadius),
            ),
            child: Icon(icon, color: accentColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
