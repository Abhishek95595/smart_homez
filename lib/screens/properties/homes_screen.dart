import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property_hierarchy.dart';
import '../../models/device.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../widgets/app_state_widgets.dart';
import '../../widgets/property_summary_card.dart';
import '../devices/device_history_screen.dart';
import 'floors_screen.dart';
import 'rooms_screen.dart';
import 'management_dialogs.dart';

import '../../features/home_setup/providers/home_setup_provider.dart';

class HomesScreen extends StatefulWidget {
  const HomesScreen({super.key});

  @override
  State<HomesScreen> createState() => _HomesScreenState();
}

class _HomesScreenState extends State<HomesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final clientId = context.read<AuthProvider>().resolvedClientId;
      if (clientId != null) {
        context.read<PropertyProvider>().syncFromApi(clientId);
      }
    });
  }

  void _openHomeSetup(BuildContext context) {
    try {
      context.read<HomeSetupProvider>().reset();
    } catch (e) {
      debugPrint('[HomesScreen] Notice resetting HomeSetupProvider: $e');
    }
    Navigator.of(context, rootNavigator: true).pushNamed('/homes/setup').then((
      _,
    ) {
      if (context.mounted) {
        final clientId = context.read<AuthProvider>().resolvedClientId;
        if (clientId != null) {
          context.read<PropertyProvider>().syncFromApi(clientId);
        } else {
          context.read<PropertyProvider>().reload();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties & Homes'),
        actions: [
          IconButton(
            tooltip: 'Add Property Setup',
            icon: const Icon(
              Icons.add_home_work_rounded,
              color: Color(0xFF00A38E),
            ),
            onPressed: () => _openHomeSetup(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openHomeSetup(context),
        icon: const Icon(Icons.add_home_work_rounded),
        label: const Text('Add Property'),
      ),
      body: propertyProvider.isLoading
          ? const AppLoadingState(message: 'Loading properties…')
          : propertyProvider.loadError != null &&
                propertyProvider.properties.isEmpty
          ? AppStateCard.error(
              title: 'Could not load properties',
              message: propertyProvider.loadError!,
              actionLabel: 'Retry',
              onAction: () => propertyProvider.reload(),
            )
          : _PropertyResults(
              properties: propertyProvider.properties,
              onOpen: (p) {
                final floors = propertyProvider.floorsFor(p.id);
                if (floors.isEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RoomsScreen(homeId: p.id, homeName: p.name),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FloorsScreen(propertyId: p.id),
                    ),
                  );
                }
              },
            ),
    );
  }
}

class _PropertyResults extends StatelessWidget {
  final List<ManagedProperty> properties;
  final ValueChanged<ManagedProperty> onOpen;

  const _PropertyResults({required this.properties, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: AppStateCard.empty(
          title: 'No properties found',
          message: 'Add your first house, apartment, or office to get started.',
        ),
      );
    }

    final propertyProvider = context.watch<PropertyProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final p = properties[index];
        final floors = propertyProvider.floorsFor(p.id);
        final rooms = propertyProvider.roomsForHome(p.id);
        final devices = deviceProvider.visibleDevicesForProperty(
          user,
          p.name,
          propertyId: p.id,
        );

        return PropertySummaryCard(
          property: p,
          floorCount: floors.length,
          roomCount: rooms.length,
          deviceCount: devices.length,
          onlineDeviceCount: devices
              .where((d) => d.status == DeviceStatus.online)
              .length,
          onOpen: () => onOpen(p),
          onHistory: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceHistoryScreen(propertyId: p.id),
            ),
          ),
          onEdit: () async {
            final result = await showPropertyForm(
              context,
              property: p,
              nameExists: (name) =>
                  propertyProvider.propertyNameExists(name, excludingId: p.id),
            );
            if (result != null) {
              await propertyProvider.updateProperty(
                p,
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
          },
          onDelete: () async {
            final approved = await confirmDelete(
              context,
              title: 'Delete ${p.name}?',
              message: 'This will remove all floors, rooms, and devices.',
            );
            if (approved) {
              await propertyProvider.deleteProperty(p.id);
              if (context.mounted) {
                await context.read<DeviceProvider>().deleteDevicesForProperty(
                  p.id,
                );
              }
            }
          },
        );
      },
    );
  }
}
