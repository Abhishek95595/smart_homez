import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/device.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_state_widgets.dart';
import '../../widgets/property_management_widgets.dart';
import '../properties/floors_screen.dart';
import '../properties/homes_screen.dart';
import '../properties/management_dialogs.dart';
import '../properties/rooms_screen.dart';
import 'device_detail_screen.dart';
import 'device_history_screen.dart';

class DevicesScreen extends StatelessWidget {
  final String title;
  final String? buildingId;
  final String? towerId;
  final String? flatId;
  final String? zone;
  final String? propertyId;
  final String? floorId;
  final String? roomId;
  final String? roomName;

  const DevicesScreen({
    super.key,
    this.title = 'Devices',
    this.buildingId,
    this.towerId,
    this.flatId,
    this.zone,
    this.propertyId,
    this.floorId,
    this.roomId,
    this.roomName,
  });

  IconData _iconFor(DeviceType type) {
    switch (type) {
      case DeviceType.light:
        return Icons.lightbulb_rounded;
      case DeviceType.fan:
        return Icons.mode_fan_off_rounded;
      case DeviceType.ac:
        return Icons.ac_unit_rounded;
      case DeviceType.pump:
        return Icons.water_rounded;
      case DeviceType.scene:
        return Icons.auto_awesome_rounded;
      case DeviceType.smokeSensor:
        return Icons.local_fire_department_rounded;
      case DeviceType.gasSensor:
        return Icons.propane_tank_rounded;
      case DeviceType.waterLevelSensor:
        return Icons.waves_rounded;
      case DeviceType.energyMeter:
        return Icons.speed_rounded;
    }
  }

  Future<void> _addDevice(BuildContext context) async {
    final provider = context.read<DeviceProvider>();
    final propertyProvider = context.read<PropertyProvider>();
    final hasFixedLocation =
        propertyId != null &&
        floorId != null &&
        roomId != null &&
        roomName != null;
    final result = await showDeviceForm(
      context,
      nameExists: (value) => provider.deviceNameExists(roomId ?? '', value),
      macExists: provider.macAddressExists,
      showLocationFields: !hasFixedLocation,
      properties: propertyProvider.properties,
      floors: propertyProvider.floors,
      rooms: propertyProvider.rooms,
      initialPropertyId: propertyId,
      initialFloorId: floorId,
      initialRoomId: roomId,
    );
    if (result == null || !context.mounted) return;
    await provider.addDevice(
      type: result.type,
      name: result.name,
      macAddress: result.macAddress,
      propertyId: propertyId ?? result.propertyId,
      floorId: floorId ?? result.floorId,
      roomId: roomId ?? result.roomId,
      roomName: roomName ?? result.roomName,
    );
  }

  Future<void> _editDevice(BuildContext context, Device device) async {
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

  Future<void> _deleteDevice(BuildContext context, Device device) async {
    final approved = await confirmDelete(
      context,
      title: 'Delete ${device.name}?',
      message: 'This device will be permanently removed from the room.',
    );
    if (!approved || !context.mounted) return;
    await context.read<DeviceProvider>().deleteDevice(device.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final visibleDevices = roomId == null
        ? deviceProvider.visibleDevicesAt(
            user,
            buildingId: buildingId,
            towerId: towerId,
            flatId: flatId,
            zone: zone,
          )
        : deviceProvider
              .visibleDevices(user)
              .where((device) => device.roomId == roomId)
              .toList();
    final propertyProvider = context.watch<PropertyProvider>();
    final floor = floorId == null ? null : propertyProvider.floorById(floorId!);
    final property = propertyId == null
        ? null
        : propertyProvider.propertyById(propertyId!);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDevice(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Device'),
      ),
      body: SafeArea(
        top: false,
        child: deviceProvider.isLoading
            ? const AppLoadingState(message: 'Loading devices…')
            : deviceProvider.loadError != null && deviceProvider.devices.isEmpty
            ? AppStateCard.error(
                title: 'Could not load devices',
                message: deviceProvider.loadError!,
                actionLabel: 'Retry',
                onAction: () => context.read<DeviceProvider>().reload(),
              )
            : _DeviceResults(
                devices: visibleDevices,
                user: user,
                loadError: deviceProvider.loadError,
                emptyMessage: roomId == null && zone == null
                    ? 'No devices visible for your role'
                    : 'No devices connected to ${roomName ?? zone}',
                breadcrumbs: roomId == null
                    ? const []
                    : [
                        HierarchyCrumb(
                          'Properties',
                          onTap: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomesScreen(),
                            ),
                            (route) => route.isFirst,
                          ),
                        ),
                        HierarchyCrumb(
                          property?.name ?? 'Property',
                          onTap: property == null
                              ? null
                              : () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FloorsScreen(propertyId: property.id),
                                  ),
                                ),
                        ),
                        HierarchyCrumb(
                          floor?.name ?? 'Floor',
                          onTap: floor == null
                              ? null
                              : () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RoomsScreen(floorId: floor.id),
                                  ),
                                ),
                        ),
                        HierarchyCrumb(roomName ?? 'Room'),
                      ],
                iconFor: _iconFor,
                onEdit: (device) => _editDevice(context, device),
                onDelete: (device) => _deleteDevice(context, device),
              ),
      ),
    );
  }
}

