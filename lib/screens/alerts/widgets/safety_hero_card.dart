import 'package:flutter/material.dart';

import '../../../utils/robot_avatar_mapper.dart';
import '../../../widgets/robot_avatar.dart';
import '../alerts_theme.dart';

/// Hasomi-style Critical Incident Hero Status Card.
/// Renders when active critical safety incidents exist, avoiding aggressive solid red backgrounds.
class SafetyHeroCard extends StatelessWidget {
  final int count;
  final VoidCallback onFilterCritical;

  const SafetyHeroCard({
    super.key,
    required this.count,
    required this.onFilterCritical,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AlertsTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(AlertsTheme.largeRadius),
        border: Border.all(
          color: colors.criticalText.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.criticalText.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          RobotAvatar(
            type: RobotAvatarMapper.mapAlertSeverity(
              activeAlertCount: count,
              maxSeverity: 'CRITICAL',
            ),
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Critical Safety Incident${count > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: colors.criticalText,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Immediate attention required for active property safety',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onFilterCritical,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.criticalBg,
              foregroundColor: colors.criticalText,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AlertsTheme.smallRadius),
                side: BorderSide(
                  color: colors.criticalText.withValues(alpha: 0.3),
                ),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
            child: const Text('VIEW'),
          ),
        ],
      ),
    );
  }
}
