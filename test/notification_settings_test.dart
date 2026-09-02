import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/alert_provider.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/automation_provider.dart';
import 'package:smart_homez/providers/client_dashboard_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/energy_provider.dart';
import 'package:smart_homez/providers/family_provider.dart';
import 'package:smart_homez/providers/notification_settings_provider.dart';
import 'package:smart_homez/providers/profile_provider.dart';
import 'package:smart_homez/providers/routine_provider.dart';
import 'package:smart_homez/providers/theme_provider.dart';
import 'package:smart_homez/providers/ticket_provider.dart';
import 'package:smart_homez/providers/water_provider.dart';
import 'package:smart_homez/screens/settings/notification_settings_screen.dart';
import 'package:smart_homez/widgets/app_navigation_drawer.dart';

import 'test_helpers.dart';

Widget _buildTestApp({
  required Widget child,
  NotificationSettingsProvider? notifProvider,
}) {
  SharedPreferences.setMockInitialValues({});
  final authProvider = AuthProvider();
  authProvider.setUserForTesting(
    const AppUser(
      id: 'test_user_id',
      email: 'tester@example.com',
      name: 'Aditya Tester',
      phone: '+919876543210',
      role: UserRole.superAdmin,
      tenantId: 'tenant-123',
      avatarInitials: 'AT',
    ),
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
      ChangeNotifierProvider(create: (_) => WaterProvider()),
      ChangeNotifierProvider(create: (_) => TicketProvider()),
      ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider.value(
        value: notifProvider ?? NotificationSettingsProvider(),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationSettingsProvider Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial defaults are all true', () {
      final provider = NotificationSettingsProvider();
      expect(provider.generalNotifications, isTrue);
      expect(provider.criticalNotifications, isTrue);
      expect(provider.planNotifications, isTrue);
    });

    test('Toggling general and plan notifications updates state', () async {
      final provider = NotificationSettingsProvider();
      await provider.setGeneralNotifications(false);
      expect(provider.generalNotifications, isFalse);

      await provider.setPlanNotifications(false);
      expect(provider.planNotifications, isFalse);

      await provider.setGeneralNotifications(true);
      expect(provider.generalNotifications, isTrue);
    });

    test('Direct setCriticalNotifications updates state', () async {
      final provider = NotificationSettingsProvider();
      await provider.setCriticalNotifications(false);
      expect(provider.criticalNotifications, isFalse);

      await provider.setCriticalNotifications(true);
      expect(provider.criticalNotifications, isTrue);
    });
  });

  group('NotificationSettingsScreen Widget Tests', () {
    testWidgets('Renders all 3 notification channels', (tester) async {
      final notifProvider = NotificationSettingsProvider();

      await tester.pumpWidget(
        _buildTestApp(
          child: const NotificationSettingsScreen(),
          notifProvider: notifProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('General Notifications'), findsOneWidget);
      expect(find.text('Critical Notifications'), findsOneWidget);
      expect(find.text('Plan Notifications'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(
        find.textContaining('fire alarm, gas leak & water overflow'),
        findsOneWidget,
      );
    });

    testWidgets('Toggling General Notifications switches state', (
      tester,
    ) async {
      final notifProvider = NotificationSettingsProvider();

      await tester.pumpWidget(
        _buildTestApp(
          child: const NotificationSettingsScreen(),
          notifProvider: notifProvider,
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));

      // Toggle general notifications
      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();

      expect(notifProvider.generalNotifications, isFalse);
    });

    testWidgets(
      'Toggling Critical Notifications to OFF shows safety warning popup and Keep Enabled retains it ON',
      (tester) async {
        final notifProvider = NotificationSettingsProvider();

        await tester.pumpWidget(
          _buildTestApp(
            child: const NotificationSettingsScreen(),
            notifProvider: notifProvider,
          ),
        );
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);

        // Tap Critical Notifications switch to turn OFF
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();

        // Verify Warning Popup appears
        expect(find.text('Disable Critical Alerts?'), findsOneWidget);
        expect(find.text('Fire & Smoke Detection'), findsOneWidget);
        expect(find.text('Gas Leak & Thermal Warnings'), findsOneWidget);
        expect(find.text('Water Overflow & Tank Faults'), findsOneWidget);
        expect(find.text('Keep Enabled'), findsOneWidget);
        expect(find.text('Disable Anyway'), findsOneWidget);

        // Tap "Keep Enabled"
        await tester.tap(find.text('Keep Enabled'));
        await tester.pumpAndSettle();

        // Popup dismissed, state still true
        expect(find.text('Disable Critical Alerts?'), findsNothing);
        expect(notifProvider.criticalNotifications, isTrue);
      },
    );

    testWidgets(
      'Toggling Critical Notifications to OFF and tapping Disable Anyway turns it OFF',
      (tester) async {
        final notifProvider = NotificationSettingsProvider();

        await tester.pumpWidget(
          _buildTestApp(
            child: const NotificationSettingsScreen(),
            notifProvider: notifProvider,
          ),
        );
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);

        // Tap Critical Notifications switch to turn OFF
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();

        // Tap "Disable Anyway"
        await tester.tap(find.text('Disable Anyway'));
        await tester.pumpAndSettle();

        // Popup dismissed, state is now false
        expect(find.text('Disable Critical Alerts?'), findsNothing);
        expect(notifProvider.criticalNotifications, isFalse);
      },
    );
  });

  group('AppNavigationDrawer Notifications Integration Tests', () {
    testWidgets(
      'AppNavigationDrawer displays Notifications card and toggles expand',
      (tester) async {
        final notifProvider = NotificationSettingsProvider();

        await tester.pumpWidget(
          _buildTestApp(
            child: const AppNavigationDrawer(permanent: true),
            notifProvider: notifProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Scroll to Notifications card
        final notifCard = find.text('Notifications');
        expect(notifCard, findsWidgets);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(notifCard.first);
        await tester.pumpAndSettle();

        // Verify child toggle items are visible
        expect(find.text('General Notifications'), findsOneWidget);
        expect(find.text('Critical Notifications'), findsOneWidget);
        expect(find.text('Plan Notifications'), findsOneWidget);
        expect(find.text('SAFETY'), findsOneWidget);
      },
    );
  });
}
