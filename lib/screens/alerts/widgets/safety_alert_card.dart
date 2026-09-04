import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/alert.dart';
import '../../../widgets/severity_badge.dart';
import '../alerts_theme.dart';
import 'alert_reading_panel.dart';

/// Premium Hasomi Safety Alert Card with left severity indicator bar,
/// metadata chips, inner reading panel, and audit logs.
class SafetyAlertCard extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback onTap;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;

  const SafetyAlertCard({
    super.key,
    required this.alert,
    required this.onTap,
    this.onAcknowledge,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AlertsTheme.of(context);
    final df = DateFormat('MMM d, h:mm a');

    final bool isResolved = alert.resolved;
    final bool isAck = alert.acknowledged && !isResolved;

    final sevColor = _severityColor(alert.severity, colors);

    final statusText = isResolved
        ? 'RESOLVED'
        : isAck
        ? 'ACKNOWLEDGED'
        : 'LIVE ACTIVE';

    final statusColor = isResolved
        ? colors.resolvedText
        : isAck
        ? colors.ackText
        : colors.criticalText;

    final statusBg = isResolved
        ? colors.resolvedBg
        : isAck
        ? colors.ackBg
        : colors.criticalBg;

    final statusIcon = isResolved
        ? Icons.check_circle_rounded
        : isAck
        ? Icons.pending_actions_rounded
        : Icons.radio_button_checked_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(AlertsTheme.largeRadius),
        border: Border.all(
          color: isResolved ? colors.border : sevColor.withValues(alpha: 0.45),
          width: isResolved ? 1 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isResolved
                ? colors.shadow
                : sevColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AlertsTheme.largeRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Left Severity Accent Indicator Bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5.5,
                  child: Container(
                    color: isResolved ? colors.textTertiary : sevColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar icon, Badges, Alert title & Chevron
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? colors.secondarySurface
                                  : sevColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AlertsTheme.mediumRadius,
                              ),
                            ),
                            child: Icon(
                              _iconFor(alert.alertType),
                              color: isResolved
                                  ? colors.textSecondary
                                  : sevColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    SeverityBadge(severity: alert.severity),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            statusIcon,
                                            size: 11,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              color: statusColor,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  alert.alertType.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.5,
                                    color: isResolved
                                        ? colors.textSecondary
                                        : colors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.textTertiary,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Metadata Chips (Location, Device, Time)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: Icons.location_on_rounded,
                            text: alert.location,
                            iconColor: colors.accent,
                            colors: colors,
                          ),
                          _MetaChip(
                            icon: Icons.memory_rounded,
                            text: alert.deviceId,
                            iconColor: colors.mediumText,
                            colors: colors,
                          ),
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            text: df.format(alert.timestamp),
                            iconColor: colors.textSecondary,
                            colors: colors,
                          ),
                        ],
                      ),

                      // Threshold / Reading Panel
                      if (alert.value != null || alert.threshold != null) ...[
                        const SizedBox(height: 14),
                        AlertReadingPanel(
                          value: alert.value,
                          threshold: alert.threshold,
                          isResolved: isResolved,
                        ),
                      ],

                      // Audit Log Container
                      if (alert.acknowledged &&
                          alert.acknowledgedBy != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondarySurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_pin_rounded,
                                size: 14,
                                color: colors.accent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Acknowledged by ${alert.acknowledgedBy}${alert.acknowledgedAt == null ? '' : ' • ${df.format(alert.acknowledgedAt!)}'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (alert.resolved && alert.resolvedBy != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.resolvedBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.resolvedText.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: colors.resolvedText,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Resolved by ${alert.resolvedBy}${alert.resolvedAt == null ? '' : ' • ${df.format(alert.resolvedAt!)}'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colors.resolvedText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Action Buttons Row
                      if (onAcknowledge != null || onResolve != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (onAcknowledge != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onAcknowledge,
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Acknowledge'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: colors.ackBg,
                                    foregroundColor: colors.ackText,
                                    side: BorderSide(
                                      color: colors.ackText.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AlertsTheme.smallRadius,
                                      ),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            if (onAcknowledge != null && onResolve != null)
                              const SizedBox(width: 10),
                            if (onResolve != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: onResolve,
                                  icon: const Icon(
                                    Icons.task_alt_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Mark Resolved'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.accent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AlertsTheme.smallRadius,
                                      ),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _severityColor(AlertSeverity sev, AlertsThemeData colors) {
    return switch (sev) {
      AlertSeverity.critical => colors.criticalText,
      AlertSeverity.high => colors.highText,
      AlertSeverity.medium => colors.mediumText,
      AlertSeverity.low => colors.lowText,
    };
  }

  IconData _iconFor(AlertType type) {
    return switch (type) {
      AlertType.smoke => Icons.local_fire_department_rounded,
      AlertType.gasLeak => Icons.propane_tank_rounded,
      AlertType.waterOverflow => Icons.waves_rounded,
      AlertType.pumpDryRun => Icons.water_damage_rounded,
      AlertType.highLoad => Icons.bolt_rounded,
      AlertType.deviceOffline => Icons.wifi_off_rounded,
      AlertType.general => Icons.info_rounded,
    };
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final AlertsThemeData colors;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondarySurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
