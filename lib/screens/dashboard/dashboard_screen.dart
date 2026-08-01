import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_state_widgets.dart';
import '../../widgets/property_summary_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/dashboard_templates.dart';
import '../admin/admin_console_screen.dart';
import '../alerts/alerts_screen.dart';
import '../automations/automations_screen.dart';
import '../devices/devices_screen.dart';
import '../energy/energy_screen.dart';
import '../profile/profile_screen.dart';
import '../properties/floors_screen.dart';
import '../properties/management_dialogs.dart';
import '../water/water_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting(bool isCommercial) {
    if (isCommercial) return 'Facility Overview';
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
    final propertyProvider = context.watch<PropertyProvider>();
    final firstProperty = propertyProvider.properties.firstOrNull;
    final isCommercial = firstProperty?.isCommercial ?? false;
    final desktop = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      backgroundColor: isCommercial ? const Color(0xFF0F111A) : AppColors.background,
      appBar: AppBar(
        backgroundColor: isCommercial ? const Color(0xFF0F111A) : AppColors.background,
        automaticallyImplyLeading: false,
        toolbarHeight: 74,
        leading: desktop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: isCommercial ? Colors.white : AppColors.textPrimary,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        titleSpacing: desktop ? 18 : 2,
        title: _AppBarGreeting(
          greeting: _greeting(isCommercial),
          firstName: isCommercial 
              ? (firstProperty?.name ?? 'Facility') 
              : (user?.name.split(' ').first ?? 'User'),
          isDark: isCommercial,
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
                  backgroundColor: isCommercial ? Colors.white10 : AppColors.primarySoft,
                  child: Text(
                    user?.avatarInitials ?? '??',
                    style: TextStyle(
                      color: isCommercial ? Colors.white : AppColors.primary,
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
        child: isCommercial 
            ? _CommercialDashboard(user: user) 
            : _ResidentialDashboard(user: user),
      ),
    );
  }
}

class _ResidentialDashboard extends StatelessWidget {
  final AppUser? user;
  const _ResidentialDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final energy = context.watch<EnergyProvider>();
    final propertyProvider = context.watch<PropertyProvider>();
    final role = user?.role ?? UserRole.resident;

    return DashboardLayoutWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MY HOME AT A GLANCE',
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          DashboardStatGrid(
            children: [
              _CompactStat(
                label: 'Devices',
                value: '${deviceProvider.totalCount}',
                icon: Icons.devices_other_rounded,
              ),
              _CompactStat(
                label: 'Online',
                value: '${deviceProvider.onlineCount}',
                icon: Icons.cloud_done_outlined,
                color: AppColors.success,
              ),
              _CompactStat(
                label: 'Alerts',
                value: '${deviceProvider.offlineCount}',
                icon: Icons.notifications_active_outlined,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 32),
          SectionHeader(
            title: 'Your Properties',
            actionLabel: 'View All',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FloorsScreen()),
            ),
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
              return PropertySummaryCard(
                property: p,
                floorCount: floors.length,
                roomCount: propertyProvider.rooms.where((r) => floors.any((f) => f.id == r.floorId)).length,
                deviceCount: deviceProvider.visibleDevicesAt(user, buildingId: p.id).length,
                onlineDeviceCount: deviceProvider.onlineCountFor(user),
                onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FloorsScreen(propertyId: p.id))),
                onHistory: () {},
                onEdit: () {},
                onDelete: () {},
              );
            }),
          const SizedBox(height: 32),
          const SectionHeader(title: 'Quick Controls'),
          const SizedBox(height: 12),
          _SmartControlGrid(showEnergy: role.canViewEnergy),
          const SizedBox(height: 24),
          if (role.canViewEnergy) ...[
            const SectionHeader(title: 'Energy Consumption'),
            const SizedBox(height: 12),
            _EnergyConsumptionCard(energy: energy),
          ],
        ],
      ),
    );
  }
}

class _CommercialDashboard extends StatelessWidget {
  final AppUser? user;
  const _CommercialDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final propertyProvider = context.watch<PropertyProvider>();
    final energy = context.watch<EnergyProvider>();
    final role = user?.role ?? UserRole.facilityManager;

    return DashboardLayoutWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FACILITY PERFORMANCE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          DashboardStatGrid(
            children: [
              CommercialStatCard(
                label: 'Total Floors',
                value: '${propertyProvider.floors.length}',
                icon: Icons.layers_outlined,
                color: const Color(0xFF6366F1),
              ),
              CommercialStatCard(
                label: 'System Health',
                value: '${deviceProvider.totalCount == 0 ? 0 : (deviceProvider.onlineCount / deviceProvider.totalCount * 100).toInt()}%',
                icon: Icons.analytics_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const SectionHeader(
            title: 'Infrastructure',
            isDark: true,
          ),
          const SizedBox(height: 16),
          _CommercialQuickActions(role: role),
          const SizedBox(height: 32),
          const SectionHeader(
            title: 'Critical Alerts',
            isDark: true,
          ),
          const SizedBox(height: 12),
          _SystemHealthPanel(deviceProvider: deviceProvider, user: user, isDark: true),
          const SizedBox(height: 32),
          if (role.canViewEnergy) ...[
            const SectionHeader(
              title: 'Energy Management',
              isDark: true,
            ),
            const SizedBox(height: 12),
            _EnergyConsumptionCard(energy: energy, isDark: true),
          ],
        ],
      ),
    );
  }
}

class _AppBarGreeting extends StatelessWidget {
  final String greeting;
  final String firstName;
  final bool isDark;

  const _AppBarGreeting({
    required this.greeting, 
    required this.firstName,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white38 : AppColors.textFaint,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          firstName,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
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
  final bool isDark;

  const _SystemHealthPanel({
    required this.deviceProvider, 
    this.user,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2A) : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
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
            color: isDark ? Colors.white24 : AppColors.textFaint,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SYSTEM STATUS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white38 : AppColors.textFaint,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Operational',
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
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
  final bool isDark;

  const _EnergyConsumptionCard({required this.energy, this.isDark = false});

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
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF1B1E2A), const Color(0xFF262A38)]
                : [const Color(0xFF151722), AppColors.primaryDark, AppColors.primary],
            stops: isDark ? null : [0, 0.56, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : const Color(0x33FF7A18),
              blurRadius: 26,
              offset: const Offset(0, 13),
            ),
          ],
          border: isDark ? Border.all(color: Colors.white10) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Load',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.white70, 
                      fontSize: 12,
                    ),
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
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.white70, 
                      fontSize: 12,
                    ),
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

class _CommercialQuickActions extends StatelessWidget {
  final UserRole role;
  const _CommercialQuickActions({required this.role});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _CommercialTile(
          label: 'Floors',
          icon: Icons.layers_outlined,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FloorsScreen())),
        ),
        _CommercialTile(
          label: 'Devices',
          icon: Icons.devices_other_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevicesScreen())),
        ),
        _CommercialTile(
          label: 'Automations',
          icon: Icons.auto_awesome_outlined,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutomationsScreen())),
        ),
        if (role.canAccessAdminConsole)
          _CommercialTile(
            label: 'Access Control',
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminConsoleScreen())),
          ),
      ],
    );
  }
}

class _CommercialTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CommercialTile({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B1E2A),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
