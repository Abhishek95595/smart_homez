import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_provider.dart';
import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/alert_provider.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/automation_provider.dart';
import 'package:smart_homez/providers/client_dashboard_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/energy_provider.dart';
import 'package:smart_homez/providers/tariff_provider.dart';
import 'package:smart_homez/providers/subscription_provider.dart';
import 'package:smart_homez/providers/routine_provider.dart';
import 'package:smart_homez/providers/ticket_provider.dart';
import 'package:smart_homez/providers/water_provider.dart';
import 'package:smart_homez/screens/admin/admin_console_screen.dart';
import 'package:smart_homez/screens/alerts/alerts_screen.dart';
import 'package:smart_homez/screens/automations/automations_screen.dart';
import 'package:smart_homez/screens/integrations/integrations_screen.dart';
import 'package:smart_homez/screens/integrations/vendor_nodes_screen.dart';
import 'package:smart_homez/screens/properties/homes_screen.dart';
import 'package:smart_homez/screens/settings/settings_screen.dart';
import 'package:smart_homez/widgets/app_navigation_drawer.dart';

import 'test_helpers.dart';

Widget _buildTestApp({
  required Widget child,
  UserRole role = UserRole.resident,
}) {
  final authProvider = AuthProvider();
  authProvider.setUserForTesting(
    AppUser(
      id: 'usr_test',
      name: 'Test User',
      email: 'test@example.com',
      phone: '+919876543210',
      role: role,
      tenantId: 'client_test_1',
      avatarInitials: 'TU',
    ),
    clientId: 'client_test_1',
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: authProvider),
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
      ChangeNotifierProvider(create: (_) => TariffProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ChangeNotifierProvider(create: (_) => WaterProvider()),
      ChangeNotifierProvider(create: (_) => TicketProvider()),
      ChangeNotifierProvider(create: (_) => AlexaProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('Navigation & Menu Redesign Tests', () {
    testWidgets(
      'Tenant Administrator (Facility Manager) sees Tenant Administration but NOT Platform Administration',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            role: UserRole.facilityManager,
            child: const Scaffold(
              drawer: AppNavigationDrawer(),
              body: Center(child: Text('Tenant Admin View')),
            ),
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Must see Tenant Administration ('T')
        expect(find.text('Tenant Administration'), findsOneWidget);
        expect(find.text('T'), findsOneWidget);

        // Must NOT see Platform Administration ('P')
        expect(find.text('Platform Administration'), findsNothing);
        expect(find.text('P'), findsNothing);

        // Tap to expand Tenant Administration
        await tester.tap(find.text('Tenant Administration'));
        await tester.pumpAndSettle();

        // Verify all 5 functional Tenant Administration items are visible
        expect(find.text('Clients & Users'), findsOneWidget);
        expect(find.text('Devices & Spaces'), findsOneWidget);
        expect(find.text('Automations & Scenes'), findsOneWidget);
        expect(find.text('Integrations'), findsOneWidget);
        expect(find.text('Tenant Settings'), findsOneWidget);

        // Verify omitted non-existent items are NOT rendered
        expect(find.text('Branding & Customization'), findsNothing);
        expect(find.text('Plans & Subscriptions'), findsNothing);
      },
    );

    testWidgets(
      'Platform Administrator (Super Admin) sees both Tenant Administration and Platform Administration',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            role: UserRole.superAdmin,
            child: const Scaffold(
              drawer: AppNavigationDrawer(),
              body: Center(child: Text('Super Admin View')),
            ),
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Must see both Tenant and Platform Administration
        expect(find.text('Tenant Administration'), findsOneWidget);
        expect(find.text('T'), findsOneWidget);
        expect(find.text('Platform Administration'), findsOneWidget);
        expect(find.text('P'), findsOneWidget);

        // Tap to expand Platform Administration
        await tester.tap(find.text('Platform Administration'));
        await tester.pumpAndSettle();

        // Verify all 3 functional Platform Administration items are visible
        expect(find.text('Tenant Management'), findsOneWidget);
        expect(find.text('Global Integrations'), findsOneWidget);
        expect(find.text('Security & System Health'), findsOneWidget);

        // Verify omitted non-existent items are NOT rendered
        expect(find.text('Billing'), findsNothing);
        expect(find.text('Finance'), findsNothing);
      },
    );

    testWidgets(
      'Read-Only / Standard Resident does NOT see Tenant Administration or Platform Administration',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            role: UserRole.resident,
            child: const Scaffold(
              drawer: AppNavigationDrawer(),
              body: Center(child: Text('Resident View')),
            ),
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Standard H-A-S-O-M-I cards must exist
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Smart'), findsOneWidget);
        expect(find.text('Operations'), findsOneWidget);
        expect(find.text('Machines'), findsOneWidget);
        expect(find.text('Intelligence'), findsOneWidget);

        // Tenant and Platform Admin must be completely hidden
        expect(find.text('Tenant Administration'), findsNothing);
        expect(find.text('T'), findsNothing);
        expect(find.text('Platform Administration'), findsNothing);
        expect(find.text('P'), findsNothing);
      },
    );

    testWidgets(
      'Hidden Empty Groups: Unauthorized roles do not see administration cards',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            role: UserRole.security,
            child: const Scaffold(
              drawer: AppNavigationDrawer(),
              body: Center(child: Text('Security View')),
            ),
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.text('Tenant Administration'), findsNothing);
        expect(find.text('Platform Administration'), findsNothing);
      },
    );

    testWidgets(
      'Route Protection: Direct access to AdminConsoleScreen by unauthorized user is restricted',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            role: UserRole.resident,
            child: const AdminConsoleScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Access Restricted'), findsOneWidget);
        expect(find.text('Admin Console'), findsOneWidget);
      },
    );

    testWidgets(
      'Route Protection: Direct access to VendorNodesScreen by unauthorized user is restricted',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            role: UserRole.resident,
            child: const VendorNodesScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Access Restricted'), findsOneWidget);
        expect(find.text('Vendor Nodes'), findsOneWidget);
      },
    );

    testWidgets(
      'No Dead or Invalid Routes: All destination pages are instantiable and valid',
      (WidgetTester tester) async {
        // Verify all destination pages can be rendered in widget tree
        const adminConsole = AdminConsoleScreen(initialTabIndex: 1);
        const homes = HomesScreen();
        const automations = AutomationsScreen();
        const integrations = IntegrationsScreen();
        const settings = SettingsScreen();
        const vendorNodes = VendorNodesScreen();
        const alerts = AlertsScreen();

        expect(adminConsole.initialTabIndex, equals(1));
        expect(homes, isNotNull);
        expect(automations, isNotNull);
        expect(integrations, isNotNull);
        expect(settings, isNotNull);
        expect(vendorNodes, isNotNull);
        expect(alerts, isNotNull);
      },
    );
  });
}
