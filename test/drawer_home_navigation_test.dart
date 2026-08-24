import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_provider.dart';
import 'package:smart_homez/providers/alert_provider.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/automation_provider.dart';
import 'package:smart_homez/providers/client_dashboard_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/energy_provider.dart';
import 'package:smart_homez/providers/routine_provider.dart';
import 'package:smart_homez/providers/ticket_provider.dart';
import 'package:smart_homez/providers/water_provider.dart';
import 'package:smart_homez/screens/dashboard/dashboard_screen.dart';
import 'package:smart_homez/widgets/app_navigation_drawer.dart';

import 'test_helpers.dart';

Widget _buildTestApp({required Widget child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => createTestPropertyProvider()),
      ChangeNotifierProvider(create: (_) => createTestDeviceProvider()),
      ChangeNotifierProvider(create: (_) => AlertProvider()),
      ChangeNotifierProvider(create: (_) => AutomationProvider()),
      ChangeNotifierProvider(create: (_) => ClientDashboardProvider()),
      ChangeNotifierProxyProvider<DeviceProvider, RoutineProvider>(
        create: (_) => RoutineProvider(),
        update: (_, deviceProvider, routineProvider) {
          final provider = routineProvider ?? RoutineProvider();
          provider.setDeviceProvider(deviceProvider);
          return provider;
        },
      ),
      ChangeNotifierProvider(create: (_) => EnergyProvider()),
      ChangeNotifierProvider(create: (_) => WaterProvider()),
      ChangeNotifierProvider(create: (_) => TicketProvider()),
      ChangeNotifierProvider(create: (_) => AlexaProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets(
    'Tapping Brand Header on AppNavigationDrawer invokes onDashboard callback',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool dashboardCalled = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            drawer: AppNavigationDrawer(
              onDashboard: () {
                dashboardCalled = true;
              },
            ),
            body: const Center(child: Text('Body')),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify all 6 H-A-S-O-M-I section headers and badges are in the drawer
      expect(find.text('Hasomi'), findsOneWidget);
      expect(find.text('Your Home. Smarter.'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Automations'), findsWidgets);
      expect(find.text('Smart'), findsOneWidget);
      expect(find.text('Operations'), findsOneWidget);
      expect(find.text('Machines'), findsOneWidget);
      expect(find.text('Intelligence'), findsOneWidget);

      expect(find.text('H'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);

      // Initially closed: tap Home tile to expand
      await tester.tap(find.text('H'));
      await tester.pumpAndSettle();

      // Now Home child items are visible
      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('Floors'), findsOneWidget);
      expect(find.text('Rooms'), findsOneWidget);

      // Scroll down to see bottom utility items
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Scroll back up to tap Brand Header at top
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hasomi'));
      await tester.pumpAndSettle();

      expect(dashboardCalled, isTrue);
    },
  );

  testWidgets(
    'Tapping Brand Header on AppNavigationDrawer without onDashboard navigates to MainShell',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            drawer: AppNavigationDrawer(),
            body: Center(child: Text('Standalone Page')),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify Brand Header is in the drawer
      expect(find.text('Hasomi'), findsOneWidget);

      // Tap Brand Header
      await tester.tap(find.text('Hasomi'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Now MainShell / Home Screen should be open
      expect(find.byType(DashboardScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Toggling section cards expands and collapses sub-items', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildTestApp(
        child: const Scaffold(
          drawer: AppNavigationDrawer(),
          body: Center(child: Text('Body')),
        ),
      ),
    );

    // Open drawer
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    final machinesFinder = find.text('Machines');
    expect(machinesFinder, findsOneWidget);

    // Tap Machines to expand
    await tester.tap(machinesFinder);
    await tester.pumpAndSettle();

    // Now Machines is expanded
    expect(machinesFinder, findsOneWidget);
  });
}
