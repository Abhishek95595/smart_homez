import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../screens/admin/admin_console_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/client_dashboard/client_dashboard_screen.dart';
import '../screens/energy/energy_screen.dart';
import '../screens/environment/environment_screen.dart';
import '../screens/family/family_invite_screen.dart';
import '../screens/fire_smoke/fire_smoke_screen.dart';
import '../screens/integrations/integrations_screen.dart';
import '../screens/integrations/vendor_nodes_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/properties/floors_screen.dart';
import '../screens/properties/homes_screen.dart';
import '../screens/properties/rooms_screen.dart';
import '../screens/scenes/scenes_screen.dart';
import '../screens/main_shell.dart';
import '../screens/services_module/services_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/water/water_screen.dart';
import 'app_logo.dart';

/// Helper to reliably open the root AppNavigationDrawer from any tab or child screen.
void openAppDrawer(BuildContext context) {
  final mainShell = context.findAncestorStateOfType<MainShellState>();
  if (mainShell != null) {
    mainShell.openDrawer();
    return;
  }
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null && scaffold.hasDrawer) {
    scaffold.openDrawer();
  }
}

class AppNavigationDrawer extends StatefulWidget {
  final VoidCallback? onDashboard;
  final ValueChanged<int>? onTabSelected;
  final bool permanent;

  const AppNavigationDrawer({
    super.key,
    this.onDashboard,
    this.onTabSelected,
    this.permanent = false,
  });

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  // All 6 cards closed by default
  final Set<String> _expandedKeys = <String>{};

  void _toggleSection(String key) {
    setState(() {
      if (_expandedKeys.contains(key)) {
        _expandedKeys.remove(key);
      } else {
        _expandedKeys.add(key);
      }
    });
  }

  void _openHome(BuildContext context) {
    _openTab(context, 0);
  }

