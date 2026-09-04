import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/user_role.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../providers/property_provider.dart';
import 'automations/automations_screen.dart';
import 'activity/activity_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'devices/devices_screen.dart';
import 'profile/profile_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/hasomi_bottom_voice_bar.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;
  bool _isDrawerOpen = false;
  final GlobalKey<HasomiBottomVoiceBarState> _voiceBarKey =
      GlobalKey<HasomiBottomVoiceBarState>();

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
    _index = widget.initialIndex;
    // Fix 3 & 4: Ensure state updates and SSE start only after hierarchy loading succeeds
    // In this repaired version, the LoginScreen (or AuthProvider.loginWithApi)
    // now completes syncFromApi BEFORE navigating to MainShell.
    // We only trigger real-time features here.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final deviceProvider = context.read<DeviceProvider>();
      final propertyProvider = context.read<PropertyProvider>();

      final clientUuid =
          auth.resolvedClientUuid ?? '6782976c-e9a4-41c9-a754-05e4ba0a97b2';
      propertyProvider.setClientId(clientUuid);
      propertyProvider.syncFromApi(clientUuid);
      deviceProvider.syncFromApi(clientUuid);
      deviceProvider.startRealtimeSync(clientUuid);

      if (auth.token != null) {
        debugPrint('[MainShell] Activating real-time services...');
        deviceProvider.startRealtime(auth.token!);
        context.read<AlertProvider>().listenRealtime();
      }
    });
  }

  DeviceProvider? _deviceProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // Graceful cleanup
    _deviceProvider?.stopRealtime();
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
        icon: Icons.access_time_rounded,
        label: 'Activity',
        page: const ActivityScreen(),
        navigatorKey: _navigatorKeys[3],
      ),
      _Tab(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        page: const ProfileScreen(),
        navigatorKey: _navigatorKeys[4],
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

        // If the current tab has a page in its navigation stack,
        // go back to that previous page.
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return;
        }

        // If there is no previous page, exit/minimize the Android app.
        // Do NOT redirect to Home.
        SystemNavigator.pop();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1100;

          return Scaffold(
            drawer: desktop
                ? null
                : AppNavigationDrawer(
                    onDashboard: () => _onTabTapped(0),
                    onTabSelected: (idx) => _onTabTapped(idx),
                  ),
            body: desktop
                ? Row(
                    children: [
                      AppNavigationDrawer(
                        permanent: true,
                        onDashboard: () => _onTabTapped(0),
                        onTabSelected: (idx) => _onTabTapped(idx),
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

            onDrawerChanged: (isOpened) {
              if (_isDrawerOpen != isOpened) {
                setState(() => _isDrawerOpen = isOpened);
              }
            },
            floatingActionButton: (safeIndex == 0 && !_isDrawerOpen && !desktop)
                ? FloatingActionButton.extended(
                    heroTag: 'hasomi_voice_fab',
                    onPressed: () {
                      _voiceBarKey.currentState?.triggerVoiceListening();
                    },
                    backgroundColor: const Color(0xFF0F172A),
                    elevation: 4,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF3B82F6)],
                        ),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    label: const Text(
                      'HASOMI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                : null,

            bottomNavigationBar: desktop
                ? null
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HasomiBottomVoiceBar(key: _voiceBarKey),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(color: AppColors.divider, width: 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x06000000),
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
                                    splashColor: AppColors.primarySoft,
                                    highlightColor: Colors.transparent,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primarySoft
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Icon(
                                                tab.icon,
                                                color: isSelected
                                                    ? AppColors.primaryDark
                                                    : AppColors.textSecondary,
                                                size: 24,
                                              ),
                                              if (tab.label == 'Activity' &&
                                                  criticalCount > 0)
                                                Positioned(
                                                  top: -6,
                                                  right: -9,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: AppColors
                                                              .critical,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 15,
                                                          minHeight: 15,
                                                        ),
                                                    child: Text(
                                                      '$criticalCount',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        height: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            tab.label,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.primaryDark
                                                  : AppColors.textSecondary,
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                            ),
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
                    ],
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
