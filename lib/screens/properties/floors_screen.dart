import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property_hierarchy.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_navigation_leading.dart';
import '../../widgets/app_state_widgets.dart';
import 'homes_screen.dart';
import 'management_dialogs.dart';
import 'rooms_screen.dart';

class FloorsScreen extends StatefulWidget {
  final String? propertyId;

  const FloorsScreen({super.key, this.propertyId});

  @override
  State<FloorsScreen> createState() => _FloorsScreenState();
}

class _FloorsScreenState extends State<FloorsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.propertyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PropertyProvider>().fetchFloorsForHome(widget.propertyId!);
      });
    }
  }

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
      message: 'This will remove all rooms and devices on this floor.',
    );
    if (approved && context.mounted) {
      final propertyProvider = context.read<PropertyProvider>();
      final deviceProvider = context.read<DeviceProvider>();
      await propertyProvider.deleteFloor(floor.id);
      await deviceProvider.deleteDevicesForFloor(floor.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();
    final properties = provider.properties;

    final currentPropertyId =
        widget.propertyId ?? (properties.isNotEmpty ? properties.first.id : '');

    final currentProperty = provider.propertyById(currentPropertyId);
    final floors = provider.floorsFor(currentPropertyId);

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => AppNavigationLeading.drawer(
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(currentProperty?.name ?? 'Floors'),
        actions: [
          if (currentPropertyId.isNotEmpty)
            IconButton(
              tooltip: 'Manage properties',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomesScreen()),
              ),
              icon: const Icon(Icons.home_work_outlined),
            ),
        ],
      ),
      floatingActionButton: currentPropertyId.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(context, currentPropertyId),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Floor'),
            ),
      body: SafeArea(
        top: false,
        child: provider.isLoading
            ? const AppLoadingState(message: 'Loading floors…')
            : currentPropertyId.isEmpty
            ? const AppStateCard.empty(
                title: 'No properties found',
                message: 'Add a property first to manage its floors.',
              )
            : _FloorResults(
                floors: floors,
                onOpen: (f) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomsScreen(
                      homeId: currentPropertyId,
                      floorId: f.id,
                      homeName: currentProperty?.name,
                    ),
                  ),
                ),
                onEdit: (f) => _edit(context, f),
                onDelete: (f) => _delete(context, f),
              ),
      ),
    );
  }
}

class _FloorResults extends StatelessWidget {
  final List<ManagedFloor> floors;
  final ValueChanged<ManagedFloor> onOpen;
  final ValueChanged<ManagedFloor> onEdit;
  final ValueChanged<ManagedFloor> onDelete;

  const _FloorResults({
    required this.floors,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (floors.isEmpty) {
      return const AppStateCard.empty(
        title: 'No floors added',
        message: 'Add your first floor to this property.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: floors.length,
      itemBuilder: (context, index) {
        final f = floors[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FloorCard(
            floor: f,
            onTap: () => onOpen(f),
            onEdit: () => onEdit(f),
            onDelete: () => onDelete(f),
          ),
        );
      },
    );
  }
}

class _FloorCard extends StatelessWidget {
  final ManagedFloor floor;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _FloorCard({
    required this.floor,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    final roomCount = propertyProvider.roomsFor(floor.id).length;
    final property = propertyProvider.propertyById(floor.propertyId);
    final deviceCount = deviceProvider
        .visibleDevicesForFloor(
          user,
          propertyName: property?.name ?? '',
          floorName: floor.name,
        )
        .length;

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
                  Icons.layers_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
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
