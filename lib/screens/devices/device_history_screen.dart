import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/device.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_state_widgets.dart';
import 'device_detail_screen.dart';

enum _HistoryFilter { all, online, attention }

class DeviceHistoryScreen extends StatefulWidget {
  final String? propertyId;
  final String? propertyName;
  final String? deviceId;

  const DeviceHistoryScreen({
    super.key,
    this.propertyId,
    this.propertyName,
    this.deviceId,
  });

  @override
  State<DeviceHistoryScreen> createState() => _DeviceHistoryScreenState();
}

class _DeviceHistoryScreenState extends State<DeviceHistoryScreen> {
  String _query = '';
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final propertyProvider = context.watch<PropertyProvider>();
    final resolvedProperty = widget.propertyId == null
        ? null
        : propertyProvider.propertyById(widget.propertyId!);
    final title = widget.deviceId != null
        ? 'Device History'
        : '${widget.propertyName ?? resolvedProperty?.name ?? 'Property'} History';

    final scopedDevices = deviceProvider.devices.where((device) {
      if (widget.deviceId != null && device.deviceId != widget.deviceId) {
        return false;
      }
      if (widget.propertyId != null && device.buildingId != widget.propertyId) {
        return false;
      }
      return true;
    }).toList();

    final filteredDevices = scopedDevices.where((device) {
      final matchesQuery =
          _query.isEmpty ||
          device.name.toLowerCase().contains(_query.toLowerCase()) ||
          device.type.label.toLowerCase().contains(_query.toLowerCase()) ||
          device.zone.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = switch (_filter) {
        _HistoryFilter.all => true,
        _HistoryFilter.online => device.status == DeviceStatus.online,
        _HistoryFilter.attention => device.status != DeviceStatus.online,
      };
      return matchesQuery && matchesFilter;
    }).toList()..sort((a, b) => b.lastHeartbeat.compareTo(a.lastHeartbeat));

    final onlineCount = scopedDevices
        .where((device) => device.status == DeviceStatus.online)
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _HistoryHero(
            totalCount: scopedDevices.length,
            onlineCount: onlineCount,
            propertyName:
                widget.propertyName ??
                resolvedProperty?.name ??
                'All registered devices',
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: const InputDecoration(
              hintText: 'Search device history',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HistoryFilter.values
                .map(
                  (filter) => ChoiceChip(
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                    label: Text(switch (filter) {
                      _HistoryFilter.all => 'All activity',
                      _HistoryFilter.online => 'Online',
                      _HistoryFilter.attention => 'Needs attention',
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'LATEST DEVICE ACTIVITY',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (scopedDevices.isEmpty)
            const AppStateCard.empty(
              title: 'No device history yet',
              message:
                  'Register a device in this property to start recording its '
                  'latest status and heartbeat.',
            )
          else if (filteredDevices.isEmpty)
            const AppStateCard.empty(
              title: 'No matching activity',
              message: 'Try another search or status filter.',
            )
          else
            ...filteredDevices.asMap().entries.map(
              (entry) => _HistoryEntry(
                device: entry.value,
                isLast: entry.key == filteredDevices.length - 1,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DeviceDetailScreen(deviceId: entry.value.deviceId),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryHero extends StatelessWidget {
  final int totalCount;
  final int onlineCount;
  final String propertyName;

  const _HistoryHero({
    required this.totalCount,
    required this.onlineCount,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171923), Color(0xFF2A2D3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2414161F),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  propertyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$onlineCount of $totalCount devices reporting online',
                  style: const TextStyle(
                    color: AppColors.sideText,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  final Device device;
  final bool isLast;
  final VoidCallback onTap;

  const _HistoryEntry({
    required this.device,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final online = device.status == DeviceStatus.online;
    final statusColor = online ? AppColors.success : AppColors.warning;
    final macLabel = device.macAddress.trim().isEmpty
        ? 'MAC not added'
        : device.macAddress;
    final zoneLabel = device.zone.trim().isEmpty ? 'Unassigned' : device.zone;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _deviceIcon(device.type),
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${device.type.label} · $zoneLabel',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$macLabel · '
                              '${DateFormat('dd MMM, hh:mm a').format(device.lastHeartbeat)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textFaint,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            online ? 'Online' : device.status.name,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 19,
                            color: AppColors.textFaint,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _deviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.light:
        return Icons.lightbulb_rounded;
      case DeviceType.fan:
        return Icons.mode_fan_off_rounded;
      case DeviceType.ac:
        return Icons.ac_unit_rounded;
      case DeviceType.pump:
        return Icons.water_rounded;
      case DeviceType.smokeSensor:
        return Icons.local_fire_department_rounded;
      case DeviceType.gasSensor:
        return Icons.propane_tank_rounded;
      case DeviceType.waterLevelSensor:
        return Icons.waves_rounded;
      case DeviceType.energyMeter:
        return Icons.speed_rounded;
      case DeviceType.scene:
        return Icons.auto_awesome_rounded;
    }
  }
}
