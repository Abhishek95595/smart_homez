import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/alert.dart';
import '../../../widgets/severity_badge.dart';
import '../activity_theme.dart';

/// Premium rounded card rendering a live system activity event.
class ActivityEventCard extends StatelessWidget {
  final AppAlert alert;
  final String userName;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final VoidCallback onTap;

  const ActivityEventCard({
    super.key,
    required this.alert,
    required this.userName,
    required this.onAcknowledge,
    required this.onResolve,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ActivityTheme.of(context);

    final statusColor = alert.resolved
        ? colors.resolvedText
        : alert.acknowledged
        ? colors.ackText
        : alert.severity == AlertSeverity.critical
        ? colors.criticalText
        : colors.warningText;

    final statusBg = alert.resolved
        ? colors.resolvedBg
        : alert.acknowledged
        ? colors.ackBg
        : alert.severity == AlertSeverity.critical
        ? colors.criticalBg
        : colors.warningBg;

    final statusText = alert.resolved
        ? 'RESOLVED'
        : alert.acknowledged
        ? 'ACKNOWLEDGED'
        : 'ACTION REQUIRED';

    final categoryIcon = _getCategoryIcon(alert.alertType);

    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(ActivityTheme.largeRadius),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ActivityTheme.largeRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Category Icon, Alert Title, Location, Severity Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        borderRadius: BorderRadius.circular(
                          ActivityTheme.smallRadius,
                        ),
                      ),
                      child: Icon(categoryIcon, color: colors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.alertType.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: colors.textTertiary,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  alert.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    SeverityBadge(severity: alert.severity),
                  ],
                ),
                const SizedBox(height: 12),

                // Device Chip and Telemetry Inset Container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondarySurface,
                    borderRadius: BorderRadius.circular(
                      ActivityTheme.smallRadius,
                    ),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.memory_rounded,
                        size: 14,
                        color: colors.accent,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Device: ${alert.deviceId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (alert.value != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Metric: ${alert.value!.toStringAsFixed(1)}${alert.threshold != null ? ' / ${alert.threshold!.toStringAsFixed(0)}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Footer: Timestamp & Status Badge
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatTimestamp(alert.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),

                // Action Buttons Row if not resolved
                if (!alert.resolved) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!alert.acknowledged)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: colors.ackBg,
                              foregroundColor: colors.ackText,
                              side: BorderSide(
                                color: colors.ackText.withValues(alpha: 0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ActivityTheme.smallRadius,
                                ),
                              ),
                            ),
                            onPressed: onAcknowledge,
                            icon: const Icon(
                              Icons.visibility_rounded,
                              size: 15,
                            ),
                            label: const Text(
                              'Acknowledge',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      if (!alert.acknowledged) const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ActivityTheme.smallRadius,
                              ),
                            ),
                          ),
                          onPressed: onResolve,
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                          ),
                          label: const Text(
                            'Mark Resolved',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(time);
  }

  IconData _getCategoryIcon(AlertType type) {
    return switch (type) {
      AlertType.smoke => Icons.local_fire_department_rounded,
      AlertType.gasLeak => Icons.propane_tank_rounded,
      AlertType.waterOverflow => Icons.waves_rounded,
      AlertType.pumpDryRun => Icons.water_damage_rounded,
      AlertType.highLoad => Icons.bolt_rounded,
      AlertType.deviceOffline => Icons.cloud_off_rounded,
      AlertType.general => Icons.sensors_rounded,
    };
  }
}
