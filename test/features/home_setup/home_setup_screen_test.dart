import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_homez/features/home_setup/data/home_setup_service.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_request.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_response.dart';
import 'package:smart_homez/features/home_setup/providers/home_setup_provider.dart';
import 'package:smart_homez/features/home_setup/screens/home_setup_screen.dart';
import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/device.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/client_dashboard_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/energy_provider.dart';
import 'package:smart_homez/providers/family_provider.dart';
import 'package:smart_homez/providers/property_provider.dart';
import 'package:smart_homez/services/device_repository.dart';
import 'package:smart_homez/services/property_repository.dart';

class MockSetupService extends HomeSetupService {
  @override
  Future<HomeSetupResult> setupHomeFromTemplate(
    HomeSetupRequest request,
  ) async {
    return HomeSetupResult(
      home: CreatedHome(id: 'home_test_123', name: request.homeName),
      rooms: [
        CreatedRoom(id: 'room_1', name: 'Living Room', type: 'Living Room'),
        CreatedRoom(id: 'room_2', name: 'Master Bedroom', type: 'Bedroom'),
        CreatedRoom(id: 'room_3', name: 'Kitchen', type: 'Kitchen'),
      ],
    );
  }
}

class FakeRepo implements PropertyRepository {
  @override
  Future<PropertySnapshot> load() async =>
      const PropertySnapshot(properties: [], floors: [], rooms: []);

  @override
  Future<void> save(PropertySnapshot snapshot) async {}
}

class FakeDeviceRepo implements DeviceRepository {
  @override
  Future<List<Device>?> load() async => [];

  @override
  Future<void> save(List<Device> devices) async {}
}

Widget createTestHarness({
  required HomeSetupProvider setupProvider,
  UserRole role = UserRole.facilityManager,
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
      ChangeNotifierProvider.value(value: setupProvider),
      ChangeNotifierProvider(
        create: (_) => PropertyProvider(repository: FakeRepo()),
      ),
      ChangeNotifierProvider(
        create: (_) => DeviceProvider(repository: FakeDeviceRepo()),
      ),
      ChangeNotifierProvider(create: (_) => EnergyProvider()),
      ChangeNotifierProvider(create: (_) => ClientDashboardProvider()),
      ChangeNotifierProvider(create: (_) => FamilyProvider()),
    ],
    child: const MaterialApp(home: HomeSetupScreen()),
  );
}

void main() {
  testWidgets(
    'Step 1: Renders Property Info step with Category selector and inputs',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = MockSetupService();
      final provider = HomeSetupProvider(setupService: service);

      await tester.pumpWidget(createTestHarness(setupProvider: provider));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Property'), findsOneWidget);
      expect(find.text("Let's set up your space"), findsOneWidget);
      expect(find.text('Step 1 of 4 — Property'), findsOneWidget);
      expect(find.text('Residential'), findsOneWidget);
      expect(find.text('Commercial'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    },
  );

  testWidgets(
    'Navigates through 4 steps: Property -> Layout -> Rooms -> Review',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = MockSetupService();
      final provider = HomeSetupProvider(setupService: service);

      await tester.pumpWidget(createTestHarness(setupProvider: provider));
      await tester.pump(const Duration(milliseconds: 300));

      // Enter property name
      provider.setPropertyName('Sunset Villa');
      await tester.pump(const Duration(milliseconds: 300));

      // Advance Step 1 -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Step 2 of 4 — Layout'), findsOneWidget);
      expect(find.text('Choose the closest layout'), findsOneWidget);

      // Advance Step 2 -> Step 3
      await tester.tap(find.text('Review rooms'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Step 3 of 4 — Rooms'), findsOneWidget);
      expect(find.text('Review your rooms'), findsOneWidget);

      // Advance Step 3 -> Step 4
      await tester.tap(find.text('Review setup'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Step 4 of 4 — Review'), findsOneWidget);
      expect(find.text('Everything look right?'), findsOneWidget);
      expect(find.text('Create Property'), findsOneWidget);
    },
  );
}
