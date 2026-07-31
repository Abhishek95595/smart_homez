import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/device.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_state_widgets.dart';
import '../../widgets/property_summary_card.dart';
import '../../widgets/section_header.dart';
import '../admin/admin_console_screen.dart';
import '../alerts/alerts_screen.dart';
import '../automations/automations_screen.dart';
import '../devices/device_history_screen.dart';
import '../devices/devices_screen.dart';
import '../energy/energy_screen.dart';
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    user?.avatarInitials ?? '??',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const _AmbientOrb(
                      size: 300,
                      colors: [Color(0x1800A38E), Colors.transparent],
                    ),
                    Positioned(
                      right: -80,
                      top: 40,
                      child: const _AmbientOrb(
                        size: 240,
                        colors: [Color(0x12FFB020), Colors.transparent],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROPERTY MANAGEMENT',
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactStat(
                                label: 'Properties',
                                value: '${propertyProvider.properties.length}',
                                icon: Icons.home_work_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CompactStat(
                                label: 'Online',
                                value: '${deviceProvider.onlineCount}',
                                icon: Icons.cloud_done_outlined,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CompactStat(
                                label: 'Issues',
                                value: '${deviceProvider.offlineCount}',
                                icon: Icons.error_outline_rounded,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SectionHeader(
                  title: 'My Properties',
                  actionLabel: 'Add Property',
                  onAction: () => _addProperty(context),
                ),
                const SizedBox(height: 14),
                if (propertyProvider.properties.isEmpty)
                  const AppStateCard.empty(
                    title: 'No properties mapped',
                    message: 'Add your first property to start monitoring.',
                  )
                else
                  ...propertyProvider.properties.take(2).map((p) {
                    final floors = propertyProvider.floorsFor(p.id);
                    final floorIds = floors.map((f) => f.id).toSet();
                    final rooms = propertyProvider.rooms.where(
                      (r) => floorIds.contains(r.floorId),
                    );
                    final devices = deviceProvider.visibleDevicesAt(user, buildingId: p.id);

                    return PropertySummaryCard(
                      property: p,
                      floorCount: floors.length,
                      roomCount: rooms.length,
                      deviceCount: devices.length,
                      onlineDeviceCount: devices.where((d) => d.status == DeviceStatus.online).length,
                      onOpen: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FloorsScreen(propertyId: p.id),
                        ),
                      ),
                      onHistory: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeviceHistoryScreen(propertyId: p.id),
                        ),
                      ),
                      onEdit: () {}, 
                      onDelete: () {},
                    );
                  }),
                const SizedBox(height: 32),
                const SectionHeader(title: 'Quick Controls'),
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

class _AppBarGreeting extends StatelessWidget {
  final String greeting;
  final String firstName;

  const _AppBarGreeting({required this.greeting, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textFaint,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          firstName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: themeColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
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

class _SmartControlGrid extends StatelessWidget {
  final bool showEnergy;
  const _SmartControlGrid({required this.showEnergy});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _ControlTile(
          icon: Icons.auto_awesome_rounded,
          label: 'Automations',
          color: const Color(0xFF6366F1),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AutomationsScreen()),
          ),
        ),
        _ControlTile(
          icon: Icons.notifications_active_rounded,
          label: 'Alerts',
          color: AppColors.danger,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlertsScreen()),
          ),
        ),
        if (showEnergy)
          _ControlTile(
            icon: Icons.bolt_rounded,
            label: 'Energy',
            color: AppColors.warning,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnergyScreen()),
            ),
          ),
        _ControlTile(
          icon: Icons.water_drop_rounded,
          label: 'Water',
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WaterScreen()),
          ),
        ),
      ],
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _HealthIndicator(
            label: 'Online',
            value: '${deviceProvider.onlineCount}',
            color: AppColors.success,
          ),
          const SizedBox(width: 24),
          _HealthIndicator(
            label: 'Offline',
            value: '${deviceProvider.offlineCount}',
            color: AppColors.textFaint,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'SYSTEM STATUS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textFaint,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Operational',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HealthIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
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

class _AdminConsoleCard extends StatelessWidget {
  final DeviceProvider deviceProvider;
  const _AdminConsoleCard({required this.deviceProvider});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sideBackground,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminConsoleScreen()),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Console',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Manage users, roles and buildings',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
