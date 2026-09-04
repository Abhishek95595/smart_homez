import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/alert.dart';
import '../../../widgets/severity_badge.dart';
import '../alerts_theme.dart';

/// Modal bottom sheet detailing an incident audit trail and safety telemetry.
class AlertDetailsSheet extends StatelessWidget {
  final AppAlert alert;
  final bool canAck;
  final bool canResolve;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  const AlertDetailsSheet({
    super.key,
    required this.alert,
    required this.canAck,
    required this.canResolve,
    required this.onAcknowledge,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AlertsTheme.of(context);
    final df = DateFormat('MMMM d, y • h:mm:ss a');

    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AlertsTheme.smallRadius),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: colors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.alertType.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Incident #${alert.id}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SeverityBadge(severity: alert.severity),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow(
            Icons.location_on_rounded,
            'Location',
            alert.location,
            colors,
          ),
          const SizedBox(height: 10),
          _detailRow(Icons.memory_rounded, 'Device ID', alert.deviceId, colors),
          const SizedBox(height: 10),
          _detailRow(
            Icons.schedule_rounded,
            'Detected At',
            df.format(alert.timestamp),
            colors,
          ),
          if (alert.value != null || alert.threshold != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.speed_rounded,
              'Telemetry Reading',
              alert.value != null
                  ? '${alert.value!.toStringAsFixed(1)}${alert.threshold != null ? ' (Limit: ${alert.threshold!.toStringAsFixed(0)})' : ''}'
                  : 'Unavailable',
              colors,
            ),
          ],
          if (alert.acknowledgedBy != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.visibility_rounded,
              'Acknowledged By',
              '${alert.acknowledgedBy}${alert.acknowledgedAt == null ? '' : ' at ${DateFormat('h:mm a').format(alert.acknowledgedAt!)}'}',
              colors,
            ),
          ],
          if (alert.resolvedBy != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.task_alt_rounded,
              'Resolved By',
              '${alert.resolvedBy}${alert.resolvedAt == null ? '' : ' at ${DateFormat('h:mm a').format(alert.resolvedAt!)}'}',
              colors,
            ),
          ],
          const SizedBox(height: 24),
          if (canAck || canResolve)
            Row(
              children: [
                if (canAck)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.ackBg,
                        foregroundColor: colors.ackText,
                        side: BorderSide(
                          color: colors.ackText.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AlertsTheme.mediumRadius,
                          ),
                        ),
                      ),
                      onPressed: onAcknowledge,
                      child: const Text('Acknowledge'),
                    ),
                  ),
                if (canAck && canResolve) const SizedBox(width: 10),
                if (canResolve)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AlertsTheme.mediumRadius,
                          ),
                        ),
                      ),
                      onPressed: onResolve,
                      child: const Text(
                        'Mark Resolved',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    AlertsThemeData colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondarySurface,
        borderRadius: BorderRadius.circular(AlertsTheme.smallRadius),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.accent),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
