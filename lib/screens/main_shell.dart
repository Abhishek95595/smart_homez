import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import 'activity/activity_screen.dart';
import 'alerts/alerts_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'devices/devices_screen.dart';
import 'energy/energy_screen.dart';
import '../widgets/app_navigation_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    context.read<DeviceProvider>().startRealtime();
    context.read<AlertProvider>().listenRealtime();
  }

  @override
  void dispose() {
    context.read<DeviceProvider>().stopRealtime();
    super.dispose();
  }

  /// Builds the role-aware tab set. Energy stays permission-aware, while
  /// Activity is always the final tab so it remains in the lower-right corner.
  List<_Tab> _tabsFor(UserRole role) {
    return [
      const _Tab(
        icon: Icons.home_rounded,
        label: 'Home',
        page: DashboardScreen(),
      ),
      const _Tab(
        icon: Icons.devices_other_rounded,
        label: 'Devices',
        page: DevicesScreen(),
      ),
      const _Tab(
        icon: Icons.notifications_active_rounded,
        label: 'Alerts',
        page: AlertsScreen(),
      ),
      if (role.canViewEnergy)
        const _Tab(
          icon: Icons.bolt_rounded,
          label: 'Energy',
          page: EnergyScreen(),
        ),
      const _Tab(
        icon: Icons.history_rounded,
        label: 'Activity',
        page: ActivityScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = context.watch<AlertProvider>().criticalActiveCount;
    final role = context.watch<AuthProvider>().role;
    final tabs = _tabsFor(role);
    final safeIndex = _index < tabs.length ? _index : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1100;
        final content = IndexedStack(
          index: safeIndex,
          children: tabs.map((t) => t.page).toList(),
        );

        return Scaffold(
          body: desktop
              ? Row(
                  children: [
                    AppNavigationDrawer(
                      permanent: true,
                      onDashboard: () => setState(() => _index = 0),
                    ),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: desktop
              ? null
              : BottomNavigationBar(
                  currentIndex: safeIndex,
                  onTap: (i) => setState(() => _index = i),
                  items: tabs
                      .map(
                        (t) => BottomNavigationBarItem(
                          icon: t.label == 'Alerts'
                              ? Badge(
                                  isLabelVisible: criticalCount > 0,
                                  label: Text('$criticalCount'),
                                  backgroundColor: Colors.red,
                                  child: Icon(t.icon),
                                )
                              : Icon(t.icon),
                          label: t.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final Widget page;
  const _Tab({required this.icon, required this.label, required this.page});
}
