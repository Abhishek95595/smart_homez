import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import 'automations/automations_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'devices/devices_screen.dart';
import 'profile/profile_screen.dart';
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
    return [
      _Tab(
        icon: Icons.home_rounded,
        label: 'Home',
        page: const DashboardScreen(),
        navigatorKey: _navigatorKeys[0],
      ),
      _Tab(
        icon: Icons.grid_view_rounded,
        label: 'Devices',
        page: const DevicesScreen(),
        navigatorKey: _navigatorKeys[1],
      ),
      _Tab(
        icon: Icons.bolt_rounded,
        label: 'Automations',
        page: const AutomationsScreen(),
        navigatorKey: _navigatorKeys[2],
      ),
      _Tab(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        page: const ProfileScreen(),
        navigatorKey: _navigatorKeys[3],
      ),
    ];
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
                : Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFE8ECEF), width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Container(
                        height: 74,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: List.generate(tabs.length, (idx) {
                            final tab = tabs[idx];
                            final isSelected = safeIndex == idx;
                            return Expanded(
                              child: InkWell(
                                onTap: () => _onTabTapped(idx),
                                splashColor: const Color(0x1000A38E),
                                highlightColor: Colors.transparent,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          tab.icon,
                                          color: isSelected
                                              ? const Color(0xFF00A38E)
                                              : const Color(0xFF64748B),
                                          size: 26,
                                        ),
                                        if (tab.label == 'Alerts' &&
                                            criticalCount > 0)
                                          Positioned(
                                            top: -3,
                                            right: -6,
                                            child: Container(
                                              padding: const EdgeInsets.all(
                                                3.5,
                                              ),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFE53E3E),
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                '$criticalCount',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      tab.label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF00A38E)
                                            : const Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      height: 0,
                                      width: 0,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF00A38E)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
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
