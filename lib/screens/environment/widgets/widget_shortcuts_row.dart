import 'package:flutter/material.dart';

import '../environment_theme.dart';

/// Redesigned Quick Shortcuts row using Hasomi Light Theme design tokens.
class WidgetShortcutsRow extends StatelessWidget {
  final List<Map<String, dynamic>> scenes;

  const WidgetShortcutsRow({super.key, required this.scenes});

  static const List<IconData> _icons = [
    Icons.lightbulb_outline_rounded,
    Icons.thermostat_rounded,
    Icons.nightlight_round,
    Icons.movie_outlined,
    Icons.lock_outline_rounded,
    Icons.power_settings_new_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = EnvironmentTheme.of(context);

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: scenes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final scene = scenes[index];
          final name = scene['name']?.toString() ?? 'Scene';
          final icon = _icons[index % _icons.length];

          return Container(
            width: 92,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.panel,
              borderRadius: BorderRadius.circular(
                EnvironmentTheme.mediumRadius,
              ),
              border: Border.all(color: colors.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(
                      EnvironmentTheme.smallRadius,
                    ),
                  ),
                  child: Icon(icon, color: colors.accent, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
