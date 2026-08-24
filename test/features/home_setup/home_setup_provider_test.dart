import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/features/home_setup/data/home_setup_service.dart';
import 'package:smart_homez/features/home_setup/data/models/bulk_assignment_models.dart';
import 'package:smart_homez/features/home_setup/data/models/home_layout_template.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_request.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_response.dart';
import 'package:smart_homez/features/home_setup/data/models/unassigned_device_model.dart';
import 'package:smart_homez/features/home_setup/providers/home_setup_provider.dart';

class FakeHomeSetupService extends HomeSetupService {
  HomeSetupResult? mockSetupResult;
  List<UnassignedDevice> mockDevices = [];
  BulkAssignmentResponse mockAssignResponse = const BulkAssignmentResponse(
    success: true,
  );

  HomeSetupRequest? lastSetupRequest;
  List<DeviceAssignmentItem>? lastAssignments;

  @override
  Future<HomeSetupResult> setupHomeFromTemplate(
    HomeSetupRequest request,
  ) async {
    lastSetupRequest = request;
    if (mockSetupResult != null) return mockSetupResult!;
    return HomeSetupResult(
      home: CreatedHome(id: 'home_mock', name: request.homeName),
      rooms: (request.flatRooms ?? ['Living Room', 'Bedroom'])
          .map((n) => CreatedRoom(id: 'r_$n', name: n, type: 'Room'))
          .toList(),
    );
  }

  @override
  Future<List<UnassignedDevice>> getUnassignedDevices(String homeId) async {
    return mockDevices;
  }

  @override
  Future<BulkAssignmentResponse> bulkAssignDevicesToRooms(
    List<DeviceAssignmentItem> assignments,
  ) async {
    lastAssignments = assignments;
    return mockAssignResponse;
  }
}

