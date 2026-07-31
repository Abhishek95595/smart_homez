import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property_hierarchy.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_state_widgets.dart';
import '../../widgets/property_management_widgets.dart';
import '../../widgets/property_summary_card.dart';
import '../devices/device_history_screen.dart';
import 'floors_screen.dart';
import 'management_dialogs.dart';

class HomesScreen extends StatelessWidget {
  const HomesScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final provider = context.read<PropertyProvider>();
    final result = await showPropertyForm(
      context,
      nameExists: provider.propertyNameExists,
    );
    if (result == null || !context.mounted) return;
    await provider.addProperty(
      name: result.name,
      address: result.address,
      category: result.category,
      propertyType: result.propertyType,
      timezone: result.timezone,
      currency: result.currency,
      businessStart: result.businessStart,
      businessEnd: result.businessEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Properties & Homes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_home_work_rounded),
        label: const Text('Add Property'),
      ),
      body: propertyProvider.isLoading
          ? const AppLoadingState(message: 'Loading saved properties…')
          : propertyProvider.loadError != null &&
                propertyProvider.properties.isEmpty
          ? AppStateCard.error(
              title: 'Could not load properties',
              message: propertyProvider.loadError!,
              actionLabel: 'Retry',
              onAction: () => context.read<PropertyProvider>().reload(),
            )
          : SearchableManagementList<ManagedProperty>(
              items: propertyProvider.properties,
              searchHint: 'Search properties or addresses',
              emptyMessage:
                  'No properties yet. Tap Add Property to create one.',
              noResultsMessage: 'No property matches your search.',
              matches: (property, query) =>
                  query.isEmpty ||
                  property.name.toLowerCase().contains(query.toLowerCase()) ||
                  property.address.toLowerCase().contains(query.toLowerCase()),
              header: [
                const _ManagementHeader(),
                if (propertyProvider.loadError != null) ...[
                  const SizedBox(height: 12),
                  AppStateCard.error(
                    title: 'Local storage issue',
                    message: propertyProvider.loadError!,
                    actionLabel: 'Retry',
                    onAction: () => context.read<PropertyProvider>().reload(),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  'YOUR PROPERTIES',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              itemBuilder: (context, property) =>
                  _PropertyCard(property: property),
            ),
    );
  }
}

class _ManagementHeader extends StatelessWidget {
  const _ManagementHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(2, 10, 2, 4),
      child: Row(
        children: [
          _HeaderIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Management',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Property → Floor → Room → Device',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FF7A18),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 28),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final ManagedProperty property;

  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final floors = propertyProvider.floorsFor(property.id);
    final floorIds = floors.map((item) => item.id).toSet();
    final roomCount = propertyProvider.rooms
        .where((item) => floorIds.contains(item.floorId))
        .length;
    final devices = deviceProvider.devices
        .where((item) => item.buildingId == property.id)
        .toList();
    final onlineCount = devices
        .where((item) => item.status.name == 'online')
        .length;

    void openProperty() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FloorsScreen(propertyId: property.id),
        ),
      );
    }

    return PropertySummaryCard(
      property: property,
      floorCount: floors.length,
      roomCount: roomCount,
      deviceCount: devices.length,
      onlineDeviceCount: onlineCount,
      onOpen: openProperty,
      onHistory: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeviceHistoryScreen(
            propertyId: property.id,
            propertyName: property.name,
          ),
        ),
      ),
      onEdit: () => _editProperty(context),
      onDelete: () => _deleteProperty(context),
    );
  }

  Future<void> _editProperty(BuildContext context) async {
    final provider = context.read<PropertyProvider>();
    final result = await showPropertyForm(
      context,
      property: property,
      nameExists: (value) =>
          provider.propertyNameExists(value, excludingId: property.id),
    );
    if (result == null || !context.mounted) return;
    await provider.updateProperty(
      property,
      name: result.name,
      address: result.address,
      category: result.category,
      propertyType: result.propertyType,
      timezone: result.timezone,
      currency: result.currency,
      businessStart: result.businessStart,
      businessEnd: result.businessEnd,
    );
  }

  Future<void> _deleteProperty(BuildContext context) async {
    final approved = await confirmDelete(
      context,
      title: 'Delete ${property.name}?',
      message:
          'This will permanently delete the property and every floor, room, '
          'and device inside it.',
    );
    if (!approved || !context.mounted) return;
    await context.read<DeviceProvider>().deleteDevicesForProperty(property.id);
    if (!context.mounted) return;
    await context.read<PropertyProvider>().deleteProperty(property.id);
  }
}
