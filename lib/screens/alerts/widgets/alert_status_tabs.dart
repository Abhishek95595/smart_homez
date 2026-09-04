import 'package:flutter/material.dart';

import '../alerts_theme.dart';

enum AlertStatusFilter { active, acknowledged, resolved, all }

/// Segmented status control tabs (Active, Ack., Resolved, All) with live count badges.
class AlertStatusTabs extends StatelessWidget {
  final AlertStatusFilter selected;
  final int activeCount;
  final int ackCount;
  final int resolvedCount;
  final int totalCount;
  final ValueChanged<AlertStatusFilter> onChanged;

  const AlertStatusTabs({
    super.key,
    required this.selected,
    required this.activeCount,
    required this.ackCount,
    required this.resolvedCount,
    required this.totalCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AlertsTheme.of(context);

    final tabs = [
      {
        'filter': AlertStatusFilter.active,
        'label': 'Active',
        'count': activeCount,
      },
      {
        'filter': AlertStatusFilter.acknowledged,
        'label': 'Ack.',
        'count': ackCount,
      },
      {
        'filter': AlertStatusFilter.resolved,
        'label': 'Resolved',
        'count': resolvedCount,
      },
      {'filter': AlertStatusFilter.all, 'label': 'All', 'count': totalCount},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.secondarySurface,
        borderRadius: BorderRadius.circular(AlertsTheme.smallRadius),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: tabs.map((t) {
          final filter = t['filter'] as AlertStatusFilter;
          final label = t['label'] as String;
          final count = t['count'] as int;
          final isSelected = selected == filter;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : colors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : colors.panel,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? Colors.white : colors.textPrimary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
