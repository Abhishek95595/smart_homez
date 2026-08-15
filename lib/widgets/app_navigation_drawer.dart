import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../providers/property_provider.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/admin/admin_console_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/automations/automations_screen.dart';
import '../screens/client_dashboard/client_dashboard_screen.dart';
import '../screens/devices/devices_screen.dart';
import '../screens/energy/energy_screen.dart';
import '../screens/fire_smoke/fire_smoke_screen.dart';
import '../screens/integrations/integrations_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/privacy/privacy_policy_screen.dart';
import '../screens/properties/floors_screen.dart';
import '../screens/properties/homes_screen.dart';
import '../screens/properties/rooms_screen.dart';
import '../screens/services_module/services_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/water/water_screen.dart';
import '../screens/integrations/vendor_nodes_screen.dart';
import '../theme/app_theme.dart';

class AppNavigationDrawer extends StatelessWidget {
  final VoidCallback? onDashboard;
  final bool permanent;

  const AppNavigationDrawer({
    super.key,
    this.onDashboard,
    this.permanent = false,
  });

  void _open(BuildContext context, Widget page) {
    if (!permanent) Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = context.watch<AuthProvider>().role;
    final properties = context.watch<PropertyProvider>();
    final devices = context.watch<DeviceProvider>();
    final alerts = context.watch<AlertProvider>();

    final menuItems = <_DrawerMenuItem>[
      _DrawerMenuItem(
        icon: Icons.home_outlined,
        label: 'Dashboard',
        selected: true,
        onTap: () {
          if (!permanent) Navigator.pop(context);
          onDashboard?.call();
        },
      ),
      _DrawerMenuItem(
        icon: Icons.dashboard_customize_outlined,
        label: 'Client Dashboard',
        onTap: () => _open(context, const ClientDashboardScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.home_work_outlined,
        label: 'Homes',
        onTap: () => _open(context, const HomesScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.layers_outlined,
        label: 'Floors',
        onTap: () => _open(context, const FloorsScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.domain_outlined,
        label: 'Rooms',
        onTap: () => _open(context, const RoomsScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.grid_view_rounded,
        label: 'Devices',
        onTap: () => _open(context, const DevicesScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.bolt_outlined,
        label: 'Automations',
        onTap: () => _open(context, const AutomationsScreen()),
      ),
      if (role.canViewEnergy)
        _DrawerMenuItem(
          icon: Icons.bar_chart_outlined,
          label: 'Energy',
          onTap: () => _open(context, const EnergyScreen()),
        ),
      if (role.canViewWater)
        _DrawerMenuItem(
          icon: Icons.water_drop_outlined,
          label: 'Water',
          onTap: () => _open(context, const WaterScreen()),
        ),
      _DrawerMenuItem(
        icon: Icons.access_time_rounded,
        label: 'Activity',
        onTap: () => _open(context, const ActivityScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.notifications_none_rounded,
        label: 'Alerts',
        trailingBadge: alerts.activeAlerts.isNotEmpty
            ? _CountBadge(count: alerts.activeAlerts.length)
            : null,
        onTap: () => _open(context, const AlertsScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.local_fire_department_outlined,
        label: 'Fire & Smoke',
        onTap: () => _open(context, const FireSmokeScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.share_outlined,
        label: 'Vendor Nodes',
        onTap: () => _open(context, const VendorNodesScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.link_rounded,
        label: 'Integrations',
        onTap: () => _open(context, const IntegrationsScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.support_agent_rounded,
        label: 'Services',
        onTap: () => _open(context, const ServicesScreen()),
      ),
      if (role.canAccessAdminConsole)
        _DrawerMenuItem(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Admin Console',
          onTap: () => _open(context, const AdminConsoleScreen()),
        ),
      _DrawerMenuItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => _open(context, const SettingsScreen()),
      ),
      _DrawerMenuItem(
        icon: Icons.verified_user_outlined,
        label: 'Privacy Policy',
        onTap: () => _open(context, const PrivacyPolicyScreen()),
      ),
    ];

    final content = Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            const _DrawerBrand(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                itemCount: menuItems.length,
                itemBuilder: (context, index) =>
                    _DrawerItemTile(item: menuItems[index]),
              ),
            ),
            _DrawerUserCard(
              initials: user?.avatarInitials ?? '--',
              name: user?.name ?? 'Smart Homez User',
              roleLabel: user?.role.label ?? 'User',
              propertyCount: properties.properties.length,
              deviceCount: devices.devices.length,
              onTap: () => _open(context, const ProfileScreen()),
            ),
          ],
        ),
      ),
    );

    if (permanent) {
      return SizedBox(width: 286, child: Material(child: content));
    }

    return Drawer(
      backgroundColor: AppColors.background,
      width: MediaQuery.sizeOf(context).width * 0.82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(26)),
      ),
      child: content,
    );
  }
}

class _DrawerMenuItem {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailingBadge;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailingBadge,
  });
}

class _DrawerBrand extends StatelessWidget {
  const _DrawerBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.home_rounded,
                  size: 64,
                  color: AppColors.primaryDark,
                ),
                const Positioned(
                  top: 18,
                  child: Icon(
                    Icons.wifi_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                Positioned(
                  bottom: 14,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Icon(
                      Icons.window_rounded,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Homez',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1,
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

class _DrawerItemTile extends StatelessWidget {
  final _DrawerMenuItem item;

  const _DrawerItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isSelected = item.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (item.trailingBadge != null) item.trailingBadge!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DrawerUserCard extends StatelessWidget {
  final String initials;
  final String name;
  final String roleLabel;
  final int propertyCount;
  final int deviceCount;
  final VoidCallback onTap;

  const _DrawerUserCard({
    required this.initials,
    required this.name,
    required this.roleLabel,
    required this.propertyCount,
    required this.deviceCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: AppTheme.cardDecoration(radius: 24),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        roleLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$propertyCount properties • $deviceCount devices',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
