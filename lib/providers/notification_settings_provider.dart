import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing push notification settings across the app:
/// 1. General notifications (device status, routine push notifications)
/// 2. Critical notifications (fire alarm, gas leak, water overflow)
/// 3. Plan notifications (plan offers, expiring plan alerts)
class NotificationSettingsProvider extends ChangeNotifier {
  static const String generalPrefKey = 'notif_general_enabled';
  static const String criticalPrefKey = 'notif_critical_enabled';
  static const String planPrefKey = 'notif_plan_enabled';

  bool _generalNotifications = true;
  bool _criticalNotifications = true;
  bool _planNotifications = true;

  bool get generalNotifications => _generalNotifications;
  bool get criticalNotifications => _criticalNotifications;
  bool get planNotifications => _planNotifications;

  NotificationSettingsProvider() {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _generalNotifications = prefs.getBool(generalPrefKey) ?? true;
      _criticalNotifications = prefs.getBool(criticalPrefKey) ?? true;
      _planNotifications = prefs.getBool(planPrefKey) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setGeneralNotifications(bool value) async {
    if (_generalNotifications == value) return;
    _generalNotifications = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(generalPrefKey, value);
    } catch (_) {}
  }

  Future<void> setCriticalNotifications(bool value) async {
    if (_criticalNotifications == value) return;
    _criticalNotifications = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(criticalPrefKey, value);
    } catch (_) {}
  }

  Future<void> setPlanNotifications(bool value) async {
    if (_planNotifications == value) return;
    _planNotifications = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(planPrefKey, value);
    } catch (_) {}
  }

  /// Handles toggling critical notifications with safety warning dialog
  Future<void> toggleCriticalWithConfirmation(
    BuildContext context,
    bool targetValue,
  ) async {
    if (targetValue == true) {
      // Turning ON does not need a warning
      await setCriticalNotifications(true);
      return;
    }

    // Attempting to turn OFF -> show warning popup
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Disable Critical Alerts?',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Critical notifications provide life-safety alerts for urgent hazards:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Column(
                children: const [
                  _CriticalBullet(
                    icon: Icons.local_fire_department_rounded,
                    color: Color(0xFFEF4444),
                    title: 'Fire & Smoke Detection',
                  ),
                  SizedBox(height: 8),
                  _CriticalBullet(
                    icon: Icons.air_rounded,
                    color: Color(0xFFF59E0B),
                    title: 'Gas Leak & Thermal Warnings',
                  ),
                  SizedBox(height: 8),
                  _CriticalBullet(
                    icon: Icons.water_drop_rounded,
                    color: Color(0xFF3B82F6),
                    title: 'Water Overflow & Tank Faults',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Disabling these notifications may delay emergency response. Are you sure you want to turn off critical alerts?',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true), // Disable anyway
            child: const Text(
              'Disable Anyway',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A38E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(false), // Keep enabled
            child: const Text(
              'Keep Enabled',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await setCriticalNotifications(false);
    }
  }

  @visibleForTesting
  void setPreferencesForTesting({bool? general, bool? critical, bool? plan}) {
    if (general != null) _generalNotifications = general;
    if (critical != null) _criticalNotifications = critical;
    if (plan != null) _planNotifications = plan;
    notifyListeners();
  }
}

class _CriticalBullet extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _CriticalBullet({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
