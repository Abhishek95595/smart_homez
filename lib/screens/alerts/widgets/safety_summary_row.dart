import 'package:flutter/material.dart';

import '../../../models/alert.dart';
import '../../../providers/alert_provider.dart';
import '../alerts_theme.dart';

/// Row of 3 summary stat cards (Critical, High Priority, Acknowledged).
class SafetySummaryRow extends StatelessWidget {
  final AlertProvider alertProvider;
  final ValueChanged<AlertSeverity> onSelectSeverity;
  final VoidCallback onSelectAck;

  const SafetySummaryRow({
    super.key,
    required this.alertProvider,
    required this.onSelectSeverity,
    required this.onSelectAck,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AlertsTheme.of(context);

    return Row(
      children: [
        _SummaryTile(
          label: 'Critical',
          value: alertProvider.criticalActiveCount,
          textColor: colors.criticalText,
          bgColor: colors.criticalBg,
          icon: Icons.shield_outlined,
          colors: colors,
          onTap: () => onSelectSeverity(AlertSeverity.critical),
        ),
        const SizedBox(width: 8),
        _SummaryTile(
          label: 'High Priority',
          value: alertProvider.activeHighCount,
          textColor: colors.highText,
          bgColor: colors.highBg,
          icon: Icons.warning_amber_rounded,
          colors: colors,
          onTap: () => onSelectSeverity(AlertSeverity.high),
        ),
        const SizedBox(width: 8),
        _SummaryTile(
          label: 'Acknowledged',
          value: alertProvider.acknowledgedCount,
          textColor: colors.ackText,
          bgColor: colors.ackBg,
          icon: Icons.task_alt_rounded,
          colors: colors,
          onTap: onSelectAck,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int value;
  final Color textColor;
  final Color bgColor;
  final IconData icon;
  final AlertsThemeData colors;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.textColor,
    required this.bgColor,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AlertsTheme.mediumRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: colors.panel,
              borderRadius: BorderRadius.circular(AlertsTheme.mediumRadius),
              border: Border.all(
                color: textColor.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(
                      AlertsTheme.smallRadius,
                    ),
                  ),
                  child: Icon(icon, color: textColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$value',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
