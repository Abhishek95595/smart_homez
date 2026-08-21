import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/admin/admin_console_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/automations/automations_screen.dart';
import '../screens/client_dashboard/client_dashboard_screen.dart';
import '../screens/devices/devices_screen.dart';
import '../screens/energy/energy_screen.dart';
import '../screens/environment/environment_screen.dart';
import '../screens/fire_smoke/fire_smoke_screen.dart';
import '../screens/integrations/integrations_screen.dart';
import '../screens/main_shell.dart';
import '../screens/properties/floors_screen.dart';
import '../screens/properties/homes_screen.dart';
import '../screens/properties/rooms_screen.dart';
import '../screens/scenes/routine_scene_screen.dart';
import '../screens/services_module/services_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/voice/hasomi_screen.dart';
import '../screens/water/water_screen.dart';

class AppNavigationDrawer extends StatefulWidget {
  final VoidCallback? onDashboard;
  final bool permanent;

  const AppNavigationDrawer({
    super.key,
    this.onDashboard,
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
    if (widget.permanent) {
      widget.onDashboard?.call();
      return;
    }

    if (widget.onDashboard != null) {
      Navigator.of(context).pop();
      widget.onDashboard!();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
        (route) => false,
      );
    }
  }

  void _open(BuildContext context, Widget page) {
    if (!widget.permanent) {
      Navigator.of(context).pop();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.role;
    final alerts = context.watch<AlertProvider>();

    final double drawerWidth = widget.permanent
        ? 270.0
        : (MediaQuery.sizeOf(context).width * 0.72).clamp(260.0, 290.0);

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
                  Colors.white.withValues(alpha: 0.03),
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
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Home
                            _SmartDrawerMenuCard(
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
                                  onTap: () =>
                                      _open(context, const DevicesScreen()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 2. Automations
                            _SmartDrawerMenuCard(
                              title: 'Automations',
                              subtitle: 'Scenes & Automations',
                              isExpanded: _expandedKeys.contains('A'),
                              onToggle: () => _toggleSection('A'),
                              children: [
                                _DrawerChildItem(
                                  title: 'Scenes',
                                  icon: Icons.movie_filter_outlined,
                                  isLast: false,
                                  onTap: () => _open(
                                    context,
                                    RoutineSceneScreen(
                                      themeData:
                                          kAllRoutineThemes['good_morning']!,
                                    ),
                                  ),
                                ),
                                _DrawerChildItem(
                                  title: 'Automations',
                                  icon: Icons.bolt_outlined,
                                  isLast: true,
                                  onTap: () =>
                                      _open(context, const AutomationsScreen()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 3. Smart
                            _SmartDrawerMenuCard(
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
                              title: 'Machines',
                              subtitle: 'All Connected Devices',
                              isExpanded: _expandedKeys.contains('M'),
                              onToggle: () => _toggleSection('M'),
                              children: [
                                _DrawerChildItem(
                                  title: 'Devices',
                                  icon: Icons.sensors_rounded,
                                  isLast: true,
                                  onTap: () =>
                                      _open(context, const DevicesScreen()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 6. Intelligence
                            _SmartDrawerMenuCard(
                              title: 'Intelligence',
                              subtitle: 'AI-Powered Insights',
                              isExpanded: _expandedKeys.contains('I'),
                              onToggle: () => _toggleSection('I'),
                              children: [
                                _DrawerChildItem(
                                  title: 'HASOMI Voice Assistant',
                                  icon: Icons.smart_toy_outlined,
                                  isLast: false,
                                  onTap: () =>
                                      _open(context, const HasomiScreen()),
                                ),
                                _DrawerChildItem(
                                  title: 'Activity Stream',
                                  icon: Icons.access_time_rounded,
                                  isLast: alerts.activeAlerts.isEmpty,
                                  onTap: () =>
                                      _open(context, const ActivityScreen()),
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
                            const SizedBox(height: 16),

                            // Individual Bottom Utility Cards
                            _DrawerBottomMenuCard(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              subtitle: 'App Preferences',
                              onTap: () =>
                                  _open(context, const SettingsScreen()),
                            ),
                            const SizedBox(height: 10),

                            _DrawerBottomMenuCard(
                              icon: Icons.extension_outlined,
                              title: 'Integrations',
                              subtitle: 'Third Party Services',
                              onTap: () =>
                                  _open(context, const IntegrationsScreen()),
                            ),
                            if (role.canAccessAdminConsole) ...[
                              const SizedBox(height: 10),
                              _DrawerBottomMenuCard(
                                icon: Icons.admin_panel_settings_outlined,
                                title: 'Admin Console',
                                subtitle: 'Manage Roles & System',
                                onTap: () =>
                                    _open(context, const AdminConsoleScreen()),
                              ),
                            ],
                            if (role.canManageTickets) ...[
                              const SizedBox(height: 10),
                              _DrawerBottomMenuCard(
                                icon: Icons.support_agent_rounded,
                                title: 'Services',
                                subtitle: 'Tickets & Maintenance',
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
                            const SizedBox(height: 18),
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
        borderRadius: BorderRadius.horizontal(right: Radius.circular(36)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(36)),
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
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.38),
                            width: 1.4,
                          ),
                        ),
                        child: const Icon(
                          Icons.hub_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Smart Homez',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.6,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Your Home. Smarter.',
                              style: TextStyle(
                                fontSize: 13.5,
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

            // Header Right Action Buttons: Home & Notification
            // Header Right Action Button: Home
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onHomeTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 19,
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

/// Identically proportioned, expandable HASOMI navigation card with
/// Letter Tile | Divider | Icon | Title + Subtitle | Chevron.
class _SmartDrawerMenuCard extends StatelessWidget {
  final String? letter;
  final IconData? icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _SmartDrawerMenuCard({
    this.letter,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isExpanded
            ? const Color(0xFFFAFEFE)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isExpanded ? const Color(0xFFC7EFE9) : const Color(0xFFE5F1EF),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main Interactive Header Row
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 74),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (letter != null) ...[
                        _DrawerLetterTile(letter: letter!),
                        const SizedBox(width: 10),
                      ],

                      if (icon != null) ...[
                        Icon(icon, color: const Color(0xFF00A38E), size: 26),
                        const SizedBox(width: 10),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
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
                          color: Color(0xFF64748B),
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
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
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

/// Large rounded letter badge with soft mint background and dark teal typography.
class _DrawerLetterTile extends StatelessWidget {
  final String letter;

  const _DrawerLetterTile({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F8F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD3F2EC), width: 1),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF007E72),
          height: 1,
        ),
      ),
    );
  }
}

/// Individual bottom utility menu card (Settings, Integrations, Admin, Logout)
/// matching the exact same design language and aspect ratio as main cards.
class _DrawerBottomMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _DrawerBottomMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDanger
        ? const Color(0xFFE5484D)
        : const Color(0xFF0F172A);
    final iconColor = isDanger
        ? const Color(0xFFE5484D)
        : const Color(0xFF00A38E);
    final badgeBg = isDanger
        ? const Color(0xFFFFECEE)
        : const Color(0xFFE7F8F5);
    final cardBg = isDanger
        ? const Color(0xFFFFFDFC)
        : Colors.white.withValues(alpha: 0.98);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDanger ? const Color(0xFFFFD4D8) : const Color(0xFFE5F1EF),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon Container Tile
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDanger
                          ? const Color(0xFFFFCBD1)
                          : const Color(0xFFD3F2EC),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 12),

                // Vertical Divider
                Container(
                  width: 1.2,
                  height: 42,
                  color: const Color(0xFFE1E8EA),
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
                          fontSize: 18,
                          fontWeight: isDanger
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDanger
                              ? const Color(0xFFE5484D).withValues(alpha: 0.8)
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
                  size: 15,
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
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Row(
            children: [
              // Tree Connector Column
              SizedBox(
                width: 32,
                height: 36,
                child: CustomPaint(
                  painter: _TreeConnectorPainter(isLast: isLast),
                ),
              ),
              const SizedBox(width: 4),

              // Child Icon Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: const Color(0xFF00A38E)),
              ),
              const SizedBox(width: 12),

              // Child Title
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),

              ?trailingBadge,
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

    final double centerX = size.width * 0.55;
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
    canvas.drawCircle(Offset(centerX, centerY), 3.2, nodePaint);
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
