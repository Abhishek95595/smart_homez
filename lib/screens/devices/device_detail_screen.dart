import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/device.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../properties/management_dialogs.dart';
import 'device_history_screen.dart';

class DeviceDetailScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  Future<void> _edit(BuildContext context, Device device) async {
    final provider = context.read<DeviceProvider>();
    final result = await showDeviceForm(
      context,
      device: device,
      nameExists: (value) => provider.deviceNameExists(
        device.roomId ?? '',
        value,
        excludingId: device.deviceId,
      ),
      macExists: (value) =>
          provider.macAddressExists(value, excludingId: device.deviceId),
    );
    if (result == null || !context.mounted) return;
    await provider.updateDevice(
      device,
      type: result.type,
      name: result.name,
      macAddress: result.macAddress,
    );
  }

  Future<void> _delete(BuildContext context, Device device) async {
    final approved = await confirmDelete(
      context,
      title: 'Delete ${device.name}?',
      message: 'This device will be permanently removed.',
    );
    if (!approved || !context.mounted) return;
    await context.read<DeviceProvider>().deleteDevice(device.deviceId);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final device = provider.deviceById(deviceId);
    if (device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Details')),
        body: const Center(child: Text('This device no longer exists.')),
      );
    }

    final properties = context.watch<PropertyProvider>();
    final property = properties.propertyById(device.buildingId);
    final floor = device.floorId == null
        ? null
        : properties.floorById(device.floorId!);
    final room = device.roomId == null
        ? null
        : properties.roomById(device.roomId!);
    final telemetry = provider.telemetryFor(device.deviceId);
    final user = context.watch<AuthProvider>().currentUser;
    final controllable = provider.canControlDevice(device, user);
    final statusColor = device.status == DeviceStatus.online
        ? AppColors.success
        : AppColors.warning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Details'),
        actions: [
          IconButton(
            tooltip: 'Edit device',
            onPressed: () => _edit(context, device),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DeviceHistoryScreen(deviceId: device.deviceId),
                  ),
                );
              }
              if (value == 'delete') _delete(context, device);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text('Device history'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete device',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.devices_other_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    device.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    device.type.label,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: statusColor,
                      radius: 5,
                    ),
                    label: Text(device.status.name.toUpperCase()),
                  ),
                  if (device.type.isControllable) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(device.isOn ? 'Powered on' : 'Powered off'),
                      value: device.isOn,
                      onChanged: controllable
                          ? (value) async {
                              final bool success = await provider.toggleDevice(
                                device,
                              );

                              if (!context.mounted) return;

                              if (!success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Device command failed. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                    if (controllable &&
                        device.isOn &&
                        device.dimLevel != null &&
                        (device.type == DeviceType.fan ||
                            device.type == DeviceType.light ||
                            device.type == DeviceType.ac)) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            device.type == DeviceType.fan
                                ? Icons.cyclone_rounded
                                : device.type == DeviceType.ac
                                    ? Icons.thermostat_rounded
                                    : Icons.lightbulb_outline_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: device.dimLevel!.clamp(0, 100).toDouble(),
                              min: 0,
                              max: 100,
                              activeColor: AppColors.primary,
                              inactiveColor: const Color(0xFFE2E8F0),
                              onChanged: (value) {
                                provider.setDimLevel(device, value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            device.type == DeviceType.ac
                                ? '${device.dimLevel!.toInt()}°C'
                                : '${device.dimLevel!.toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Location',
            children: [
              _Row(
                'Property',
                property?.name ??
                    device.homeName ??
                    (device.buildingId.trim().isEmpty
                        ? 'Not assigned'
                        : device.buildingId),
              ),
              _Row('Floor', floor?.name ?? device.floorName ?? 'Not assigned'),
              _Row(
                'Room',
                room?.name ??
                    device.roomName ??
                    (device.zone == 'Unassigned'
                        ? 'Not assigned'
                        : device.zone),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Device information',
            children: [
              _Row('Device ID', device.deviceId),
              _Row(
                'MAC address',
                device.macAddress.trim().isEmpty
                    ? 'Not added'
                    : device.macAddress,
              ),
              _Row('Firmware', device.firmwareVersion),
              _Row(
                'Last active',
                DateFormat('dd MMM yyyy, hh:mm a').format(device.lastHeartbeat),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Live readings',
            children: telemetry == null
                ? const [_Row('Status', 'Waiting for telemetry…')]
                : [
                    if (telemetry.temperature != null)
                      _Row(
                        'Temperature',
                        '${telemetry.temperature!.toStringAsFixed(1)} °C',
                      ),
                    if (telemetry.gasPpm != null)
                      _Row(
                        'Gas',
                        '${telemetry.gasPpm!.toStringAsFixed(0)} ppm',
                      ),
                    if (telemetry.smoke != null)
                      _Row(
                        'Smoke',
                        telemetry.smoke == 1 ? 'Detected' : 'Clear',
                      ),
                    if (telemetry.power != null)
                      _Row('Power', '${telemetry.power!.toStringAsFixed(0)} W'),
                    if (telemetry.voltage != null)
                      _Row(
                        'Voltage',
                        '${telemetry.voltage!.toStringAsFixed(1)} V',
                      ),
                    if (telemetry.tankLevelPercent != null)
                      _Row(
                        'Tank level',
                        '${telemetry.tankLevelPercent!.toStringAsFixed(0)}%',
                      ),
                    _Row(
                      'Updated',
                      DateFormat('hh:mm:ss a').format(telemetry.timestamp),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
