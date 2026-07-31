import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../models/app_user.dart';
import '../../models/device.dart';
import '../../models/property_hierarchy.dart';
import '../../models/user_role.dart';
import '../../models/water_system.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_state_widgets.dart';
import '../../widgets/property_summary_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/severity_badge.dart';
import '../admin/admin_console_screen.dart';
import '../alerts/alerts_screen.dart';
import '../automations/automations_screen.dart';
import '../devices/device_history_screen.dart';
import '../devices/devices_screen.dart';
import '../energy/energy_screen.dart';
import '../fire_smoke/fire_smoke_screen.dart';
import '../profile/profile_screen.dart';
import '../properties/floors_screen.dart';
import '../properties/management_dialogs.dart';
import '../water/water_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _addProperty(BuildContext context) async {
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
    final user = context.watch<AuthProvider>().currentUser;
    final deviceProvider = context.watch<DeviceProvider>();
    final energy = context.watch<EnergyProvider>();
    final propertyProvider = context.watch<PropertyProvider>();
    final role = user?.role ?? UserRole.resident;
    final desktop = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        toolbarHeight: 74,
        leading: desktop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        titleSpacing: desktop ? 18 : 2,
        title: _AppBarGreeting(
          greeting: _greeting(),
          firstName: user?.name.split(' ').first ?? 'User',
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Open profile',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.sideBackground,
                radius: 22,
                child: Text(
                  user?.avatarInitials ?? '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            const Positioned(
              top: -86,
              right: -92,
              child: _AmbientOrb(
                size: 230,
                colors: [Color(0x2200A38E), Color(0x0000A38E)],
              ),
            ),
            const Positioned(
              top: 630,
              left: -112,
              child: _AmbientOrb(
                size: 260,
                colors: [Color(0x1500A38E), Color(0x0000A38E)],
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                const _PropertyManagementIntro(),
                const SizedBox(height: 22),
                _DashboardPropertiesSection(
                  propertyProvider: propertyProvider,
                  deviceProvider: deviceProvider,
                  onAddProperty: () => _addProperty(context),
                ),
                const SizedBox(height: 30),
                const SectionHeader(title: 'Smart Controls'),
                const SizedBox(height: 12),
                _SmartControlGrid(showEnergy: role.canViewEnergy),
                const SizedBox(height: 28),
                if (role.canAccessAdminConsole) ...[
                  _AdminConsoleCard(deviceProvider: deviceProvider),
                  const SizedBox(height: 24),
                ],
                SectionHeader(
                  title: 'System Health',
                  actionLabel: 'View devices',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DevicesScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _SystemHealthPanel(deviceProvider: deviceProvider, user: user),
                const SizedBox(height: 24),
                if (role.canViewEnergy) ...[
                  const SectionHeader(title: 'Energy Consumption'),
                  const SizedBox(height: 12),
                  _EnergyConsumptionCard(energy: energy),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _AmbientOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _AppBarGreeting extends StatelessWidget {
  final String greeting;
  final String firstName;

  const _AppBarGreeting({required this.greeting, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$firstName 👋',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }
}

class _PropertyManagementIntro extends StatelessWidget {
  const _PropertyManagementIntro();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Property Management',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Property  →  Floor  →  Room  →  Device',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardPropertiesSection extends StatefulWidget {
  final PropertyProvider propertyProvider;
  final DeviceProvider deviceProvider;
  final VoidCallback onAddProperty;

  const _DashboardPropertiesSection({
    required this.propertyProvider,
    required this.deviceProvider,
    required this.onAddProperty,
  });

  @override
  State<_DashboardPropertiesSection> createState() =>
      _DashboardPropertiesSectionState();
}

class _DashboardPropertiesSectionState
    extends State<_DashboardPropertiesSection> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editProperty(ManagedProperty property) async {
    final result = await showPropertyForm(
      context,
      property: property,
      nameExists: (value) => widget.propertyProvider.propertyNameExists(
        value,
        excludingId: property.id,
      ),
    );
    if (result == null || !mounted) return;
    await widget.propertyProvider.updateProperty(
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

  Future<void> _deleteProperty(ManagedProperty property) async {
    final approved = await confirmDelete(
      context,
      title: 'Delete ${property.name}?',
      message:
          'This will permanently delete the property and every floor, room, '
          'and device inside it.',
    );
    if (!approved || !mounted) return;
    await widget.deviceProvider.deleteDevicesForProperty(property.id);
    if (!mounted) return;
    await widget.propertyProvider.deleteProperty(property.id);
  }

  @override
  Widget build(BuildContext context) {
    final properties = widget.propertyProvider.properties.where((property) {
      final query = _query.toLowerCase();
      return query.isEmpty ||
          property.name.toLowerCase().contains(query) ||
          property.address.toLowerCase().contains(query) ||
          property.propertyType.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'YOUR PROPERTIES',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${widget.propertyProvider.properties.length} total',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: InputDecoration(
            hintText: 'Search properties or addresses',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        if (widget.propertyProvider.isLoading)
          const AppLoadingState(message: 'Loading your properties…')
        else if (widget.propertyProvider.loadError != null &&
            widget.propertyProvider.properties.isEmpty)
          AppStateCard.error(
            title: 'Could not load properties',
            message: widget.propertyProvider.loadError!,
            actionLabel: 'Retry',
            onAction: () => widget.propertyProvider.reload(),
          )
        else if (widget.propertyProvider.properties.isEmpty)
          const AppStateCard.empty(
            title: 'No properties yet',
            message: 'Add your first home, apartment, or office to begin.',
          )
        else if (properties.isEmpty)
          const AppStateCard.empty(
            title: 'No matching properties',
            message: 'Try searching with another name, type, or address.',
          )
        else
          ...properties.map((property) {
            final floors = widget.propertyProvider.floorsFor(property.id);
            final floorIds = floors.map((floor) => floor.id).toSet();
            final roomCount = widget.propertyProvider.rooms
                .where((room) => floorIds.contains(room.floorId))
                .length;
            final devices = widget.deviceProvider.devices
                .where((device) => device.buildingId == property.id)
                .toList();
            final onlineCount = devices
                .where((device) => device.status == DeviceStatus.online)
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
              onEdit: () => _editProperty(property),
              onDelete: () => _deleteProperty(property),
            );
          }),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: widget.onAddProperty,
            icon: const Icon(Icons.add_home_work_rounded),
            label: const Text('Add Property'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shadowColor: AppColors.primary.withValues(alpha: 0.35),
              elevation: 8,
            ),
          ),
        ),
      ],
    );
  }
}

// Kept for the standalone safety module, but intentionally not shown on Home.
// ignore: unused_element
class _SectionEyebrow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionEyebrow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            letterSpacing: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _SafetyFirstPanel extends StatelessWidget {
  final AlertProvider alertProvider;
  final String userName;

  const _SafetyFirstPanel({
    required this.alertProvider,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final safetyAlerts = alertProvider.activeAlerts
        .where(
          (alert) =>
              alert.alertType == AlertType.smoke ||
              alert.alertType == AlertType.gasLeak ||
              alert.alertType == AlertType.waterOverflow,
        )
        .toList();
    final critical = safetyAlerts.any(
      (alert) => alert.severity == AlertSeverity.critical,
    );
    final needsAttention = safetyAlerts.isNotEmpty;
    final status = critical
        ? 'CRITICAL'
        : needsAttention
        ? 'ATTENTION NEEDED'
        : 'SAFE';
    final statusColor = critical
        ? AppColors.critical
        : needsAttention
        ? AppColors.warning
        : AppColors.success;

    int count(AlertType type) =>
        safetyAlerts.where((alert) => alert.alertType == type).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  critical
                      ? Icons.emergency_rounded
                      : needsAttention
                      ? Icons.warning_amber_rounded
                      : Icons.shield_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '24/7 SAFETY MONITORING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.circle, size: 10, color: AppColors.success),
              const SizedBox(width: 5),
              const Text(
                'Live',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SafetyMetric(
                  icon: Icons.smoke_free_rounded,
                  label: 'Smoke',
                  count: count(AlertType.smoke),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SafetyMetric(
                  icon: Icons.gas_meter_rounded,
                  label: 'Gas Leak',
                  count: count(AlertType.gasLeak),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SafetyMetric(
                  icon: Icons.water_damage_rounded,
                  label: 'Overflow',
                  count: count(AlertType.waterOverflow),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showEmergencyActions(context),
              icon: const Icon(Icons.call_rounded),
              label: const Text('Emergency Call / Contact'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.critical,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Alert Timeline',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                ),
                child: const Text('View all'),
              ),
            ],
          ),
          if (safetyAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text('No active safety alerts. All systems normal.'),
                  ),
                ],
              ),
            )
          else
            ...safetyAlerts
                .take(3)
                .map(
                  (alert) =>
                      _SafetyTimelineItem(alert: alert, userName: userName),
                ),
        ],
      ),
    );
  }

  void _showEmergencyActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emergency response',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose the appropriate contact. Configure real phone numbers '
                'in Settings before production use.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.critical,
                  child: Icon(Icons.local_fire_department, color: Colors.white),
                ),
                title: const Text('Fire & Emergency Services'),
                subtitle: const Text('Emergency number: 112'),
                onTap: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.security_rounded),
                ),
                title: const Text('Building Security'),
                subtitle: const Text('Contact not configured'),
                onTap: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.contact_phone_rounded),
                ),
                title: const Text('Emergency Contact'),
                subtitle: const Text('Contact not configured'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SafetyMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _SafetyMetric({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final safe = count == 0;
    final color = safe ? AppColors.success : AppColors.critical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          Text(
            safe ? 'Safe' : '$count alert${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SafetyTimelineItem extends StatelessWidget {
  final AppAlert alert;
  final String userName;

  const _SafetyTimelineItem({required this.alert, required this.userName});

  @override
  Widget build(BuildContext context) {
    final time =
        '${alert.timestamp.hour.toString().padLeft(2, '0')}:'
        '${alert.timestamp.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeverityBadge(severity: alert.severity),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.alertType.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            alert.location,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!alert.acknowledged)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<AlertProvider>().acknowledge(
                      alert,
                      userName,
                    ),
                    child: const Text('Acknowledge'),
                  ),
                )
              else
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 17,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Acknowledged',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      context.read<AlertProvider>().resolve(alert, userName),
                  child: const Text('Mark Resolved'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _WaterPumpSnapshot extends StatelessWidget {
  final WaterTank tank;

  const _WaterPumpSnapshot({required this.tank});

  @override
  Widget build(BuildContext context) {
    final running = tank.pumpState == PumpState.running;
    final duration = tank.displayedRunDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WaterScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.water_drop_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Water & Pump Automation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PumpMetric(
                    label: 'Tank Level',
                    value: '${tank.levelPercent.toStringAsFixed(0)}%',
                  ),
                ),
                Expanded(
                  child: _PumpMetric(
                    label: 'Pump',
                    value: running ? 'ON' : 'OFF',
                    color: running
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: _PumpMetric(
                    label: 'Mode',
                    value: tank.pumpMode == PumpMode.auto ? 'AUTO' : 'MANUAL',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Run time: ${hours}h ${minutes}m  •  '
              'Energy: ${tank.energyUsageKwh.toStringAsFixed(2)} kWh',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 17,
                  color: tank.overflowProtectionEnabled
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  tank.overflowProtectionEnabled
                      ? 'Overflow prevention active'
                      : 'Overflow prevention disabled',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _PumpMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _PumpMetric({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _CriticalAlertCard extends StatelessWidget {
  final AlertProvider alertProvider;
  const _CriticalAlertCard({required this.alertProvider});

  @override
  Widget build(BuildContext context) {
    final alert = alertProvider.activeAlerts.first;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlertsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.critical.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.critical,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SeverityBadge(severity: alert.severity),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.alertType.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.location,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartControlGrid extends StatelessWidget {
  final bool showEnergy;

  const _SmartControlGrid({required this.showEnergy});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(
        title: 'Automations',
        subtitle: 'Scenes, schedules & routines',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.primary,
        page: AutomationsScreen(),
      ),
      if (showEnergy)
        const _NavItem(
          title: 'Energy',
          subtitle: 'Live usage & cost insights',
          icon: Icons.query_stats_rounded,
          color: Color(0xFF3B82F6),
          page: EnergyScreen(),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = items.length == 1 ? 1 : 2;
        final wide = constraints.maxWidth >= 700;
        final aspectRatio = columns == 1
            ? (wide ? 4.8 : 2.35)
            : (wide ? 2.8 : 1.35);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _SmartControlTile(item: items[index]),
        );
      },
    );
  }
}

class _NavItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const _NavItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}

class _SmartControlTile extends StatelessWidget {
  final _NavItem item;
  const _SmartControlTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final deepColor = Color.lerp(item.color, const Color(0xFF11131B), 0.38)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [item.color, deepColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item.page),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -35,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.17),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Icon(item.icon, color: Colors.white),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.north_east_rounded,
                            color: Colors.white70,
                            size: 19,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FireSmokeSnapshotCard extends StatelessWidget {
  final DeviceProvider deviceProvider;
  final AlertProvider alertProvider;
  final AppUser? user;

  const _FireSmokeSnapshotCard({
    required this.deviceProvider,
    required this.alertProvider,
  }) : user = null;

  @override
  Widget build(BuildContext context) {
    final sensors = deviceProvider.fireAndSmokeDevicesFor(user);
    final activeSafetyAlerts = alertProvider.activeSafetyAlerts.length;
    final online = sensors
        .where((device) => device.status == DeviceStatus.online)
        .length;
    final hasAlert = activeSafetyAlerts > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FireSmokeScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasAlert
              ? AppColors.critical.withValues(alpha: 0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasAlert
                ? AppColors.critical.withValues(alpha: 0.45)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (hasAlert ? AppColors.critical : AppColors.success)
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasAlert
                    ? Icons.local_fire_department_rounded
                    : Icons.shield_outlined,
                color: hasAlert ? AppColors.critical : AppColors.success,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAlert ? 'Fire & Smoke Alert' : 'Fire & Smoke Safety',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasAlert
                        ? '$activeSafetyAlerts active smoke/gas alert${activeSafetyAlerts == 1 ? '' : 's'}'
                        : '$online/${sensors.length} safety sensors online',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemHealthPanel extends StatelessWidget {
  final DeviceProvider deviceProvider;
  final AppUser? user;
  const _SystemHealthPanel({required this.deviceProvider, this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, Color(0xFFF0F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE6F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D14161F),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _healthStat(
            'Online',
            deviceProvider.onlineCountFor(user),
            AppColors.success,
          ),
          _divider(),
          _healthStat(
            'Offline',
            deviceProvider.offlineCountFor(user),
            AppColors.textSecondary,
          ),
          _divider(),
          _healthStat(
            'Total',
            deviceProvider.totalCountFor(user),
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: AppColors.divider);

  Widget _healthStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyConsumptionCard extends StatelessWidget {
  final EnergyProvider energy;
  const _EnergyConsumptionCard({required this.energy});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EnergyScreen()),
      ),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF151722), AppColors.primaryDark, AppColors.primary],
            stops: [0, 0.56, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33FF7A18),
              blurRadius: 26,
              offset: Offset(0, 13),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Load',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${energy.instantPowerWatts.toStringAsFixed(0)} W',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Today: ${energy.todayKwh.toStringAsFixed(1)} kWh",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entry point to the Admin Console (Super Admin / Facility Manager only) —
/// building/tower/flat hierarchy overview & user/device administration.
class _AdminConsoleCard extends StatelessWidget {
  final DeviceProvider deviceProvider;
  const _AdminConsoleCard({required this.deviceProvider});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminConsoleScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Console',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Buildings, users & device registry',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
