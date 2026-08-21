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
  final String? propertyName;
  final String? floorName;

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
    this.propertyName,
    this.floorName,
  });

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

  Future<void> _moveDevice(BuildContext context, Device device) async {
    final provider = context.read<DeviceProvider>();
    final propertyProvider = context.read<PropertyProvider>();
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
      showLocationFields: true,
      properties: propertyProvider.properties,
      floors: propertyProvider.floors,
      rooms: propertyProvider.rooms,
    );

    if (result == null || !context.mounted) return;

    if (result.roomId != device.roomId) {
      await provider.moveDevice(device, roomId: result.roomId);
    } else if (result.floorId != device.floorId) {
      await provider.moveDevice(device, floorId: result.floorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final rawVisibleDevices =
        (propertyName != null && floorName != null && roomName != null)
        ? deviceProvider.visibleDevicesForRoom(
            user,
            propertyName: propertyName!,
            floorName: floorName!,
            roomName: roomName!,
          )
        : (propertyName != null && floorName != null)
        ? deviceProvider.visibleDevicesForFloor(
            user,
            propertyName: propertyName!,
            floorName: floorName!,
          )
        : roomId == null
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
    final visibleDevices = rawVisibleDevices;
    final propertyProvider = context.watch<PropertyProvider>();
    final floor = floorId == null ? null : propertyProvider.floorById(floorId!);
    final property = propertyId == null
        ? null
        : propertyProvider.propertyById(propertyId!);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'SMART IOT HARDWARE MATRIX',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00A38E),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3500A38E),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          onPressed: () => _addDevice(context),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Add Device',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ),
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
            : _GenZDeviceDashboard(
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
                onEdit: (device) => _editDevice(context, device),
                onDelete: (device) => _deleteDevice(context, device),
                onMove: (device) => _moveDevice(context, device),
              ),
      ),
    );
  }
}

enum _DeviceFilter { all, on, lights, climate, fans, sensors, offline }

class _GenZDeviceDashboard extends StatefulWidget {
  final List<Device> devices;
  final AppUser? user;
  final String? loadError;
  final String emptyMessage;
  final List<HierarchyCrumb> breadcrumbs;
  final ValueChanged<Device>? onEdit;
  final ValueChanged<Device>? onDelete;
  final ValueChanged<Device>? onMove;

  const _GenZDeviceDashboard({
    required this.devices,
    required this.user,
    this.loadError,
    required this.emptyMessage,
    required this.breadcrumbs,
    required this.onEdit,
    required this.onDelete,
    this.onMove,
  });

  @override
  State<_GenZDeviceDashboard> createState() => _GenZDeviceDashboardState();
}

class _GenZDeviceDashboardState extends State<_GenZDeviceDashboard> {
  String _query = '';
  _DeviceFilter _filter = _DeviceFilter.all;

