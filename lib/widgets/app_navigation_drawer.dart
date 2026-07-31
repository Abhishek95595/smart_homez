import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/automation_provider.dart';
import '../providers/device_provider.dart';
import '../providers/property_provider.dart';
import '../screens/admin/admin_console_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/automations/automations_screen.dart';
import '../screens/devices/devices_screen.dart';
import '../screens/energy/energy_screen.dart';
import '../screens/fire_smoke/fire_smoke_screen.dart';
import '../screens/integrations/integrations_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/properties/floors_screen.dart';
import '../screens/properties/homes_screen.dart';
import '../screens/properties/rooms_screen.dart';
import '../screens/services_module/services_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/water/water_screen.dart';
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
    final role = context.watch<AuthProvider>().role;
    final user = context.watch<AuthProvider>().currentUser;
    final properties = context.watch<PropertyProvider>();
    final devices = context.watch<DeviceProvider>();
    final alerts = context.watch<AlertProvider>();
    final automations = context.watch<AutomationProvider>();

    final content = ColoredBox(
      color: AppColors.sideBackground,
      child: SafeArea(
        child: Column(
          children: [
            const _DrawerBrand(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                children: [
                  const _DrawerHeading('MAIN'),
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    selected: true,
                    onTap: () {
                      if (!permanent) Navigator.pop(context);
                      onDashboard?.call();
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_active_outlined,
                    label: 'Alerts',
                    count: alerts.activeAlerts.length,
                    onTap: () => _open(context, const AlertsScreen()),
                  ),
                  if (role.canViewEnergy)
                    _DrawerItem(
                      icon: Icons.bolt_outlined,
                      label: 'Energy insights',
                      onTap: () => _open(context, const EnergyScreen()),
                    ),
                  if (role.canViewWater)
                    _DrawerItem(
                      icon: Icons.water_drop_outlined,
                      label: 'Water management',
                      onTap: () => _open(context, const WaterScreen()),
                    ),
                  const _DrawerHeading('MY PROPERTIES'),
                  _DrawerItem(
                    icon: Icons.home_work_outlined,
                    label: 'Properties',
                    count: properties.properties.length,
                    onTap: () => _open(context, const HomesScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.layers_outlined,
                    label: 'Floors',
                    count: properties.floors.length,
                    onTap: () => _open(context, const FloorsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.meeting_room_outlined,
                    label: 'Rooms / units',
                    count: properties.rooms.length,
                    onTap: () => _open(context, const RoomsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.devices_other_rounded,
                    label: 'Devices',
                    count: devices.devices.length,
                    onTap: () => _open(context, const DevicesScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Fire, smoke & gas',
                    onTap: () => _open(context, const FireSmokeScreen()),
                  ),
                  const _DrawerHeading('INTEGRATIONS'),
                  _DrawerItem(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Automations',
                    count: automations.enabledCount,
                    onTap: () => _open(context, const AutomationsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.mic_none_rounded,
                    label: 'Voice assistants',
                    onTap: () =>
                        _open(context, const IntegrationsScreen(initialTab: 0)),
                  ),
                  _DrawerItem(
                    icon: Icons.webhook_rounded,
                    label: 'Webhooks',
                    onTap: () =>
                        _open(context, const IntegrationsScreen(initialTab: 1)),
                  ),
                  _DrawerItem(
                    icon: Icons.hub_outlined,
                    label: 'Vendor nodes',
                    onTap: () => _open(context, const ServicesScreen()),
                  ),
                  if (role.canAccessAdminConsole)
                    _DrawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Access control',
                      onTap: () => _open(context, const AdminConsoleScreen()),
                    ),
                  const _DrawerHeading('ACCOUNT'),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    onTap: () => _open(context, const ProfileScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _open(context, const SettingsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy policy',
                    onTap: () => _open(
                      context,
                      const _InfoScreen(
                        title: 'Privacy Policy',
                        icon: Icons.privacy_tip_outlined,
                        message:
                            'Property, device and account data is used only '
                            'to provide Smart Homez monitoring and automation. '
                            'Sensitive actions should be protected by backend '
                            'authentication before production deployment.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _DrawerUser(
              initials: user?.avatarInitials ?? '--',
              name: user?.name ?? 'Smart Homez User',
              role: user?.role.label ?? 'User',
              onTap: () => _open(context, const ProfileScreen()),
            ),
          ],
        ),
      ),
    );

    if (permanent) {
      return SizedBox(width: 276, child: Material(child: content));
    }

    return Drawer(
      backgroundColor: AppColors.sideBackground,
      width: MediaQuery.sizeOf(context).width * 0.88,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
      ),
      child: content,
    );
  }
}

class _DrawerBrand extends StatelessWidget {
  const _DrawerBrand();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 17),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.sideDivider)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4DFF7A18),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Homez',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'BY AURABRAIN TECHNOLOGIES',
                  style: TextStyle(
                    color: AppColors.sideTextDim,
                    fontSize: 8.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
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

class _DrawerHeading extends StatelessWidget {
  final String text;

  const _DrawerHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 17, 8, 7),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.sideTextDim,
          fontSize: 10.5,
          letterSpacing: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: selected ? AppColors.sideElevated : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primarySoft
                        : AppColors.sideElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: selected ? AppColors.primary : AppColors.sideTextDim,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.sideText,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.sideTextDim,
                      fontSize: 10.5,
                      fontFamily: 'monospace',
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

class _DrawerUser extends StatelessWidget {
  final String initials;
  final String name;
  final String role;
  final VoidCallback onTap;

  const _DrawerUser({
    required this.initials,
    required this.name,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.sideDivider)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(
                        color: AppColors.sideTextDim,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.sideTextDim,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const _InfoScreen({
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
