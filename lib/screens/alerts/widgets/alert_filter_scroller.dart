import 'package:flutter/material.dart';

import '../../../models/alert.dart';
import '../alerts_theme.dart';

/// Horizontally scrollable chip filter row for Alert Severity and Alert Type.
class AlertFilterScroller extends StatelessWidget {
  final AlertSeverity? severityFilter;
  final AlertType? typeFilter;
  final ValueChanged<AlertSeverity?> onSeverityChanged;
  final ValueChanged<AlertType?> onTypeChanged;
  final VoidCallback onClear;

  const AlertFilterScroller({
    super.key,
    required this.severityFilter,
    required this.typeFilter,
    required this.onSeverityChanged,
    required this.onTypeChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AlertsTheme.of(context);
    final hasFilter = severityFilter != null || typeFilter != null;

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (hasFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.criticalBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.criticalText.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: colors.criticalText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Clear Filters',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.criticalText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _chip(
            label: 'Critical',
            selected: severityFilter == AlertSeverity.critical,
            color: colors.criticalText,
            colors: colors,
            onTap: () => onSeverityChanged(
              severityFilter == AlertSeverity.critical
                  ? null
                  : AlertSeverity.critical,
            ),
          ),
          _chip(
            label: 'High',
            selected: severityFilter == AlertSeverity.high,
            color: colors.highText,
            colors: colors,
            onTap: () => onSeverityChanged(
              severityFilter == AlertSeverity.high ? null : AlertSeverity.high,
            ),
          ),
          _chip(
            label: 'Medium',
            selected: severityFilter == AlertSeverity.medium,
            color: colors.mediumText,
            colors: colors,
            onTap: () => onSeverityChanged(
              severityFilter == AlertSeverity.medium
                  ? null
                  : AlertSeverity.medium,
            ),
          ),
          _chip(
            label: 'Low',
            selected: severityFilter == AlertSeverity.low,
            color: colors.lowText,
            colors: colors,
            onTap: () => onSeverityChanged(
              severityFilter == AlertSeverity.low ? null : AlertSeverity.low,
            ),
          ),
          _chip(
            label: 'Smoke',
            selected: typeFilter == AlertType.smoke,
            icon: Icons.local_fire_department_rounded,
            color: colors.criticalText,
            colors: colors,
            onTap: () => onTypeChanged(
              typeFilter == AlertType.smoke ? null : AlertType.smoke,
            ),
          ),
          _chip(
            label: 'Gas Leak',
            selected: typeFilter == AlertType.gasLeak,
            icon: Icons.propane_tank_rounded,
            color: colors.criticalText,
            colors: colors,
            onTap: () => onTypeChanged(
              typeFilter == AlertType.gasLeak ? null : AlertType.gasLeak,
            ),
          ),
          _chip(
            label: 'Water Overflow',
            selected: typeFilter == AlertType.waterOverflow,
            icon: Icons.water_damage_rounded,
            color: colors.mediumText,
            colors: colors,
            onTap: () => onTypeChanged(
              typeFilter == AlertType.waterOverflow
                  ? null
                  : AlertType.waterOverflow,
            ),
          ),
          _chip(
            label: 'Offline',
            selected: typeFilter == AlertType.deviceOffline,
            icon: Icons.wifi_off_rounded,
            color: colors.textSecondary,
            colors: colors,
            onTap: () => onTypeChanged(
              typeFilter == AlertType.deviceOffline
                  ? null
                  : AlertType.deviceOffline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required Color color,
    required AlertsThemeData colors,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : colors.panel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : colors.border,
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? Colors.white : color),
                const SizedBox(width: 4),
              ] else ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: selected ? Colors.white : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