  void _openTab(BuildContext context, int tabIndex) {
    if (widget.permanent) {
      widget.onTabSelected?.call(tabIndex);
      if (tabIndex == 0) widget.onDashboard?.call();
      return;
    }

    Navigator.of(context).pop();

    if (widget.onTabSelected != null) {
      widget.onTabSelected!(tabIndex);
    } else if (widget.onDashboard != null && tabIndex == 0) {
      widget.onDashboard!();
    } else {
      final mainShellState = context.findAncestorStateOfType<MainShellState>();
      if (mainShellState != null) {
        mainShellState.onTabTapped(tabIndex);
      } else {
        final rootNav = Navigator.of(context, rootNavigator: true);
        if (rootNav.canPop()) {
          rootNav.popUntil((route) => route.isFirst);
        } else {
          rootNav.pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainShell(initialIndex: tabIndex),
            ),
          );
        }
      }
    }
  }

  void _open(BuildContext context, Widget page) {
    if (!widget.permanent) {
      Navigator.of(context).pop();
    }
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => page));
  }

  void _openInviteModal(
    BuildContext context, {
    String initialMethod = 'email',
  }) {
    if (!widget.permanent) {
      Navigator.of(context).pop();
    }
    showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FamilyInviteBottomSheet(initialMethod: initialMethod),
    );
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.role;
    final alerts = context.watch<AlertProvider>();
    final notifSettings = Provider.of<NotificationSettingsProvider?>(context);

    final double drawerWidth = widget.permanent
        ? 280.0
        : (MediaQuery.sizeOf(context).width * 0.84).clamp(310.0, 345.0);

    final content = Stack(
      children: [
        // Layer 1: Full drawer background image (covers the entire drawer)
        Positioned.fill(
          child: Image.asset(
            'assets/images/drawer_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF23C9B5), Color(0xFF00A38E)],
                ),
              ),
            ),
          ),
        ),

        // Layer 2: Subtle readability overlay for perfect foreground text contrast
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.04),
                ],
                stops: const [0.0, 0.32, 1.0],
              ),
            ),
          ),
        ),

        // Layer 3: Foreground scrollable drawer content
        SafeArea(
          top: false,
          bottom: true,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Top Hero Header (frames the background house & robot)
              SliverToBoxAdapter(
                child: _DrawerHeroHeader(
                  onHomeTap: () => _openHome(context),
                  onAlertsTap: () => _open(context, const AlertsScreen()),
                  alertCount: alerts.activeAlerts.length,
                ),
              ),

              // Overlapping Navigation Content Area
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28), // 28px visual overlap
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Subtle decorative element behind cards
                      const Positioned.fill(
                        child: _DrawerBackgroundDecorations(),
                      ),

                      // Main Navigation Cards & Bottom Utilities
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Home
                            _SmartDrawerMenuCard(
                              letter: 'H',
                              letterColor: const Color(0xFF00A38E),
                              letterBgColor: const Color(0xFFE6F7F5),
                              letterBorderColor: const Color(0xFFB2EBF2),
                              title: 'Home',
                              subtitle: 'Properties, Floors, Rooms & Devices',
                              isExpanded: _expandedKeys.contains('H'),
                              onToggle: () => _toggleSection('H'),
                              children: [
                                _DrawerChildItem(
                                  title: 'Properties',
                                  icon: Icons.apartment_rounded,
                                  isLast: false,
                                  onTap: () =>
                                      _open(context, const HomesScreen()),
                                ),
                                _DrawerChildItem(
                                  title: 'Floors',
                                  icon: Icons.layers_outlined,
                                  isLast: false,
                                  onTap: () =>
                                      _open(context, const FloorsScreen()),
                                ),
                                _DrawerChildItem(
                                  title: 'Rooms',
                                  icon: Icons.meeting_room_outlined,
                                  isLast: false,
                                  onTap: () =>
                                      _open(context, const RoomsScreen()),
                                ),
                                _DrawerChildItem(
                                  title: 'Devices',
                                  icon: Icons.grid_view_rounded,
                                  isLast: true,
                                  onTap: () => _openTab(context, 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 2. Automations
                            _SmartDrawerMenuCard(
                              letter: 'A',
                              letterColor: const Color(0xFF6366F1),
                              letterBgColor: const Color(0xFFEEF2FF),
                              letterBorderColor: const Color(0xFFC7D2FE),
                              title: 'Automations',
                              subtitle: 'Rules & Schedules',
                              isExpanded: _expandedKeys.contains('A'),
                              onToggle: () => _toggleSection('A'),
                              children: [
                                _DrawerChildItem(
                                  title: 'Automations',
                                  icon: Icons.bolt_outlined,
                                  isLast: false,
                                  onTap: () => _openTab(context, 2),
                                ),
                                _DrawerChildItem(
                                  title: 'Scenes',
                                  icon: Icons.auto_awesome_rounded,
                                  isLast: true,
                                  onTap: () =>
                                      _open(context, const ScenesScreen()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 3. Smart
                            _SmartDrawerMenuCard(
                              letter: 'S',
                              letterColor: const Color(0xFF0284C7),
                              letterBgColor: const Color(0xFFE0F2FE),
                              letterBorderColor: const Color(0xFFBAE6FD),
                              title: 'Smart',
                              subtitle: 'Environment Monitoring',
                              isExpanded: _expandedKeys.contains('S'),
                              onToggle: () => _toggleSection('S'),
                              children: [
                                _DrawerChildItem(
                                  title: 'Environment',
                                  icon: Icons.eco_outlined,
                                  isLast: true,
                                  onTap: () =>
                                      _open(context, const EnvironmentScreen()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 4. Operations
                            _SmartDrawerMenuCard(
                              letter: 'O',
                              letterColor: const Color(0xFFD97706),
                              letterBgColor: const Color(0xFFFEF3C7),
                              letterBorderColor: const Color(0xFFFDE68A),
                              title: 'Operations',
                              subtitle: 'Energy, Water, Fire & More',
                              isExpanded: _expandedKeys.contains('O'),
                              onToggle: () => _toggleSection('O'),
                              children: [
                                if (role.canViewEnergy)
                                  _DrawerChildItem(
                                    title: 'Energy Monitoring',
                                    icon: Icons.electric_bolt_rounded,
                                    isLast: false,
                                    onTap: () =>
                                        _open(context, const EnergyScreen()),
                                  ),
                                _DrawerChildItem(
                                  title: 'Energy Dashboard',
                                  icon: Icons.analytics_outlined,
                                  isLast: !role.canViewWater,
                                  onTap: () => _open(
                                    context,
                                    const ClientDashboardScreen(),
                                  ),
                                ),
                                if (role.canViewWater)
                                  _DrawerChildItem(
                                    title: 'Water',
                                    icon: Icons.water_drop_outlined,
                                    isLast: false,
                                    onTap: () =>
                                        _open(context, const WaterScreen()),
                                  ),
                                _DrawerChildItem(
                                  title: 'Fire & Smoke',
                                  icon: Icons.local_fire_department_outlined,
                                  isLast: true,
                                  onTap: () =>
                                      _open(context, const FireSmokeScreen()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 5. Machines
                            _SmartDrawerMenuCard(
                              letter: 'M',
                              letterColor: const Color(0xFF0D9488),
                              letterBgColor: const Color(0xFFCCFBF1),
                              letterBorderColor: const Color(0xFF99F6E4),
                              title: 'Machines',
                              subtitle: 'All Connected Devices',
                              isExpanded: _expandedKeys.contains('M'),
                              onToggle: () => _toggleSection('M'),
                              children: [
                                _DrawerChildItem(
                                  title: 'Devices',
                                  icon: Icons.sensors_rounded,
                                  isLast: true,
                                  onTap: () => _openTab(context, 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 6. Intelligence (HASOMI Voice Assistant removed)
                            _SmartDrawerMenuCard(
                              letter: 'I',
                              letterColor: const Color(0xFF8B5CF6),
                              letterBgColor: const Color(0xFFF5F3FF),
                              letterBorderColor: const Color(0xFFDDD6FE),
                              title: 'Intelligence',
                              subtitle: 'AI-Powered Insights',
                              isExpanded: _expandedKeys.contains('I'),
                              onToggle: () => _toggleSection('I'),
                              children: [
                                _DrawerChildItem(
                                  title: 'Voice & Alexa Integrations',
                                  icon: Icons.speaker_rounded,
                                  isLast: false,
                                  onTap: () => _open(
                                    context,
                                    const IntegrationsScreen(),
                                  ),
                                ),
                                _DrawerChildItem(
                                  title: 'Activity Stream',
                                  icon: Icons.access_time_rounded,
                                  isLast: alerts.activeAlerts.isEmpty,
                                  onTap: () => _openTab(context, 3),
                                ),
                                if (alerts.activeAlerts.isNotEmpty)
                                  _DrawerChildItem(
                                    title: 'Active Alerts',
                                    icon: Icons.notifications_active_outlined,
                                    isLast: true,
                                    trailingBadge: _AlertCountBadge(
                                      count: alerts.activeAlerts.length,
                                    ),
                                    onTap: () =>
                                        _open(context, const AlertsScreen()),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 7. Family & Invite
                            _SmartDrawerMenuCard(
                              icon: Icons.family_restroom_rounded,
                              iconColor: const Color(0xFF0284C7),
                              iconBgColor: const Color(0xFFE0F2FE),
                              iconBorderColor: const Color(0xFFBAE6FD),
                              title: 'Family & Invite',
                              subtitle: 'Device Access by Email or Phone',
                              isExpanded: _expandedKeys.contains('F'),
                              onToggle: () => _toggleSection('F'),
                              children: [
                                _DrawerChildItem(
                                  title: 'Invite by Email',
                                  icon: Icons.email_outlined,
                                  isLast: false,
                                  onTap: () => _openInviteModal(
                                    context,
                                    initialMethod: 'email',
                                  ),
                                ),
                                _DrawerChildItem(
                                  title: 'Invite by Phone',
                                  icon: Icons.phone_iphone_rounded,
                                  isLast: false,
                                  onTap: () => _openInviteModal(
                                    context,
                                    initialMethod: 'phone',
                                  ),
                                ),
                                _DrawerChildItem(
                                  title: 'Family Members & Access',
                                  icon: Icons.group_outlined,
                                  isLast: true,
                                  onTap: () => _open(
                                    context,
                                    const FamilyInviteScreen(),
                                  ),
                                ),
                              ],
                            ),

                            // Tenant Administration (Super Admin & Facility Manager)
                            if (role.canAccessTenantAdmin) ...[
                              const SizedBox(height: 10),
                              _SmartDrawerMenuCard(
                                letter: 'T',
                                letterColor: const Color(0xFF334155),
                                letterBgColor: const Color(0xFFF1F5F9),
                                letterBorderColor: const Color(0xFFE2E8F0),
                                icon: Icons.admin_panel_settings_outlined,
                                title: 'Tenant Administration',
                                subtitle: 'Clients, Spaces & Automations',
                                isExpanded: _expandedKeys.contains('T'),
                                onToggle: () => _toggleSection('T'),
                                children: [
                                  _DrawerChildItem(
                                    title: 'Clients & Users',
                                    icon: Icons.people_outline_rounded,
                                    isLast: false,
                                    onTap: () => _open(
                                      context,
                                      const AdminConsoleScreen(
                                        initialTabIndex: 1,
                                      ),
                                    ),
                                  ),
                                  _DrawerChildItem(
                                    title: 'Devices & Spaces',
                                    icon: Icons.apartment_rounded,
                                    isLast: false,
                                    onTap: () =>
                                        _open(context, const HomesScreen()),
                                  ),
                                  _DrawerChildItem(
                                    title: 'Automations & Scenes',
                                    icon:
                                        Icons.precision_manufacturing_outlined,
                                    isLast: false,
                                    onTap: () => _openTab(context, 2),
                                  ),
                                  _DrawerChildItem(
                                    title: 'Integrations',
                                    icon: Icons.extension_outlined,
                                    isLast: false,
                                    onTap: () => _open(
                                      context,
                                      const IntegrationsScreen(),
                                    ),
                                  ),
                                  _DrawerChildItem(
                                    title: 'Tenant Settings',
                                    icon: Icons.settings_outlined,
                                    isLast: true,
                                    onTap: () =>
                                        _open(context, const SettingsScreen()),
                                  ),
                                ],
                              ),
                            ],

                            // Platform Administration (Super Admin only)
                            if (role.canAccessPlatformAdmin) ...[
                              const SizedBox(height: 10),
                              _SmartDrawerMenuCard(
                                letter: 'P',
                                letterColor: const Color(0xFF4338CA),
                                letterBgColor: const Color(0xFFEEF2FF),
                                letterBorderColor: const Color(0xFFC7D2FE),
                                icon: Icons.shield_outlined,
                                title: 'Platform Administration',
                                subtitle: 'Multi-Tenant & System Governance',
                                isExpanded: _expandedKeys.contains('P'),
                                onToggle: () => _toggleSection('P'),
                                children: [
                                  _DrawerChildItem(
                                    title: 'Tenant Management',
                                    icon: Icons.corporate_fare_rounded,
                                    isLast: false,
                                    onTap: () => _open(
                                      context,
                                      const AdminConsoleScreen(
                                        initialTabIndex: 0,
                                      ),
                                    ),
                                  ),
                                  _DrawerChildItem(
                                    title: 'Global Integrations',
                                    icon: Icons.hub_outlined,
                                    isLast: false,
                                    onTap: () => _open(
                                      context,
                                      const VendorNodesScreen(),
                                    ),
                                  ),
                                  _DrawerChildItem(
                                    title: 'Security & System Health',
                                    icon: Icons.health_and_safety_outlined,
                                    isLast: true,
                                    onTap: () =>
                                        _open(context, const AlertsScreen()),
                                  ),
                                ],
                              ),
                            ],

                            // Notifications Menu Card
                            const SizedBox(height: 10),
                            _SmartDrawerMenuCard(
                              icon: Icons.notifications_active_rounded,
                              iconColor: const Color(0xFF00A38E),
                              iconBgColor: const Color(0xFFE6F7F5),
                              iconBorderColor: const Color(0xFFB2EBF2),
                              title: 'Notifications',
                              subtitle: 'General, Critical & Plan Alerts',
                              isExpanded: _expandedKeys.contains('N'),
                              onToggle: () => _toggleSection('N'),
                              children: [
                                _DrawerToggleChildItem(
                                  title: 'General Notifications',
                                  subtitle: 'Device push alerts',
                                  icon: Icons.devices_other_rounded,
                                  iconColor: const Color(0xFF00A38E),
                                  value:
                                      notifSettings?.generalNotifications ??
                                      true,
                                  onChanged: (val) => notifSettings
                                      ?.setGeneralNotifications(val),
                                  isLast: false,
                                ),
                                _DrawerToggleChildItem(
                                  title: 'Critical Notifications',
                                  subtitle: 'Fire, gas, water safety',
                                  icon: Icons.local_fire_department_rounded,
                                  iconColor: const Color(0xFFDC2626),
                                  badge: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SAFETY',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                  value:
                                      notifSettings?.criticalNotifications ??
                                      true,
                                  onChanged: (val) {
                                    notifSettings
                                        ?.toggleCriticalWithConfirmation(
                                          context,
                                          val,
                                        );
                                  },
                                  isLast: false,
                                ),
                                _DrawerToggleChildItem(
                                  title: 'Plan Notifications',
                                  subtitle: 'Offers & expiring plans',
                                  icon: Icons.card_giftcard_rounded,
                                  iconColor: const Color(0xFF7C3AED),
                                  value:
                                      notifSettings?.planNotifications ?? true,
                                  onChanged: (val) =>
                                      notifSettings?.setPlanNotifications(val),
                                  isLast: false,
                                ),
                                _DrawerChildItem(
                                  title: 'Notification Settings',
                                  icon: Icons.tune_rounded,
                                  isLast: true,
                                  onTap: () => _open(
                                    context,
                                    const NotificationSettingsScreen(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Individual Bottom Utility Cards
                            _DrawerBottomMenuCard(
                              icon: Icons.person_outline_rounded,
                              title: 'Profile',
                              subtitle: 'Account & Companion Avatar',
                              badgeBg: const Color(0xFFE0F2FE),
                              iconColor: const Color(0xFF0284C7),
                              onTap: () =>
                                  _open(context, const ProfileScreen()),
                            ),
                            const SizedBox(height: 10),
                            _DrawerBottomMenuCard(
                              icon: Icons.workspace_premium_rounded,
                              title: 'Subscription & Plans',
                              subtitle: 'Active Tier & Resource Limits',
                              badgeBg: const Color(0xFFFEF3C7),
                              iconColor: const Color(0xFFD97706),
                              onTap: () =>
                                  _open(context, const SubscriptionScreen()),
                            ),
                            const SizedBox(height: 10),
                            _DrawerBottomMenuCard(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              subtitle: 'App Preferences',
                              badgeBg: const Color(0xFFF1F5F9),
                              iconColor: const Color(0xFF475569),
                              onTap: () =>
                                  _open(context, const SettingsScreen()),
                            ),
                            if (role.canManageTickets) ...[
                              const SizedBox(height: 10),
                              _DrawerBottomMenuCard(
                                icon: Icons.support_agent_rounded,
                                title: 'Services',
                                subtitle: 'Tickets & Maintenance',
                                badgeBg: const Color(0xFFFEF3C7),
                                iconColor: const Color(0xFFD97706),
                                onTap: () =>
                                    _open(context, const ServicesScreen()),
                              ),
                            ],
                            const SizedBox(height: 10),

                            _DrawerBottomMenuCard(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              subtitle: 'Sign out from your account',
                              isDanger: true,
                              onTap: () => _logout(context),
                            ),

                            // Version 1.0 Footer at end of sidebar
                            const Padding(
                              padding: EdgeInsets.only(top: 18, bottom: 28),
                              child: Center(
                                child: Text(
                                  'Version 1.0',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.permanent) {
      return SizedBox(
        width: drawerWidth,
        child: Material(child: content),
      );
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      width: drawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
        child: content,
      ),
    );
  }
}

/// Hero header containing top branding and action buttons over the top section of drawer_bg.png.
class _DrawerHeroHeader extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onAlertsTap;
  final int alertCount;

  const _DrawerHeroHeader({
    required this.onHomeTap,
    required this.onAlertsTap,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 245),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, topPadding + 14, 18, 44),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Branded Logo and Title
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onHomeTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppBrandHeader.white(
                              fontSize: 22,
                              spacing: 0,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Your Home. Smarter.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.92),
                                letterSpacing: 0.2,
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
          ],
        ),
      ),
    );
  }
}

/// Identically proportioned, modern expandable HASOMI navigation card with
/// Letter Tile | Title + Subtitle | Chevron.
class _SmartDrawerMenuCard extends StatelessWidget {
  final String? letter;
  final Color? letterColor;
  final Color? letterBgColor;
  final Color? letterBorderColor;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final Color? iconBorderColor;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final Color backgroundColor;

  const _SmartDrawerMenuCard({
    this.letter,
    this.letterColor,
    this.letterBgColor,
    this.letterBorderColor,
    this.icon,
    this.iconColor,
    this.iconBgColor,
    this.iconBorderColor,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? (letterColor ?? iconColor ?? const Color(0xFF00A38E))
                    .withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main Interactive Header Row
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (letter != null) ...[
                        _DrawerLetterTile(
                          letter: letter!,
                          color: letterColor,
                          bgColor: letterBgColor,
                          borderColor: letterBorderColor,
                        ),
                        const SizedBox(width: 12),
                      ] else if (icon != null) ...[
                        _DrawerIconTile(
                          icon: icon!,
                          iconColor: iconColor,
                          bgColor: iconBgColor,
                          borderColor: iconBorderColor,
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Title and Subtitle Block
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2.5),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Smooth Animated Chevron
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF94A3B8),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expandable Nested Children Section
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded squircle icon tile for drawer menu items with custom category icons.
class _DrawerIconTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? bgColor;
  final Color? borderColor;

  const _DrawerIconTile({
    required this.icon,
    this.iconColor,
    this.bgColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFE6F7F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? const Color(0xFFB2EBF2),
          width: 1,
        ),
      ),
      child: Icon(icon, color: iconColor ?? const Color(0xFF007E72), size: 22),
    );
  }
}

/// Large rounded letter badge with soft mint background and dark teal typography.
class _DrawerLetterTile extends StatelessWidget {
  final String letter;
  final Color? color;
  final Color? bgColor;
  final Color? borderColor;

  const _DrawerLetterTile({
    required this.letter,
    this.color,
    this.bgColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFE6F7F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? const Color(0xFFB2EBF2),
          width: 1,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: color ?? const Color(0xFF007E72),
          height: 1,
        ),
      ),
    );
  }
}

/// Individual bottom utility menu card (Settings, Integrations, Admin, Logout)
/// matching the exact same modern design language.
class _DrawerBottomMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;
  final Color? badgeBg;
  final Color? iconColor;

  const _DrawerBottomMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
    this.badgeBg,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = isDanger
        ? const Color(0xFFDC2626)
        : const Color(0xFF0F172A);
    final effectiveIconColor = isDanger
        ? const Color(0xFFDC2626)
        : (iconColor ?? const Color(0xFF00A38E));
    final effectiveBadgeBg = isDanger
        ? const Color(0xFFFEE2E2)
        : (badgeBg ?? const Color(0xFFE6F7F5));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDanger ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Container Tile
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: effectiveBadgeBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDanger
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFB2EBF2),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: effectiveIconColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: isDanger
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: effectiveTitleColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDanger
                              ? const Color(0xFFEF4444).withValues(alpha: 0.85)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Arrow Chevron
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDanger
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFCBD5E1),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nested child item with custom tree connector rail and bullet node.
class _DrawerChildItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isLast;
  final VoidCallback onTap;
  final Widget? trailingBadge;

  const _DrawerChildItem({
    required this.title,
    required this.icon,
    required this.isLast,
    required this.onTap,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: [
              // Tree Connector Column
              SizedBox(
                width: 14,
                height: 34,
                child: CustomPaint(
                  painter: _TreeConnectorPainter(isLast: isLast),
                ),
              ),
              const SizedBox(width: 4),

              // Child Icon Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 15, color: const Color(0xFF00A38E)),
              ),
              const SizedBox(width: 10),

              // Child Title
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),

              if (trailingBadge != null) trailingBadge!,
            ],
          ),
        ),
      ),
    );
  }
}

class _TreeConnectorPainter extends CustomPainter {
  final bool isLast;

  const _TreeConnectorPainter({required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF86DDD1)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = const Color(0xFF00A38E)
      ..style = PaintingStyle.fill;

    final double centerX = size.width * 0.5;
    final double centerY = size.height * 0.5;

    // Vertical connecting line
    if (isLast) {
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, centerY), linePaint);
    } else {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, size.height),
        linePaint,
      );
    }

    // Circular Node
    canvas.drawCircle(Offset(centerX, centerY), 2.8, nodePaint);
  }

  @override
  bool shouldRepaint(covariant _TreeConnectorPainter oldDelegate) =>
      oldDelegate.isLast != isLast;
}

/// Subtle background decorative layer for additional depth.
class _DrawerBackgroundDecorations extends StatelessWidget {
  const _DrawerBackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AlertCountBadge extends StatelessWidget {
  final int count;

  const _AlertCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE5484D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Nested child toggle item with custom tree connector rail and switch.
class _DrawerToggleChildItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;
  final Widget? badge;

  const _DrawerToggleChildItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor = const Color(0xFF00A38E),
    required this.value,
    required this.onChanged,
    required this.isLast,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
      child: Row(
        children: [
          // Tree Connector Column
          SizedBox(
            width: 14,
            height: 36,
            child: CustomPaint(painter: _TreeConnectorPainter(isLast: isLast)),
          ),
          const SizedBox(width: 4),

          // Icon Container
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (badge != null) ...[const SizedBox(width: 4), badge!],
                  ],
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Custom Modern Switch
          _DrawerSwitch(
            value: value,
            activeColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Modern iOS-styled pill switch with smooth slide animation and distinct white thumb with drop shadow.
class _DrawerSwitch extends StatelessWidget {
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _DrawerSwitch({
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 25,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? activeColor : const Color(0xFFE2E8F0),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 3,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
