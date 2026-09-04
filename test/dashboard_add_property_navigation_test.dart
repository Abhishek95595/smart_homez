import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_homez/features/home_setup/providers/home_setup_provider.dart';
import 'package:smart_homez/features/home_setup/screens/home_setup_screen.dart';
import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/device.dart';
import 'package:smart_homez/models/property_hierarchy.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/alert_provider.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/automation_provider.dart';
import 'package:smart_homez/providers/client_dashboard_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/client_notification_provider.dart';
import 'package:smart_homez/providers/energy_provider.dart';
import 'package:smart_homez/providers/family_provider.dart';
import 'package:smart_homez/providers/property_provider.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_provider.dart';
import 'package:smart_homez/providers/notification_settings_provider.dart';
import 'package:smart_homez/providers/profile_provider.dart';
import 'package:smart_homez/providers/routine_provider.dart';
import 'package:smart_homez/providers/scene_provider.dart';
import 'package:smart_homez/providers/subscription_provider.dart';
import 'package:smart_homez/providers/tariff_provider.dart';
import 'package:smart_homez/providers/ticket_provider.dart';
import 'package:smart_homez/providers/water_provider.dart';
import 'package:smart_homez/screens/dashboard/dashboard_screen.dart';
import 'package:smart_homez/services/device_repository.dart';
import 'package:smart_homez/services/property_repository.dart';

class FakePropertyRepository implements PropertyRepository {
  final List<ManagedProperty> properties;

  FakePropertyRepository([this.properties = const []]);

  @override
  Future<PropertySnapshot> load() async => PropertySnapshot(
    properties: properties,
    floors: const [],
    rooms: const [],
  );

  @override
  Future<void> save(PropertySnapshot snapshot) async {}
}

class FakeDeviceRepository implements DeviceRepository {
  @override
  Future<List<Device>?> load() async => [];

  @override
  Future<void> save(List<Device> devices) async {}
}

Widget createDashboardHarness({
  required PropertyProvider propertyProvider,
  required DeviceProvider deviceProvider,
  required HomeSetupProvider setupProvider,
}) {
  final authProvider = AuthProvider();
  authProvider.setUserForTesting(
    const AppUser(
      id: 'usr_1',
      name: 'Aditya',
      email: 'aditya@example.com',
      phone: '1234567890',
      role: UserRole.resident,
      tenantId: 'tenant_1',
      avatarInitials: 'A',
    ),
    clientId: 'tenant_1',
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider.value(value: setupProvider),
      ChangeNotifierProvider.value(value: propertyProvider),
      ChangeNotifierProvider.value(value: deviceProvider),
      ChangeNotifierProvider(create: (_) => AlertProvider()),
      ChangeNotifierProvider(create: (_) => AutomationProvider()),
      ChangeNotifierProvider(create: (_) => ClientDashboardProvider()),
      ChangeNotifierProxyProvider<DeviceProvider, RoutineProvider>(
        create: (_) => RoutineProvider(),
        update: (_, devProv, routineProv) {
          final p = routineProv ?? RoutineProvider();
          p.setDeviceProvider(devProv);
          return p;
        },
      ),
      ChangeNotifierProvider(create: (_) => EnergyProvider()),
      ChangeNotifierProvider(create: (_) => WaterProvider()),
      ChangeNotifierProvider(create: (_) => TicketProvider()),
      ChangeNotifierProvider(create: (_) => AlexaProvider()),
      ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => TariffProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
      ChangeNotifierProvider(create: (_) => ClientNotificationProvider()),
      ChangeNotifierProvider(create: (_) => SceneProvider()),
    ],
    child: MaterialApp(
      home: const DashboardScreen(),
      routes: {'/homes/setup': (context) => const HomeSetupScreen()},
    ),
  );
}

void main() {
  testWidgets(
    'Dashboard empty-state Add Property button opens 4-step HomeSetupScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final setupProvider = HomeSetupProvider();
      final propertyProvider = PropertyProvider(
        repository: FakePropertyRepository([]),
      );
      final deviceProvider = DeviceProvider(repository: FakeDeviceRepository());

      await tester.pumpWidget(
        createDashboardHarness(
          propertyProvider: propertyProvider,
          deviceProvider: deviceProvider,
          setupProvider: setupProvider,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Your First Property'), findsOneWidget);

      // Tap "Add Your First Property" card
      await tester.tap(find.text('Add Your First Property'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeSetupScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Dashboard Add Property card (with existing property) opens 4-step HomeSetupScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final setupProvider = HomeSetupProvider();
      final propertyProvider = PropertyProvider(
        repository: FakePropertyRepository([
          const ManagedProperty(
            id: 'prop_1',
            name: 'Greenwood Villa',
            address: '123 Palm St',
            category: 'Residential',
            propertyType: 'Villa',
          ),
        ]),
      );
      final deviceProvider = DeviceProvider(repository: FakeDeviceRepository());

      await tester.pumpWidget(
        createDashboardHarness(
          propertyProvider: propertyProvider,
          deviceProvider: deviceProvider,
          setupProvider: setupProvider,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Property'), findsOneWidget);

      // Tap "Add Property" card
      await tester.tap(find.text('Add Property'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeSetupScreen), findsOneWidget);
    },
  );
}