  @override
  Widget build(BuildContext context) {
    final activeCount = widget.devices.where((d) => d.isOn).length;
    final onlineCount = widget.devices
        .where((d) => d.status == DeviceStatus.online)
        .length;

    final filteredDevices =
        widget.devices.where((device) {
          final matchesQuery =
              _query.isEmpty ||
              device.name.toLowerCase().contains(_query.toLowerCase()) ||
              device.type.label.toLowerCase().contains(_query.toLowerCase()) ||
              (device.roomName ?? '').toLowerCase().contains(
                _query.toLowerCase(),
              );

          final matchesFilter = switch (_filter) {
            _DeviceFilter.all => true,
            _DeviceFilter.on => device.isOn,
            _DeviceFilter.lights => device.type == DeviceType.light,
            _DeviceFilter.climate => device.type == DeviceType.ac,
            _DeviceFilter.fans => device.type == DeviceType.fan,
            _DeviceFilter.sensors => device.type.isSensorOnly,
            _DeviceFilter.offline => device.status != DeviceStatus.online,
          };

          return matchesQuery && matchesFilter;
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    // Grouping by room
    final Map<String, List<Device>> grouped = {};
    for (final dev in filteredDevices) {
      final room = dev.roomName?.trim().isNotEmpty == true
          ? dev.roomName!
          : 'Unassigned Space';
      grouped.putIfAbsent(room, () => []).add(dev);
    }
    final sortedRooms = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Unassigned Space') return 1;
        if (b == 'Unassigned Space') return -1;
        return a.compareTo(b);
      });

    final bool isWide = MediaQuery.of(context).size.width > 600;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        if (widget.breadcrumbs.isNotEmpty) ...[
          HierarchyBreadcrumbs(items: widget.breadcrumbs),
          const SizedBox(height: 12),
        ],

        // Gen-Z Hero Device Status Header
        _HeroDeviceMatrix(
          totalDevices: widget.devices.length,
          activeDevices: activeCount,
          onlineDevices: onlineCount,
          onTurnAllOff: () async {
            final provider = context.read<DeviceProvider>();
            for (final d in widget.devices) {
              if (d.isOn &&
                  d.type.isControllable &&
                  provider.canControlDevice(d, widget.user)) {
                await provider.toggleDevice(d);
              }
            }
          },
        ),
        const SizedBox(height: 14),

        // Search Input
        _DeviceSearchInput(
          query: _query,
          onChanged: (val) => setState(() => _query = val.trim()),
          onClear: () => setState(() => _query = ''),
        ),
        const SizedBox(height: 12),

        // Horizontal Category Filter Rail
        _FilterRail(
          selected: _filter,
          onSelected: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 18),

        if (widget.loadError != null) ...[
          AppStateCard.error(
            title: 'Connection error',
            message: widget.loadError!,
          ),
          const SizedBox(height: 16),
        ],

        if (widget.devices.isEmpty)
          _DeviceEmptyState(message: widget.emptyMessage)
        else if (filteredDevices.isEmpty)
          const _DeviceEmptyState(
            message: 'No smart devices found matching current filters.',
          )
        else
          ...sortedRooms.expand((room) {
            final roomDevices = grouped[room]!;
            final roomOnCount = roomDevices.where((d) => d.isOn).length;

            return [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A38E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        room == 'Unassigned Space'
                            ? Icons.grid_view_rounded
                            : Icons.meeting_room_rounded,
                        size: 16,
                        color: const Color(0xFF00A38E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      room,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: roomOnCount > 0
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$roomOnCount/${roomDevices.length} Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: roomOnCount > 0
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isWide)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: roomDevices.length,
                  itemBuilder: (context, i) => _GenZDeviceCard(
                    device: roomDevices[i],
                    user: widget.user,
                    onEdit: widget.onEdit == null
                        ? null
                        : () => widget.onEdit?.call(roomDevices[i]),
                    onDelete: widget.onDelete == null
                        ? null
                        : () => widget.onDelete?.call(roomDevices[i]),
                    onMove: widget.onMove == null
                        ? null
                        : () => widget.onMove?.call(roomDevices[i]),
                  ),
                )
              else
                ...roomDevices.map(
                  (device) => _GenZDeviceCard(
                    device: device,
                    user: widget.user,
                    onEdit: widget.onEdit == null
                        ? null
                        : () => widget.onEdit?.call(device),
                    onDelete: widget.onDelete == null
                        ? null
                        : () => widget.onDelete?.call(device),
                    onMove: widget.onMove == null
                        ? null
                        : () => widget.onMove?.call(device),
                  ),
                ),
              const SizedBox(height: 14),
            ];
          }),
      ],
    );
  }
}

class _HeroDeviceMatrix extends StatelessWidget {
  final int totalDevices;
  final int activeDevices;
  final int onlineDevices;
  final VoidCallback onTurnAllOff;