enum _DeviceFilter { all, online, offline }

class _DeviceResults extends StatefulWidget {
  final List<Device> devices;
  final AppUser? user;
  final String? loadError;
  final String emptyMessage;
  final List<HierarchyCrumb> breadcrumbs;
  final IconData Function(DeviceType type) iconFor;
  final ValueChanged<Device>? onEdit;
  final ValueChanged<Device>? onDelete;

  const _DeviceResults({
    required this.devices,
    required this.user,
    this.loadError,
    required this.emptyMessage,
    required this.breadcrumbs,
    required this.iconFor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DeviceResults> createState() => _DeviceResultsState();
}

class _DeviceResultsState extends State<_DeviceResults> {
  String _query = '';
  _DeviceFilter _filter = _DeviceFilter.all;

  @override
  Widget build(BuildContext context) {
    final devices =
        widget.devices.where((device) {
          final matchesQuery =
              _query.isEmpty ||
              device.name.toLowerCase().contains(_query.toLowerCase()) ||
              device.type.label.toLowerCase().contains(_query.toLowerCase());
          final matchesStatus = switch (_filter) {
            _DeviceFilter.all => true,
            _DeviceFilter.online => device.status == DeviceStatus.online,
            _DeviceFilter.offline => device.status != DeviceStatus.online,
          };
          return matchesQuery && matchesStatus;
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    final zones = devices.map((device) => device.zone).toSet().toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (widget.breadcrumbs.isNotEmpty) ...[
          HierarchyBreadcrumbs(items: widget.breadcrumbs),
          const SizedBox(height: 8),
        ],
        TextField(
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: const InputDecoration(
            hintText: 'Search devices or types',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _DeviceFilter.values
              .map(
                (filter) => ChoiceChip(
                  label: Text(switch (filter) {
                    _DeviceFilter.all => 'All',
                    _DeviceFilter.online => 'Online',
                    _DeviceFilter.offline => 'Offline',
                  }),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        if (widget.loadError != null) ...[
          AppStateCard.error(
            title: 'Local storage issue',
            message: widget.loadError!,
          ),
          const SizedBox(height: 10),
        ],
        if (widget.devices.isEmpty)
          _DeviceMessage(widget.emptyMessage)
        else if (devices.isEmpty)
          const _DeviceMessage('No devices match your search or filter.')
        else
          for (final zone in zones) ...[
            Text(
              zone,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...devices
                .where((device) => device.zone == zone)
                .map(
                  (device) => _DeviceCard(
                    device: device,
                    icon: widget.iconFor(device.type),
                    user: widget.user,
                    onEdit: widget.onEdit == null
                        ? null
                        : () => widget.onEdit?.call(device),
                    onDelete: widget.onDelete == null
                        ? null
                        : () => widget.onDelete?.call(device),
                  ),
                ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _DeviceMessage extends StatelessWidget {
  final String message;

  const _DeviceMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: AppStateCard.empty(title: 'No devices found', message: message),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final IconData icon;
  final AppUser? user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DeviceCard({
    required this.device,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final controllable =
        device.type.isControllable &&
        deviceProvider.canControlDevice(device, user);
    final telemetry = deviceProvider.telemetryFor(device.deviceId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceDetailScreen(deviceId: device.deviceId),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color:
                            (device.isOn
                                    ? AppColors.primary
                                    : AppColors.textSecondary)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: device.isOn
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: device.status == DeviceStatus.online
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                device.status == DeviceStatus.online
                                    ? 'Online'
                                    : 'Offline',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (telemetry?.gasPpm != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${telemetry!.gasPpm!.toStringAsFixed(0)} ppm',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              if (telemetry?.power != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${telemetry!.power!.toStringAsFixed(0)} W',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (controllable)
                      Switch(
                        value: device.isOn,
                        onChanged: (_) =>
                            context.read<DeviceProvider>().toggleDevice(device),
                      )
                    else if (device.type.isControllable)
                      Icon(
                        device.isOn
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        color: AppColors.textSecondary,
                      )
                    else
                      const Icon(
                        Icons.sensors_rounded,
                        color: AppColors.textSecondary,
                      ),
                    if (onEdit != null && onDelete != null)
                      PopupMenuButton<String>(
                        tooltip: 'Device actions',
                        onSelected: (value) {
                          if (value == 'history') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeviceHistoryScreen(
                                  deviceId: device.deviceId,
                                ),
                              ),
                            );
                          }
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') onDelete?.call();
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
                            value: 'edit',
                            child: Text('Edit device'),
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
                if (controllable &&
                    device.isOn &&
                    device.dimLevel != null &&
                    (device.type == DeviceType.fan ||
                        device.type == DeviceType.ac)) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      Expanded(
                        child: Slider(
                          value: device.dimLevel!,
                          min: 0,
                          max: device.type == DeviceType.ac ? 30 : 100,
                          onChanged: (v) => context
                              .read<DeviceProvider>()
                              .setDimLevel(device, v),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          device.dimLevel!.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