void main() {
  late FakeHomeSetupService fakeService;
  late HomeSetupProvider provider;

  setUp(() {
    fakeService = FakeHomeSetupService();
    provider = HomeSetupProvider(setupService: fakeService);
  });

  group('HomeSetupProvider Step 1 & Custom Layout Tests', () {
    test('Initializes with 2BHK template and default draft values', () {
      expect(provider.currentStep, 0);
      expect(provider.selectedTemplate, HomeLayoutTemplateType.twoBhk);
      expect(provider.hierarchyMode, HierarchyMode.flat);
      expect(provider.homeName, 'My Smart Home');
      expect(provider.customFlatRooms.isNotEmpty, isTrue);
      expect(provider.customFloors.length, 2);
    });

    test('Switching template updates selected template and hierarchy mode', () {
      provider.setTemplate(HomeLayoutTemplateType.villa);
      expect(provider.selectedTemplate, HomeLayoutTemplateType.villa);
      expect(provider.hierarchyMode, HierarchyMode.floorBased);

      provider.setTemplate(HomeLayoutTemplateType.studio);
      expect(provider.selectedTemplate, HomeLayoutTemplateType.studio);
      expect(provider.hierarchyMode, HierarchyMode.flat);
    });

    test('Custom flat rooms validation: add, rename, duplicate, remove', () {
      provider.setTemplate(HomeLayoutTemplateType.custom);
      provider.setHierarchyMode(HierarchyMode.flat);

      final errEmpty = provider.addCustomFlatRoom('   ');
      expect(errEmpty, isNotNull);

      final errSuccess = provider.addCustomFlatRoom('Wine Cellar');
      expect(errSuccess, isNull);
      expect(provider.customFlatRooms, contains('Wine Cellar'));

      final errDuplicate = provider.addCustomFlatRoom('Wine Cellar');
      expect(errDuplicate, isNotNull);

      final cellarIndex = provider.customFlatRooms.indexOf('Wine Cellar');
      final errRename = provider.renameCustomFlatRoom(
        cellarIndex,
        'Wine Tasting Room',
      );
      expect(errRename, isNull);
      expect(provider.customFlatRooms[cellarIndex], 'Wine Tasting Room');

      provider.removeCustomFlatRoom(cellarIndex);
      expect(provider.customFlatRooms.contains('Wine Tasting Room'), isFalse);
    });

    test(
      'Custom floor rooms validation: add floor, add room, prevent empty',
      () {
        provider.setTemplate(HomeLayoutTemplateType.custom);
        provider.setHierarchyMode(HierarchyMode.floorBased);

        final errFloor = provider.addCustomFloor('Rooftop Deck', 2);
        expect(errFloor, isNull);

        final floorIdx = provider.customFloors.indexWhere(
          (f) => f.name == 'Rooftop Deck',
        );
        expect(floorIdx, isNonNegative);

        final errRoom = provider.addRoomToFloor(floorIdx, 'Bar Lounge');
        expect(errRoom, isNull);
        expect(provider.customFloors[floorIdx].rooms, contains('Bar Lounge'));
      },
    );

    test(
      'validateLayoutStep prevents empty home names or empty custom layouts',
      () {
        provider.setHomeName('   ');
        expect(provider.validateLayoutStep(), isNotNull);

        provider.setHomeName('Valid Home');
        expect(provider.validateLayoutStep(), isNull);
      },
    );
  });

  group('HomeSetupProvider Execution & Device Assignment Tests', () {
    test('createHomeLayout fails if user lacks canManage permission', () async {
      final success = await provider.createHomeLayout(canManage: false);
      expect(success, isFalse);
      expect(provider.errorMessage, contains('permission'));
      expect(provider.currentStep, 0);
    });

    test(
      'createHomeLayout succeeds, moves to Step 1, and fetches devices with suggestions',
      () async {
        fakeService.mockDevices = [
          const UnassignedDevice(
            id: 'dev_1',
            name: 'Living Room Light',
            type: 'light',
            suggestedRoomName: 'Living Room',
            confidence: 0.9,
          ),
          const UnassignedDevice(id: 'dev_2', name: 'AC Unit', type: 'climate'),
        ];

        final success = await provider.createHomeLayout(canManage: true);
        expect(success, isTrue);
        expect(provider.currentStep, 1);
        expect(provider.createdHome, isNotNull);
        expect(provider.unassignedDevices.length, 2);

        // dev_1 should be pre-assigned to Living Room
        expect(provider.deviceAssignments['dev_1'], 'r_Living Room');
        // dev_2 has no suggestion
        expect(provider.deviceAssignments['dev_2'], isNull);
        expect(provider.assignedCount, 1);
      },
    );

    test(
      'assignDevice, assignAllSuggested, and clearAllAssignments manipulate state',
      () async {
        fakeService.mockDevices = [
          const UnassignedDevice(
            id: 'd1',
            name: 'Bulb',
            type: 'light',
            suggestedRoomName: 'Living Room',
          ),
          const UnassignedDevice(
            id: 'd2',
            name: 'Fan',
            type: 'fan',
            suggestedRoomName: 'Master Bedroom',
          ),
        ];

        await provider.createHomeLayout(canManage: true);

        provider.clearAllAssignments();
        expect(provider.assignedCount, 0);

        provider.assignDevice('d1', 'r_Living Room');
        expect(provider.deviceAssignments['d1'], 'r_Living Room');
        expect(provider.assignedCount, 1);

        provider.assignAllSuggested();
        expect(provider.assignedCount, 2);
      },
    );

    test('submitAssignments handles partial failures and retries', () async {
      fakeService.mockDevices = [
        const UnassignedDevice(id: 'd1', name: 'Bulb', type: 'light'),
        const UnassignedDevice(id: 'd2', name: 'Fan', type: 'fan'),
      ];

      await provider.createHomeLayout(canManage: true);
      provider.assignDevice('d1', 'r_Living Room');
      provider.assignDevice('d2', 'r_Bedroom');

      // 1. Simulate partial failure
      fakeService.mockAssignResponse = const BulkAssignmentResponse(
        success: false,
        failedAssignments: [
          BulkAssignmentFailure(deviceId: 'd2', error: 'Device unreachable'),
        ],
      );

      final submitOk = await provider.submitAssignments(canManage: true);
      expect(submitOk, isFalse);
      expect(provider.partialFailures.length, 1);
      expect(provider.partialFailures.first.deviceId, 'd2');

      // 2. Retry only failed items
      fakeService.mockAssignResponse = const BulkAssignmentResponse(
        success: true,
        assignedIds: ['d2'],
      );

      final retryOk = await provider.retryFailedAssignments(canManage: true);
      expect(retryOk, isTrue);
      expect(provider.partialFailures, isEmpty);
      expect(provider.isCompleted, isTrue);
    });
  });
}
