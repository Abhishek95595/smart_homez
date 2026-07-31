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
import '../../widgets/severity_badge.dart';

class FireSmokeScreen extends StatefulWidget {
  const FireSmokeScreen({super.key});

  @override
  State<FireSmokeScreen> createState() => _FireSmokeScreenState();
}

class _FireSmokeScreenState extends State<FireSmokeScreen> {
  _SafetyFilter _filter = _SafetyFilter.all;

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final alertProvider = context.watch<AlertProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final sensors = deviceProvider.fireAndSmokeDevicesFor(user);
    final alerts = alertProvider.fireAndSmokeAlerts;
    final filteredSensors = sensors.where(_matchesFilter).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Fire & Smoke')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SafetyHero(
              activeAlerts: alertProvider.activeSafetyAlerts.length,
              smokeAlerts: alertProvider.activeSmokeCount,
              gasAlerts: alertProvider.activeGasLeakCount,
              onlineSensors: sensors
                  .where((d) => d.status == DeviceStatus.online)
                  .length,
              totalSensors: sensors.length,
            ),
            const SizedBox(height: 16),
            _EmergencyGuidanceCard(
              hasActiveAlert: alertProvider.activeSafetyAlerts.isNotEmpty,
            ),
            const SizedBox(height: 20),
            const Text(
              'Sensor Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _FilterBar(
              selected: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 12),
            if (filteredSensors.isEmpty)
              _EmptySafetyState(hasAnySensor: sensors.isNotEmpty)
            else
              ...filteredSensors.map(
                (device) => _SafetySensorCard(
                  device: device,
                  telemetry: deviceProvider.telemetryFor(device.deviceId),
                  latestAlert: _latestAlertFor(alerts, device.deviceId),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Recent Safety Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              const _NoAlertCard()
            else
              ...alerts
                  .take(6)
                  .map(
                    (alert) => _SafetyAlertTile(
                      alert: alert,
                      canAcknowledge:
                          !alert.acknowledged &&
                          (user?.role.canAcknowledgeAlerts ?? false),
                      onAcknowledge: () => context
                          .read<AlertProvider>()
                          .acknowledge(alert, user?.name ?? 'You'),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasAlert
              ? const [Color(0xFF7F1D1D), Color(0xFFDC2626)]
              : const [Color(0xFF064E3B), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasAlert
                      ? Icons.local_fire_department_rounded
                      : Icons.shield_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasAlert ? 'Safety attention needed' : 'Fire safety normal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasAlert
                ? '$activeAlerts active fire/gas alert${activeAlerts == 1 ? '' : 's'} need review.'
                : 'No active smoke or gas alerts right now.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _heroMetric('Smoke', smokeAlerts),
              const SizedBox(width: 10),
              _heroMetric('Gas', gasAlerts),
              const SizedBox(width: 10),
              _heroMetric('Online', '$onlineSensors/$totalSensors'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, Object value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyGuidanceCard extends StatelessWidget {
  final bool hasActiveAlert;
  const _EmergencyGuidanceCard({required this.hasActiveAlert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveAlert
              ? AppColors.critical.withValues(alpha: 0.5)
              : AppColors.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasActiveAlert
                ? Icons.priority_high_rounded
                : Icons.fact_check_outlined,
            color: hasActiveAlert ? AppColors.critical : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasActiveAlert
                  ? 'Check the alert location immediately, verify the sensor, and acknowledge only after the safety team has reviewed it.'
                  : 'Review this panel during daily checks. Offline safety sensors should be fixed before adding new automation rules.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _SafetyFilter selected;
  final ValueChanged<_SafetyFilter> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All', _SafetyFilter.all),
          _chip('Smoke', _SafetyFilter.smoke),
          _chip('Gas', _SafetyFilter.gas),
          _chip('Offline', _SafetyFilter.offline),
        ],
      ),
    );
  }

  Widget _chip(String label, _SafetyFilter value) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onChanged(value),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        side: const BorderSide(color: AppColors.divider),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SafetySensorCard extends StatelessWidget {
  final Device device;
  final Telemetry? telemetry;
  final AppAlert? latestAlert;

  const _SafetySensorCard({
    required this.device,
    required this.telemetry,
    required this.latestAlert,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveAlert = latestAlert != null && !latestAlert!.acknowledged;
    final statusColor = hasActiveAlert
        ? AppColors.critical
        : device.status == DeviceStatus.online
        ? AppColors.success
        : AppColors.textSecondary;
    final df = DateFormat('MMM d, h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${device.type.label} • ${device.zone}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: hasActiveAlert
                    ? 'Alert'
                    : device.status == DeviceStatus.online
                    ? 'Online'
                    : device.status.name,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ReadingChip(
                label: 'Smoke',
                value: telemetry?.smoke == 1 ? 'Detected' : 'Clear',
                color: telemetry?.smoke == 1
                    ? AppColors.critical
                    : AppColors.success,
              ),
              if (telemetry?.gasPpm != null)
                _ReadingChip(
                  label: 'Gas',
                  value: '${telemetry!.gasPpm!.toStringAsFixed(0)} ppm',
                  color: telemetry!.gasPpm! >= 500
                      ? AppColors.critical
                      : AppColors.success,
                ),
              if (telemetry?.temperature != null)
                _ReadingChip(
                  label: 'Temp',
                  value: '${telemetry!.temperature!.toStringAsFixed(1)}°C',
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Last heartbeat: ${df.format(device.lastHeartbeat)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (latestAlert != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SeverityBadge(severity: latestAlert!.severity),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    latestAlert!.acknowledged
                        ? 'Last alert acknowledged'
                        : latestAlert!.alertType.label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData get _icon => device.type == DeviceType.gasSensor
      ? Icons.gas_meter_rounded
      : Icons.smoke_free_rounded;
}

class _SafetyAlertTile extends StatelessWidget {
  final AppAlert alert;
  final bool canAcknowledge;
  final VoidCallback onAcknowledge;

  const _SafetyAlertTile({
    required this.alert,
    required this.canAcknowledge,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, h:mm a');
    final color = AppTheme.severityColor(alert.severity.label);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.acknowledged
              ? AppColors.divider
              : color.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeverityBadge(severity: alert.severity),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.alertType.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (alert.acknowledged)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.location,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            df.format(alert.timestamp),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (alert.value != null && alert.threshold != null) ...[
            const SizedBox(height: 4),
            Text(
              'Value ${alert.value!.toStringAsFixed(0)} / threshold ${alert.threshold!.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (canAcknowledge) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAcknowledge,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Acknowledge Safety Alert'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReadingChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        hasAnySensor
            ? 'No sensors match this filter.'
            : 'No fire or gas sensors found. Add Smoke Sensor or Gas Sensor devices from a room.',
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
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
