import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../providers/property_provider.dart';
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
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    // Fix 3 & 4: Ensure state updates and SSE start only after hierarchy loading succeeds
    // In this repaired version, the LoginScreen (or AuthProvider.loginWithApi)
    // now completes syncFromApi BEFORE navigating to MainShell.
    // We only trigger real-time features here.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final deviceProvider = context.read<DeviceProvider>();

      // SSE Gating: Only start if we have a valid token AND successful resolution
      if (auth.token != null && auth.resolvedClientUuid != null) {
        debugPrint('[MainShell] Activating real-time services...');
        deviceProvider.startRealtime(auth.token!);
        context.read<AlertProvider>().listenRealtime();
      }
    });
  }

  @override
  void dispose() {
    // Graceful cleanup
    context.read<DeviceProvider>().stopRealtime();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_index == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _index = index);
    }
  }

  List<_Tab> _tabsFor(UserRole role) {
    final List<_Tab> tabs = [
      _Tab(
        icon: Icons.home_rounded,
        label: 'Home',
        page: const DashboardScreen(),
        navigatorKey: _navigatorKeys[0],
      ),
      _Tab(
        icon: Icons.devices_other_rounded,
        label: 'Devices',
        page: const DevicesScreen(),
        navigatorKey: _navigatorKeys[1],
      ),
      _Tab(
        icon: Icons.notifications_active_rounded,
        label: 'Alerts',
        page: const AlertsScreen(),
        navigatorKey: _navigatorKeys[2],
      ),
    ];

    var nextIdx = 3;
    if (role.canViewEnergy) {
      tabs.add(
        _Tab(
          icon: Icons.bolt_rounded,
          label: 'Energy',
          page: const EnergyScreen(),
          navigatorKey: _navigatorKeys[nextIdx++],
        ),
      );
    }

    tabs.add(
      _Tab(
        icon: Icons.history_rounded,
        label: 'Activity',
        page: const ActivityScreen(),
        navigatorKey: _navigatorKeys[nextIdx],
      ),
    );

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = context.watch<AlertProvider>().criticalActiveCount;
    final auth = context.watch<AuthProvider>();
    final role = auth.role;

    // Fix 3: MOVED setClientId out of build() and into login logic/initState callback
    // context.read<PropertyProvider>().setClientId(auth.resolvedClientId);

    final tabs = _tabsFor(role);
    final safeIndex = _index < tabs.length ? _index : 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final NavigatorState? navigator =
            _navigatorKeys[safeIndex].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else {
          if (safeIndex != 0) {
            setState(() => _index = 0);
          }
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1100;

          return Scaffold(
            drawer: desktop ? null : const AppNavigationDrawer(),
            body: desktop
                ? Row(
                    children: [
                      AppNavigationDrawer(
                        permanent: true,
                        onDashboard: () => _onTabTapped(0),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: safeIndex,
                          children: tabs
                              .map((t) => _TabNavigator(tab: t))
                              .toList(),
                        ),
                      ),
                    ],
                  )
                : IndexedStack(
                    index: safeIndex,
                    children: tabs.map((t) => _TabNavigator(tab: t)).toList(),
                  ),
            bottomNavigationBar: desktop
                ? null
                : BottomNavigationBar(
                    currentIndex: safeIndex,
                    onTap: _onTabTapped,
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
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  final _Tab tab;
  const _TabNavigator({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: tab.navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (context) => tab.page);
      },
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final Widget page;
  final GlobalKey<NavigatorState> navigatorKey;
  const _Tab({
    required this.icon,
    required this.label,
    required this.page,
    required this.navigatorKey,
  });
}
