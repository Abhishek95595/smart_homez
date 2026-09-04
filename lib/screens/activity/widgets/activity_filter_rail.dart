import 'package:flutter/material.dart';

import '../activity_theme.dart';

enum ActivityFilter { all, newItems, acknowledged, resolved, critical }

/// Horizontally scrollable category filter rail for Activity Stream events.
class ActivityFilterRail extends StatelessWidget {
  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onSelected;

  const ActivityFilterRail({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ActivityTheme.of(context);

    final filters = [
      {
        'f': ActivityFilter.all,
        'label': 'All Feed',
        'icon': Icons.feed_rounded,
      },
      {
        'f': ActivityFilter.newItems,
        'label': 'New Unread',
        'icon': Icons.fiber_new_rounded,
      },
      {
        'f': ActivityFilter.acknowledged,
        'label': 'Acknowledged',
        'icon': Icons.visibility_rounded,
      },
      {
        'f': ActivityFilter.resolved,
        'label': 'Resolved',
        'icon': Icons.check_circle_rounded,
      },
      {
        'f': ActivityFilter.critical,
        'label': 'Critical Only',
        'icon': Icons.warning_rounded,
      },
    ];

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((item) {
          final f = item['f'] as ActivityFilter;
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = selected == f;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accent : colors.panel,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? colors.accent : colors.border,
                  ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: isSelected ? Colors.white : colors.textPrimary,
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
