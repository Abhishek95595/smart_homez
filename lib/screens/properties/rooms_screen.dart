import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property_hierarchy.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_state_widgets.dart';
import '../devices/devices_screen.dart';
import 'floors_screen.dart';
import 'homes_screen.dart';
import 'management_dialogs.dart';

class RoomsScreen extends StatefulWidget {
  final String? homeId;
  final String? floorId;

  const RoomsScreen({super.key, this.homeId, this.floorId});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.homeId != null && widget.floorId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PropertyProvider>().fetchRoomsForFloor(
          widget.homeId!,
          widget.floorId!,
        );
      });
    }
  }

  Future<void> _add(BuildContext context, ManagedFloor floor) async {
    final provider = context.read<PropertyProvider>();
    final result = await showRoomForm(
      context,
      nameExists: (name) => provider.roomNameExists(floor.id, name),
    );
    if (result == null || !context.mounted) return;
    await provider.addRoom(
      homeId: widget.homeId ?? '',
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
      message: 'This will unassign all devices in this room.',
    );
    if (approved) {
      await context.read<PropertyProvider>().deleteRoom(room.id);
      if (context.mounted) {
        await context.read<DeviceProvider>().deleteDevicesForRoom(room.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();
    final floors = provider.floors;

    final currentFloorId =
        widget.floorId ?? (floors.isNotEmpty ? floors.first.id : '');
    final currentFloor = provider.floorById(currentFloorId);
    final rooms = provider.roomsFor(currentFloorId);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentFloor?.name ?? 'Rooms'),
        actions: [
          if (currentFloorId.isNotEmpty)
            IconButton(
              tooltip: 'View all floors',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FloorsScreen(propertyId: currentFloor?.propertyId),
                ),
              ),
              icon: const Icon(Icons.layers_outlined),
            ),
          IconButton(
            tooltip: 'View all properties',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomesScreen()),
            ),
            icon: const Icon(Icons.home_work_outlined),
          ),
        ],
      ),
      floatingActionButton: currentFloor == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(context, currentFloor),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Room'),
            ),
      body: SafeArea(
        top: false,
        child: provider.isLoading
            ? const AppLoadingState(message: 'Loading rooms…')
            : currentFloorId.isEmpty
            ? const AppStateCard.empty(
                title: 'No floors found',
                message: 'Add a floor first to manage its rooms.',
              )
            : _RoomResults(
                rooms: rooms,
                onOpen: (r) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DevicesScreen(
                      title: r.name,
                      propertyId: currentFloor?.propertyId,
                      floorId: r.floorId,
                      roomId: r.id,
                      roomName: r.name,
                    ),
                  ),
                ),
                onEdit: (r) => _edit(context, r),
                onDelete: (r) => _delete(context, r),
              ),
      ),
    );
  }
}

class _RoomResults extends StatelessWidget {
  final List<ManagedRoom> rooms;
  final ValueChanged<ManagedRoom> onOpen;
  final ValueChanged<ManagedRoom> onEdit;
  final ValueChanged<ManagedRoom> onDelete;

  const _RoomResults({
    required this.rooms,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const AppStateCard.empty(
        title: 'No rooms added',
        message: 'Add your first room or unit to this floor.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final r = rooms[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RoomCard(
            room: r,
            onTap: () => onOpen(r),
            onEdit: () => onEdit(r),
            onDelete: () => onDelete(r),
          ),
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  final ManagedRoom room;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RoomCard({
    required this.room,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final devices = deviceProvider.devicesForRoom(room.id);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
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
                      '${devices.length} devices assigned',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
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