  const _HeroDeviceMatrix({
    required this.totalDevices,
    required this.activeDevices,
    required this.onlineDevices,
    required this.onTurnAllOff,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x8010B981),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE SPACE MATRIX',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00C9A7),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$activeDevices of $totalDevices Running',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeDevices > 0)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTurnAllOff,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.power_settings_new_rounded,
                            size: 15,
                            color: Color(0xFFFCA5A5),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Turn All Off',
                            style: TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _heroStat(
                'Online Network',
                '$onlineDevices',
                Icons.wifi_tethering_rounded,
                const Color(0xFF00C9A7),
              ),
              const SizedBox(width: 10),
              _heroStat(
                'Active Loads',
                '$activeDevices',
                Icons.bolt_rounded,
                const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              _heroStat(
                'Total Hardware',
                '$totalDevices',
                Icons.hub_rounded,
                const Color(0xFF60A5FA),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
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

class _DeviceSearchInput extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _DeviceSearchInput({
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Search device, type or room...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF00A38E),
            size: 20,
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  final _DeviceFilter selected;
  final ValueChanged<_DeviceFilter> onSelected;

  const _FilterRail({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const filters = [
      {
        'f': _DeviceFilter.all,
        'label': 'All Devices',
        'icon': Icons.apps_rounded,
      },
      {'f': _DeviceFilter.on, 'label': 'Active ON', 'icon': Icons.bolt_rounded},
      {
        'f': _DeviceFilter.lights,
        'label': 'Lights',
        'icon': Icons.lightbulb_rounded,
      },
      {
        'f': _DeviceFilter.climate,
        'label': 'Climate',
        'icon': Icons.ac_unit_rounded,
      },
      {'f': _DeviceFilter.fans, 'label': 'Fans', 'icon': Icons.cyclone_rounded},
      {
        'f': _DeviceFilter.sensors,
        'label': 'Sensors',
        'icon': Icons.sensors_rounded,
      },
      {
        'f': _DeviceFilter.offline,
        'label': 'Offline',
        'icon': Icons.cloud_off_rounded,
      },
    ];

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((item) {
          final f = item['f'] as _DeviceFilter;
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = selected == f;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00A38E)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x2500A38E),
                            blurRadius: 8,
                            offset: Offset(0, 3),
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
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF334155),
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

class _GenZDeviceCard extends StatelessWidget {
  final Device device;
  final AppUser? user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMove;

  const _GenZDeviceCard({
    required this.device,
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final controllable =
        device.type.isControllable &&
        deviceProvider.canControlDevice(device, user);
    final isUpdating = deviceProvider.isUpdating(device.deviceId);
    final bool isOn = device.isOn;

    final theme = _getDeviceTheme(device.type, isOn);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isOn ? theme.cardBg : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOn ? theme.borderColor : const Color(0xFFE2E8F0),
          width: isOn ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOn ? theme.glowColor : const Color(0x04000000),
            blurRadius: isOn ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceDetailScreen(deviceId: device.deviceId),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Squircle Icon Avatar with dynamic glow
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isOn
                            ? LinearGradient(
                                colors: theme.iconGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isOn ? null : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isOn
                            ? [
                                BoxShadow(
                                  color: theme.iconGradient.first.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        theme.icon,
                        color: isOn ? Colors.white : const Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Device Name, Room, Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                              color: isOn
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6.5,
                                height: 6.5,
                                decoration: BoxDecoration(
                                  color: device.status == DeviceStatus.online
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                device.status == DeviceStatus.online
                                    ? (isOn ? 'ACTIVE' : 'STANDBY')
                                    : 'OFFLINE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: device.status == DeviceStatus.online
                                      ? (isOn
                                            ? theme.iconGradient.first
                                            : const Color(0xFF64748B))
                                      : const Color(0xFF94A3B8),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              if (device.roomName != null &&
                                  device.roomName!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                const Text(
                                  '•',
                                  style: TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    device.roomName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tactile Gen-Z Power Button / Sensor Badge
                    if (controllable)
                      GestureDetector(
                        onTap: () =>
                            context.read<DeviceProvider>().toggleDevice(device),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: isOn
                                ? LinearGradient(
                                    colors: theme.iconGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isOn ? null : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isOn
                                  ? Colors.transparent
                                  : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: isOn
                                ? [
                                    BoxShadow(
                                      color: theme.iconGradient.first
                                          .withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.power_settings_new_rounded,
                              size: 22,
                              color: isOn
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      )
                    else if (device.type.isSensorOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.radar_rounded,
                              size: 12,
                              color: Color(0xFF8B5CF6),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'SENSOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),

                    // 3-dot popup menu
                    if (onEdit != null && onDelete != null) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        padding: EdgeInsets.zero,
                        offset: const Offset(0, 35),
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
                          if (value == 'move') onMove?.call();
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') onDelete?.call();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'history',
                            child: ListTile(
                              leading: Icon(Icons.history_rounded),
                              title: Text('Activity History'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'move',
                            child: ListTile(
                              leading: Icon(Icons.drive_file_move_outlined),
                              title: Text('Move Room'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit Info'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.danger,
                              ),
                              title: Text(
                                'Delete',
                                style: TextStyle(color: AppColors.danger),
                              ),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                // Inline Slider Control for Fan / AC when ON
                if (controllable &&
                    isOn &&
                    device.dimLevel != null &&
                    (device.type == DeviceType.fan ||
                        device.type == DeviceType.light ||
                        device.type == DeviceType.ac)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          device.type == DeviceType.fan
                              ? Icons.cyclone_rounded
                              : device.type == DeviceType.ac
                                  ? Icons.thermostat_rounded
                                  : Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: theme.iconGradient.first,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              activeTrackColor: theme.iconGradient.first,
                              inactiveTrackColor: const Color(0xFFE2E8F0),
                              thumbColor: theme.iconGradient.first,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: device.dimLevel!,
                              min: 0,
                              max: device.type == DeviceType.ac ? 30 : 100,
                              onChanged: isUpdating
                                  ? null
                                  : (v) => context
                                        .read<DeviceProvider>()
                                        .setDimLevel(device, v),
                            ),
                          ),
                        ),
                        Text(
                          '${device.dimLevel!.toStringAsFixed(0)}${device.type == DeviceType.ac ? '°C' : '%'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: theme.iconGradient.first,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _DeviceCardTheme _getDeviceTheme(DeviceType type, bool isOn) {
    switch (type) {
      case DeviceType.light:
        return _DeviceCardTheme(
          icon: Icons.lightbulb_rounded,
          iconGradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          cardBg: const Color(0xFFFFFDF5),
          borderColor: const Color(0xFFFDE68A),
          glowColor: const Color(0x18F59E0B),
        );
      case DeviceType.ac:
        return _DeviceCardTheme(
          icon: Icons.ac_unit_rounded,
          iconGradient: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
          cardBg: const Color(0xFFF0FDFE),
          borderColor: const Color(0xFFA5F3FC),
          glowColor: const Color(0x1806B6D4),
        );
      case DeviceType.fan:
        return _DeviceCardTheme(
          icon: Icons.cyclone_rounded,
          iconGradient: const [Color(0xFF00C9A7), Color(0xFF00A38E)],
          cardBg: const Color(0xFFF0FDFB),
          borderColor: const Color(0xFF99F6E4),
          glowColor: const Color(0x1800C9A7),
        );
      case DeviceType.pump:
        return _DeviceCardTheme(
          icon: Icons.water_rounded,
          iconGradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          cardBg: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
          glowColor: const Color(0x183B82F6),
        );
      case DeviceType.smokeSensor:
        return _DeviceCardTheme(
          icon: Icons.local_fire_department_rounded,
          iconGradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
          cardBg: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          glowColor: const Color(0x18EF4444),
        );
      case DeviceType.gasSensor:
        return _DeviceCardTheme(
          icon: Icons.gas_meter_rounded,
          iconGradient: const [Color(0xFFEA580C), Color(0xFFC2410C)],
          cardBg: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFFED7AA),
          glowColor: const Color(0x18EA580C),
        );
      case DeviceType.waterLevelSensor:
        return _DeviceCardTheme(
          icon: Icons.waves_rounded,
          iconGradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
          cardBg: const Color(0xFFF0F9FF),
          borderColor: const Color(0xFFBAE6FD),
          glowColor: const Color(0x180284C7),
        );
      case DeviceType.energyMeter:
        return _DeviceCardTheme(
          icon: Icons.speed_rounded,
          iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
          cardBg: const Color(0xFFECFDF5),
          borderColor: const Color(0xFFA7F3D0),
          glowColor: const Color(0x1810B981),
        );
      case DeviceType.scene:
        return _DeviceCardTheme(
          icon: Icons.auto_awesome_rounded,
          iconGradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          cardBg: const Color(0xFFF5F3FF),
          borderColor: const Color(0xFFDDD6FE),
          glowColor: const Color(0x188B5CF6),
        );
    }
  }
}

class _DeviceCardTheme {
  final IconData icon;
  final List<Color> iconGradient;
  final Color cardBg;
  final Color borderColor;
  final Color glowColor;

  const _DeviceCardTheme({
    required this.icon,
    required this.iconGradient,
    required this.cardBg,
    required this.borderColor,
    required this.glowColor,
  });
}

class _DeviceEmptyState extends StatelessWidget {
  final String message;

  const _DeviceEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.devices_other_rounded,
                color: Color(0xFF94A3B8),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Devices Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
