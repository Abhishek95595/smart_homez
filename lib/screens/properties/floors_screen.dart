import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property_hierarchy.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_state_widgets.dart';
import '../../widgets/property_management_widgets.dart';
import 'homes_screen.dart';
import 'management_dialogs.dart';
import 'rooms_screen.dart';

class FloorsScreen extends StatelessWidget {
  final String? propertyId;

  const FloorsScreen({super.key, this.propertyId});

  Future<void> _add(BuildContext context, String selectedPropertyId) async {
    final provider = context.read<PropertyProvider>();
    final result = await showFloorForm(
      context,
      floorExists: (name, level) =>
          provider.floorExists(selectedPropertyId, name: name, level: level),
    );
    if (result == null || !context.mounted) return;
    await provider.addFloor(
      propertyId: selectedPropertyId,
      name: result.name,
      level: result.level,
    );
  }

  Future<void> _edit(BuildContext context, ManagedFloor floor) async {
    final provider = context.read<PropertyProvider>();
    final result = await showFloorForm(
      context,
      floor: floor,
      floorExists: (name, level) => provider.floorExists(
        floor.propertyId,
        name: name,
        level: level,
        excludingId: floor.id,
      ),
    );
    if (result == null || !context.mounted) return;
    await provider.updateFloor(floor, name: result.name, level: result.level);
  }

  Future<void> _delete(BuildContext context, ManagedFloor floor) async {
    final approved = await confirmDelete(
      context,
      title: 'Delete ${floor.name}?',
      message:
          'This will permanently delete the floor and every room and device '
          'inside it.',
    );
    if (!approved || !context.mounted) return;
    await context.read<DeviceProvider>().deleteDevicesForFloor(floor.id);
    if (!context.mounted) return;
    await context.read<PropertyProvider>().deleteFloor(floor.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();
    if (provider.isLoading) {
      return const Scaffold(body: AppLoadingState(message: 'Loading floors…'));
    }
    if (provider.loadError != null && provider.properties.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Floors')),
        body: AppStateCard.error(
          title: 'Could not load floors',
          message: provider.loadError!,
          actionLabel: 'Retry',
          onAction: () => context.read<PropertyProvider>().reload(),
        ),
      );
    }

    final property = propertyId == null
        ? provider.properties.firstOrNull
        : provider.propertyById(propertyId!);

    if (property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Floors')),
        body: const Center(
          child: Text(
            'Add a property before adding floors.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final floors = provider.floorsFor(property.id);
    return Scaffold(
      appBar: AppBar(title: Text('${property.name} Floors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, property.id),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Floor'),
      ),
      body: SearchableManagementList<ManagedFloor>(
        items: floors,
        searchHint: 'Search floors',
        emptyMessage: 'No floors yet. Tap Add Floor to create the first floor.',
        noResultsMessage: 'No floor matches your search.',
        matches: (floor, query) =>
            query.isEmpty ||
            floor.name.toLowerCase().contains(query.toLowerCase()) ||
            floor.level.toString() == query,
        header: [
          HierarchyBreadcrumbs(
            items: [
              HierarchyCrumb(
                'Properties',
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomesScreen()),
                ),
              ),
              HierarchyCrumb(property.name),
            ],
          ),
          const SizedBox(height: 8),
        ],
        itemBuilder: (context, floor) {
          final rooms = provider.roomsFor(floor.id);
          final roomIds = rooms.map((item) => item.id).toSet();
          final deviceCount = context
              .watch<DeviceProvider>()
              .devices
              .where((item) => roomIds.contains(item.roomId))
              .length;
          return _FloorCard(
            floor: floor,
            roomCount: rooms.length,
            deviceCount: deviceCount,
            onEdit: () => _edit(context, floor),
            onDelete: () => _delete(context, floor),
          );
        },
      ),
    );
  }
}

class _FloorCard extends StatelessWidget {
  final ManagedFloor floor;
  final int roomCount;
  final int deviceCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _FloorCard({
    required this.floor,
    required this.roomCount,
    required this.deviceCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RoomsScreen(floorId: floor.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${floor.level}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      floor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$roomCount rooms • $deviceCount devices',
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
                  tooltip: 'Floor actions',
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit floor')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete floor',
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
