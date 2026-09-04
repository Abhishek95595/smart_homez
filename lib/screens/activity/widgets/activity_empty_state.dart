import 'package:flutter/material.dart';

import '../activity_theme.dart';

/// Clean empty state placeholder for Activity Stream.
class ActivityEmptyState extends StatelessWidget {
  const ActivityEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ActivityTheme.of(context);

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
                borderRadius: BorderRadius.circular(ActivityTheme.largeRadius),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                color: colors.textTertiary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Activity Recorded',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'System events will appear here when available.',
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
