import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_homez/features/home_setup/data/home_setup_service.dart';
import 'package:smart_homez/features/home_setup/data/models/bulk_assignment_models.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_request.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_response.dart';
import 'package:smart_homez/features/home_setup/data/models/unassigned_device_model.dart';
import 'package:smart_homez/features/home_setup/providers/home_setup_provider.dart';
import 'package:smart_homez/features/home_setup/screens/home_setup_screen.dart';
import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/device.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/client_dashboard_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/energy_provider.dart';
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

  @override
  Future<List<UnassignedDevice>> getUnassignedDevices(String homeId) async {
    return [
      const UnassignedDevice(
        id: 'dev_fan',
        name: 'Ceiling Fan',
        type: 'fan',
        suggestedRoomName: 'Living Room',
        confidence: 0.95,
      ),
      const UnassignedDevice(
        id: 'dev_light',
        name: 'Dining Light',
        type: 'light',
      ),
    ];
  }

  @override
  Future<BulkAssignmentResponse> bulkAssignDevicesToRooms(
    List<DeviceAssignmentItem> assignments,
  ) async {
    return const BulkAssignmentResponse(
      success: true,
      assignedIds: ['dev_fan', 'dev_light'],
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
    ],
    child: const MaterialApp(home: HomeSetupScreen()),
  );
}

void main() {
  testWidgets(
    'Step 1: Renders templates and enables creation for authorized admin',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = MockSetupService();
      final provider = HomeSetupProvider(setupService: service);

      await tester.pumpWidget(createTestHarness(setupProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('One-Click Home Setup'), findsOneWidget);
      expect(find.text('1. Home Details'), findsOneWidget);
      expect(find.text('2. Select Layout Template'), findsOneWidget);
      expect(find.text('Studio Apartment'), findsOneWidget);
      expect(find.text('2 BHK Apartment'), findsOneWidget);
      expect(find.text('3 BHK Apartment'), findsOneWidget);
      expect(find.text('Multi-Floor Villa'), findsOneWidget);
      expect(find.text('Custom Layout'), findsOneWidget);
      expect(find.text('Create & Continue to Devices'), findsOneWidget);
    },
  );

  testWidgets(
    'Step 1: Selecting Custom Layout reveals Custom Structure Editor',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = MockSetupService();
      final provider = HomeSetupProvider(setupService: service);

      await tester.pumpWidget(createTestHarness(setupProvider: provider));
      await tester.pumpAndSettle();

      // Tap Custom Layout
      await tester.ensureVisible(find.text('Custom Layout'));
      await tester.tap(find.text('Custom Layout'));
      await tester.pumpAndSettle();

      expect(find.text('Customize Structure'), findsOneWidget);
      expect(find.text('Flat (Home → Rooms)'), findsOneWidget);
      expect(find.text('Floors (Home → Floors → Rooms)'), findsOneWidget);
    },
  );

  testWidgets(
    'Permissions: Unauthorized resident sees read-only banner and disabled button',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = MockSetupService();
      final provider = HomeSetupProvider(setupService: service);

      await tester.pumpWidget(
        createTestHarness(setupProvider: provider, role: UserRole.resident),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'View-only mode: Administrator or manager permissions are required',
        ),
        findsOneWidget,
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create & Continue to Devices'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'Step 2: Creates layout, advances to Step 2, and displays unassigned devices & suggestions',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = MockSetupService();
      final provider = HomeSetupProvider(setupService: service);

      await tester.pumpWidget(createTestHarness(setupProvider: provider));
      await tester.pumpAndSettle();

      // Tap Create & Continue
      await tester.ensureVisible(find.text('Create & Continue to Devices'));
      await tester.tap(find.text('Create & Continue to Devices'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('My Smart Home Created!'), findsOneWidget);
      expect(find.text('Assign Devices to Rooms'), findsOneWidget);
      expect(find.text('Ceiling Fan'), findsOneWidget);
      expect(find.text('95% match'), findsOneWidget);
      expect(find.text('Dining Light'), findsOneWidget);
      expect(find.text('1 of 2 devices assigned'), findsOneWidget);

      // Auto assign button
      await tester.ensureVisible(find.text('Auto-Assign'));
      await tester.tap(find.text('Auto-Assign'));
      await tester.pumpAndSettle();

      // Complete Onboarding
      expect(find.text('Complete Onboarding'), findsOneWidget);
      await tester.ensureVisible(find.text('Complete Onboarding'));
      await tester.tap(find.text('Complete Onboarding'));
      await tester.pump();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'PopScope: Prompts confirmation when user tries to abandon wizard on Step 2',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = MockSetupService();
      final provider = HomeSetupProvider(setupService: service);

      await tester.pumpWidget(createTestHarness(setupProvider: provider));
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.ensureVisible(find.text('Create & Continue to Devices'));
      await tester.tap(find.text('Create & Continue to Devices'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap close button in app bar
      final appBarCloseButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.close_rounded),
      );
      await tester.tap(appBarCloseButton);
      await tester.pumpAndSettle();

      expect(find.text('Leave Setup Wizard?'), findsOneWidget);
      expect(find.text('Continue Setup'), findsOneWidget);
      expect(find.text('Exit Setup'), findsOneWidget);

      // Tap Continue Setup to stay
      await tester.tap(find.text('Continue Setup'));
      await tester.pumpAndSettle();
      expect(find.text('Leave Setup Wizard?'), findsNothing);
    },
  );
}
