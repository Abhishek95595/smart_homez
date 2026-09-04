import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../models/device.dart';
import '../../models/telemetry.dart';
import '../../models/user_role.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../alerts/alerts_screen.dart';

class FireSmokeScreen extends StatefulWidget {
  const FireSmokeScreen({super.key});

  @override
  State<FireSmokeScreen> createState() => _FireSmokeScreenState();
}

class _FireSmokeScreenState extends State<FireSmokeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  _SafetyFilter _filter = _SafetyFilter.all;

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final alertProvider = context.watch<AlertProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    final sensors = deviceProvider.fireAndSmokeDevicesFor(user);
    final alerts = alertProvider.fireAndSmokeAlerts;
    final activeAlerts = alertProvider.activeSafetyAlerts;
    final filteredSensors = sensors.where(_matchesFilter).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final onlineSensors = sensors
        .where((d) => d.status == DeviceStatus.online)
        .length;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppNavigationDrawer(),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopHeader(
              activeAlertCount: activeAlerts.length,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onAlerts: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AlertsScreen()));
              },
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  _FilterRow(
                    selected: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                  const SizedBox(height: 14),
                  _SafetyHero(
                    activeAlerts: activeAlerts.length,
                    smokeAlerts: alertProvider.activeSmokeCount,
                    gasAlerts: alertProvider.activeGasLeakCount,
                    onlineSensors: onlineSensors,
                    totalSensors: sensors.length,
                  ),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'Sensor Status',
                    trailing: filteredSensors.isEmpty
                        ? null
                        : '${filteredSensors.length} shown',
                  ),
                  const SizedBox(height: 12),
                  if (filteredSensors.isEmpty)
                    _EmptySafetyState(hasAnySensor: sensors.isNotEmpty)
                  else
                    SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredSensors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final device = filteredSensors[index];
                          return _SensorCompactCard(
                            device: device,
                            telemetry: deviceProvider.telemetryFor(
                              device.deviceId,
                            ),
                            latestAlert: _latestAlertFor(
                              alerts,
                              device.deviceId,
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 22),
                  const _SectionHeader(title: 'Safety Controls'),
                  const SizedBox(height: 12),
                  _SafetyControls(
                    selected: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                    onlineSensors: onlineSensors,
                    totalSensors: sensors.length,
                    activeAlerts: activeAlerts.length,
                    onReviewAlerts: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AlertsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'Alert History',
                    trailing: alerts.isEmpty ? null : '${alerts.length} total',
                  ),
                  const SizedBox(height: 12),
                  if (alerts.isEmpty)
                    const _NoAlertCard()
                  else
                    _AlertHistoryCard(
                      alerts: alerts.take(6).toList(),
                      canAcknowledge: user?.role.canAcknowledgeAlerts ?? false,
                      onAcknowledge: (alert) => context
                          .read<AlertProvider>()
                          .acknowledge(alert, user?.name ?? 'You'),
                    ),
                  const SizedBox(height: 18),
                  _EmergencyCard(
                    hasActiveAlert: activeAlerts.isNotEmpty,
                    onReviewAlerts: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AlertsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const _AssistantStrip(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(Device device) {
    return switch (_filter) {
      _SafetyFilter.all => true,
      _SafetyFilter.smoke => device.type == DeviceType.smokeSensor,
      _SafetyFilter.gas => device.type == DeviceType.gasSensor,
      _SafetyFilter.offline => device.status == DeviceStatus.offline,
    };
  }

  AppAlert? _latestAlertFor(List<AppAlert> alerts, String deviceId) {
    final matches = alerts.where((alert) => alert.deviceId == deviceId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return matches.firstOrNull;
  }
}

enum _SafetyFilter { all, smoke, gas, offline }

class _TopHeader extends StatelessWidget {
  final int activeAlertCount;
  final VoidCallback onMenu;
  final VoidCallback onAlerts;

  const _TopHeader({
    required this.activeAlertCount,
    required this.onMenu,
    required this.onAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 21,
                color: AppColors.textPrimary,
              ),
            ),
          IconButton(
            tooltip: 'Menu',
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded, size: 28),
            color: AppColors.textPrimary,
          ),
          const Spacer(),
          const Column(
            children: [
              Text(
                'Fire & Smoke',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Monitor safety and stay protected',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onAlerts,
                icon: const Icon(Icons.notifications_none_rounded, size: 29),
                color: AppColors.textPrimary,
              ),
              if (activeAlertCount > 0)
                Positioned(
                  top: 3,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$activeAlertCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _SafetyFilter selected;
  final ValueChanged<_SafetyFilter> onChanged;

  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Sensors',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_SafetyFilter>(
                value: selected,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
                items: const [
                  DropdownMenuItem(
                    value: _SafetyFilter.all,
                    child: Text('All safety sensors'),
                  ),
                  DropdownMenuItem(
                    value: _SafetyFilter.smoke,
                    child: Text('Smoke sensors'),
                  ),
                  DropdownMenuItem(
                    value: _SafetyFilter.gas,
                    child: Text('Gas sensors'),
                  ),
                  DropdownMenuItem(
                    value: _SafetyFilter.offline,
                    child: Text('Offline sensors'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 7),
              Text(
                'Live',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyHero extends StatelessWidget {
  final int activeAlerts;
  final int smokeAlerts;
  final int gasAlerts;
  final int onlineSensors;
  final int totalSensors;

  const _SafetyHero({
    required this.activeAlerts,
    required this.smokeAlerts,
    required this.gasAlerts,
    required this.onlineSensors,
    required this.totalSensors,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlert = activeAlerts > 0;
    final health = totalSensors == 0
        ? 0
        : ((onlineSensors / totalSensors) * 100).round();

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFECF9F7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD6F0EC)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Keep the mascot in its own upper-right zone. On narrow Android
          // screens this prevents it from sitting behind the metric cards.
          Positioned(
            right: 8,
            top: 68,
            width: 132,
            height: 145,
            child: Image.asset(
              'assets/images/fire_safety_robot_ref.png',
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 224,
                  child: Row(
                    children: [
                      Icon(
                        hasAlert
                            ? Icons.warning_rounded
                            : Icons.verified_user_rounded,
                        size: 31,
                        color: hasAlert
                            ? AppColors.critical
                            : AppColors.success,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          hasAlert ? 'Attention Needed' : 'All Clear',
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 25,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                            color: hasAlert
                                ? AppColors.critical
                                : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  width: 205,
                  child: Text(
                    hasAlert
                        ? '$activeAlerts active safety alert${activeAlerts == 1 ? '' : 's'} need review.'
                        : 'Your home is safe.\nNo fire or smoke detected.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                const Spacer(),
                // Metrics are placed below the mascot rather than on top of it.
                Row(
                  children: [
                    _HeroMetric(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.danger,
                      value: '$smokeAlerts',
                      label: 'Fire Alerts',
                    ),
                    const SizedBox(width: 6),
                    _HeroMetric(
                      icon: Icons.smoke_free_rounded,
                      iconColor: AppColors.primary,
                      value: '$gasAlerts',
                      label: 'Smoke/Gas',
                    ),
                    const SizedBox(width: 6),
                    _HeroMetric(
                      icon: Icons.sensors_rounded,
                      iconColor: AppColors.textSecondary,
                      value: '$onlineSensors',
                      label: 'Active Sensors',
                    ),
                    const SizedBox(width: 6),
                    _HeroMetric(
                      icon: Icons.shield_rounded,
                      iconColor: AppColors.success,
                      value: '$health%',
                      label: 'System Health',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _HeroMetric({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _SensorCompactCard extends StatelessWidget {
  final Device device;
  final Telemetry? telemetry;
  final AppAlert? latestAlert;

  static String _sensorAssetFor(Device device) {
    final n = device.name.toLowerCase();
    final z = device.zone.toLowerCase();

    if (n.contains('heat') || z.contains('electrical')) {
      return 'assets/images/fire_heat_sensor_ref.png';
    }
    if (device.type == DeviceType.gasSensor || n.contains('gas')) {
      return 'assets/images/fire_gas_sensor_ref.png';
    }
    return 'assets/images/fire_smoke_sensor_ref.png';
  }

  static String _sensorLabelFor(Device device) {
    final n = device.name.toLowerCase();
    final z = device.zone.toLowerCase();

    if (n.contains('heat') || z.contains('electrical')) {
      return 'Heat Sensor';
    }
    if (device.type == DeviceType.gasSensor || n.contains('gas')) {
      return 'Gas Sensor';
    }
    return 'Smoke Sensor';
  }

  const _SensorCompactCard({
    required this.device,
    required this.telemetry,
    required this.latestAlert,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlert =
        latestAlert != null &&
        !latestAlert!.acknowledged &&
        !latestAlert!.resolved;
    final isOnline = device.status == DeviceStatus.online;
    final stateColor = hasAlert
        ? AppColors.critical
        : isOnline
        ? AppColors.success
        : AppColors.textFaint;

    final df = DateFormat('h:mm a');

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device.zone.isEmpty ? 'Safety Sensor' : device.zone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: stateColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasAlert ? Icons.priority_high_rounded : Icons.check_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _sensorLabelFor(device),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE4EBED)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(_sensorAssetFor(device), fit: BoxFit.contain),
            ),
          ),
          const Spacer(),
          Text(
            hasAlert
                ? 'Alert'
                : isOnline
                ? 'Normal'
                : 'Offline',
            style: TextStyle(
              color: stateColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            telemetry?.smoke == 1
                ? 'Smoke detected'
                : 'Today, ${df.format(device.lastHeartbeat)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SafetyControls extends StatelessWidget {
  final _SafetyFilter selected;
  final ValueChanged<_SafetyFilter> onChanged;
  final int onlineSensors;
  final int totalSensors;
  final int activeAlerts;
  final VoidCallback onReviewAlerts;

  const _SafetyControls({
    required this.selected,
    required this.onChanged,
    required this.onlineSensors,
    required this.totalSensors,
    required this.activeAlerts,
    required this.onReviewAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ControlTile(
                  icon: Icons.volume_off_rounded,
                  title: 'All Sensors',
                  subtitle: '$onlineSensors/$totalSensors online',
                  color: AppColors.primary,
                  onTap: () => onChanged(_SafetyFilter.all),
                  selected: selected == _SafetyFilter.all,
                ),
              ),
              Expanded(
                child: _ControlTile(
                  icon: Icons.smoke_free_rounded,
                  title: 'Smoke',
                  subtitle: 'Filter sensors',
                  color: AppColors.primary,
                  onTap: () => onChanged(_SafetyFilter.smoke),
                  selected: selected == _SafetyFilter.smoke,
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: _ControlTile(
                  icon: Icons.gas_meter_rounded,
                  title: 'Gas',
                  subtitle: 'Filter sensors',
                  color: AppColors.warning,
                  onTap: () => onChanged(_SafetyFilter.gas),
                  selected: selected == _SafetyFilter.gas,
                ),
              ),
              Expanded(
                child: _ControlTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Review Alerts',
                  subtitle: activeAlerts == 0
                      ? 'All clear'
                      : '$activeAlerts active',
                  color: activeAlerts == 0
                      ? AppColors.success
                      : AppColors.danger,
                  onTap: onReviewAlerts,
                  selected: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  const _ControlTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertHistoryCard extends StatelessWidget {
  final List<AppAlert> alerts;
  final bool canAcknowledge;
  final ValueChanged<AppAlert> onAcknowledge;

  const _AlertHistoryCard({
    required this.alerts,
    required this.canAcknowledge,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < alerts.length; i++) ...[
            _AlertHistoryTile(
              alert: alerts[i],
              canAcknowledge: canAcknowledge,
              onAcknowledge: () => onAcknowledge(alerts[i]),
            ),
            if (i != alerts.length - 1) const Divider(height: 1, indent: 58),
          ],
        ],
      ),
    );
  }
}

class _AlertHistoryTile extends StatelessWidget {
  final AppAlert alert;
  final bool canAcknowledge;
  final VoidCallback onAcknowledge;

  const _AlertHistoryTile({
    required this.alert,
    required this.canAcknowledge,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, h:mm a');
    final resolved = alert.resolved || alert.acknowledged;
    final color = resolved ? AppColors.success : AppColors.danger;

    return InkWell(
      onTap: canAcknowledge && !alert.acknowledged ? onAcknowledge : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(
                resolved ? Icons.check_rounded : Icons.warning_amber_rounded,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.alertType.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              df.format(alert.timestamp),
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final bool hasActiveAlert;
  final VoidCallback onReviewAlerts;

  const _EmergencyCard({
    required this.hasActiveAlert,
    required this.onReviewAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: hasActiveAlert
            ? const Color(0xFFFFF0F0)
            : const Color(0xFFF1FBF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasActiveAlert
              ? const Color(0xFFFFD7D7)
              : const Color(0xFFD9F1ED),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasActiveAlert
                ? Icons.warning_amber_rounded
                : Icons.health_and_safety_rounded,
            color: hasActiveAlert ? AppColors.danger : AppColors.primary,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActiveAlert
                      ? 'Safety attention needed'
                      : 'Safety guidance',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: hasActiveAlert
                        ? AppColors.danger
                        : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasActiveAlert
                      ? 'Review the alert location immediately and follow your emergency procedure.'
                      : 'If you see fire or smoke, leave the area and follow your emergency procedure.',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onReviewAlerts,
            style: FilledButton.styleFrom(
              backgroundColor: hasActiveAlert
                  ? AppColors.danger
                  : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: const Text(
              'Review',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/fire_emergency_robot_ref.png',
              width: 68,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantStrip extends StatelessWidget {
  const _AssistantStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9F1ED)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/fire_assistant_robot_ref.png',
              width: 58,
              height: 52,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask Hasomi anything...',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "I'm here to keep your home safe.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: const Icon(Icons.mic_none_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _EmptySafetyState extends StatelessWidget {
  final bool hasAnySensor;

  const _EmptySafetyState({required this.hasAnySensor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        hasAnySensor
            ? 'No sensors match this filter.'
            : 'No fire or gas sensors found. Add a Smoke Sensor or Gas Sensor from a room.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _NoAlertCard extends StatelessWidget {
  const _NoAlertCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No smoke or gas alerts recorded.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
