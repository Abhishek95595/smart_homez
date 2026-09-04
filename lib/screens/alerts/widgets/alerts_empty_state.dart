import 'package:flutter/material.dart';

import '../alerts_theme.dart';
import 'alert_status_tabs.dart';

/// Clean empty state placeholder for Safety & Alerts screen.
class AlertsEmptyState extends StatelessWidget {
  final AlertStatusFilter statusFilter;
  final bool hasCustomFilters;

  const AlertsEmptyState({
    super.key,
    required this.statusFilter,
    required this.hasCustomFilters,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AlertsTheme.of(context);

    final title = hasCustomFilters
        ? 'No Matching Alerts'
        : switch (statusFilter) {
            AlertStatusFilter.active => 'No Active Safety Alerts',
            AlertStatusFilter.acknowledged => 'No Acknowledged Alerts',
            AlertStatusFilter.resolved => 'No Resolved Alerts History',
            AlertStatusFilter.all => 'No Safety Alerts',
          };

    final message = hasCustomFilters
        ? 'Try clearing active search or severity filters to view more alerts.'
        : 'Your smart home ecosystem is running safely with all parameters normal.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.secondarySurface,
                borderRadius: BorderRadius.circular(AlertsTheme.largeRadius),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.shield_moon_rounded,
                color: colors.accent,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
