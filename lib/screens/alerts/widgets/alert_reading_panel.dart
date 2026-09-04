import 'package:flutter/material.dart';

import '../alerts_theme.dart';

/// Inner telemetry reading & threshold panel for safety alert cards.
class AlertReadingPanel extends StatelessWidget {
  final double? value;
  final double? threshold;
  final bool isResolved;

  const AlertReadingPanel({
    super.key,
    required this.value,
    required this.threshold,
    required this.isResolved,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AlertsTheme.of(context);

    final bool hasData = value != null && threshold != null;
    final val = value ?? 0.0;
    final thresh = threshold ?? 1.0;

    final ratio = thresh <= 0 ? 1.0 : (val / thresh).clamp(0.0, 1.4).toDouble();
    final isOver = hasData && val >= thresh && !isResolved;

    final panelBg = isOver ? colors.criticalBg : colors.secondarySurface;

    final borderCol = isOver
        ? colors.criticalText.withValues(alpha: 0.3)
        : colors.border;

    final statusText = hasData
        ? (isOver ? 'EXCEEDED' : 'NORMAL')
        : 'UNAVAILABLE';
    final statusColor = hasData
        ? (isOver ? colors.criticalText : colors.lowText)
        : colors.textTertiary;
    final statusBg = hasData
        ? (isOver ? colors.criticalBg : colors.lowBg)
        : colors.secondarySurface;

    final displayText = hasData
        ? 'Reading: ${val.toStringAsFixed(1)} (Limit: ${thresh.toStringAsFixed(1)})'
        : 'Telemetry: Unavailable';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(AlertsTheme.smallRadius),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: isOver ? colors.criticalText : colors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          if (hasData) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? colors.criticalText : colors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
