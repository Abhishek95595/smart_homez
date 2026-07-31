import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property_hierarchy.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_state_widgets.dart';
import '../../widgets/property_management_widgets.dart';
import '../devices/devices_screen.dart';
import 'floors_screen.dart';
import 'homes_screen.dart';
import 'management_dialogs.dart';

class RoomsScreen extends StatelessWidget {
  final String? floorId;

  const RoomsScreen({super.key, this.floorId});

  Future<void> _add(BuildContext context, ManagedFloor floor) async {
    final provider = context.read<PropertyProvider>();
    final result = await showRoomForm(
      context,
      nameExists: (name) => provider.roomNameExists(floor.id, name),
    );
    if (result == null || !context.mounted) return;
    await provider.addRoom(
      floorId: floor.id,
      name: result.name,
      type: result.type,
    );
  }

  Future<void> _edit(BuildContext context, ManagedRoom room) async {
    final provider = context.read<PropertyProvider>();
    final result = await showRoomForm(
      context,
      room: room,
      nameExists: (name) =>
          provider.roomNameExists(room.floorId, name, excludingId: room.id),
    );
    if (result == null || !context.mounted) return;
    final resolvedName = result.name.trim().isEmpty
        ? room.name
        : result.name.trim();
    await provider.updateRoom(room, name: resolvedName, type: result.type);
    if (!context.mounted) return;
    await context.read<DeviceProvider>().renameRoom(room.id, resolvedName);
  }

  Future<void> _delete(BuildContext context, ManagedRoom room) async {
    final approved = await confirmDelete(
      context,
      title: 'Delete ${room.name}?',
      message: 'This will permanently delete the room and every device in it.',
    );
    if (!approved || !context.mounted) return;
    await context.read<DeviceProvider>().deleteDevicesForRoom(room.id);
    if (!context.mounted) return;
    await context.read<PropertyProvider>().deleteRoom(room.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();
    if (provider.isLoading) {
      return const Scaffold(body: AppLoadingState(message: 'Loading rooms…'));
    }
    if (provider.loadError != null && provider.floors.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rooms')),
        body: AppStateCard.error(
          title: 'Could not load rooms',
          message: provider.loadError!,
          actionLabel: 'Retry',
          onAction: () => context.read<PropertyProvider>().reload(),
        ),
      );
    }

    final floor = floorId == null
        ? provider.floors.firstOrNull
        : provider.floorById(floorId!);
    if (floor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rooms')),
        body: const Center(
          child: Text(
            'Add a floor before adding rooms.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final property = provider.propertyById(floor.propertyId);
    final rooms = provider.roomsFor(floor.id);
    return Scaffold(
      appBar: AppBar(title: Text('${floor.name} Rooms')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, floor),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Room'),
      ),
      body: SearchableManagementList<ManagedRoom>(
        items: rooms,
        searchHint: 'Search rooms',
        emptyMessage: 'No rooms yet. Tap Add Room to create the first room.',
        noResultsMessage: 'No room matches your search.',
        matches: (room, query) =>
            query.isEmpty ||
            room.name.toLowerCase().contains(query.toLowerCase()) ||
            room.type.toLowerCase().contains(query.toLowerCase()),
        header: [
          HierarchyBreadcrumbs(
            items: [
              HierarchyCrumb(
                'Properties',
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomesScreen()),
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
                          builder: (_) => FloorsScreen(propertyId: property.id),
                        ),
                      ),
              ),
              HierarchyCrumb(floor.name),
            ],
          ),
          const SizedBox(height: 8),
        ],
        itemBuilder: (context, room) {
          final devices = context.watch<DeviceProvider>().devicesForRoom(
            room.id,
          );
          return _RoomCard(
            property: property,
            floor: floor,
            room: room,
            deviceCount: devices.length,
            onlineCount: devices
                .where((item) => item.status.name == 'online')
                .length,
            onEdit: () => _edit(context, room),
            onDelete: () => _delete(context, room),
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final ManagedProperty? property;
  final ManagedFloor floor;
  final ManagedRoom room;
  final int deviceCount;
  final int onlineCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RoomCard({
    required this.property,
    required this.floor,
    required this.room,
    required this.deviceCount,
    required this.onlineCount,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get _icon {
    switch (room.type) {
      case 'Kitchen':
        return Icons.kitchen_outlined;
      case 'Bedroom':
        return Icons.bed_outlined;
      case 'Living Room':
        return Icons.weekend_outlined;
      case 'Bathroom':
        return Icons.bathroom_outlined;
      case 'Office':
        return Icons.desk_outlined;
      case 'Garage':
        return Icons.garage_outlined;
      default:
        return Icons.meeting_room_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DevicesScreen(
              title: '${room.name} Devices',
              propertyId: property?.id,
              floorId: floor.id,
              roomId: room.id,
              roomName: room.name,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.type,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      deviceCount == 0
                          ? 'No devices connected'
                          : '$onlineCount of $deviceCount devices online',
                      style: TextStyle(
                        color: deviceCount == 0
                            ? AppColors.textSecondary
                            : AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null && onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'Room actions',
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit room')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete room',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
