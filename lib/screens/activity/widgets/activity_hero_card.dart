import 'package:flutter/material.dart';

import '../../../providers/alert_provider.dart';
import '../activity_theme.dart';

/// Redesigned Live System Events Hero Status Card.
/// Displays live total, action-required, and resolved metrics dynamically derived from [AlertProvider].
class ActivityHeroCard extends StatelessWidget {
  final AlertProvider alertProvider;

  const ActivityHeroCard({super.key, required this.alertProvider});

  @override
  Widget build(BuildContext context) {
    final colors = ActivityTheme.of(context);

    final total = alertProvider.alerts.length;
    final resolved = alertProvider.alerts
        .where((activity) => activity.resolved)
        .length;
    final activeCritical = alertProvider.criticalActiveCount;
    final unacknowledged = alertProvider.alerts
        .where((a) => !a.acknowledged && !a.resolved)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.secondarySurface,
        borderRadius: BorderRadius.circular(ActivityTheme.largeRadius),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(
                    ActivityTheme.mediumRadius,
                  ),
                ),
                child: const Icon(
                  Icons.stream_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'EVENT TIMELINE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: colors.accentDark,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Live System Events',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeCritical > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.criticalBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.criticalText.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: colors.criticalText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$activeCritical Critical',
                        style: TextStyle(
                          color: colors.criticalText,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Compact Stat Tiles Row
          Row(
            children: [
              _StatTile(
                label: 'Total Events',
                value: '$total',
                icon: Icons.history_rounded,
                accentColor: colors.accentDark,
                colors: colors,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'Action Required',
                value: '$unacknowledged',
                icon: Icons.priority_high_rounded,
                accentColor: colors.warningText,
                colors: colors,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'Resolved',
                value: '$resolved',
                icon: Icons.task_alt_rounded,
                accentColor: colors.resolvedText,
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final ActivityThemeData colors;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(ActivityTheme.smallRadius),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: accentColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
