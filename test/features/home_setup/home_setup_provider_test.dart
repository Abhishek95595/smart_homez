import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/features/home_setup/data/home_setup_service.dart';
import 'package:smart_homez/features/home_setup/data/models/home_layout_template.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_request.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_response.dart';
import 'package:smart_homez/features/home_setup/providers/home_setup_provider.dart';

class FakeHomeSetupService extends HomeSetupService {
  HomeSetupResult? mockSetupResult;

  @override
  Future<HomeSetupResult> setupHomeFromTemplate(
    HomeSetupRequest request,
  ) async {
    if (mockSetupResult != null) return mockSetupResult!;
    return HomeSetupResult(
      home: CreatedHome(id: 'home_mock_123', name: request.homeName),
      rooms: (request.flatRooms ?? ['Living Room', 'Bedroom'])
          .map((n) => CreatedRoom(id: 'r_$n', name: n, type: 'Room'))
          .toList(),
    );
  }
}

void main() {
  late FakeHomeSetupService fakeService;
  late HomeSetupProvider provider;

  setUp(() {
    fakeService = FakeHomeSetupService();
    provider = HomeSetupProvider(setupService: fakeService);
  });

  group('HomeSetupProvider 4-Step Flow & State Tests', () {
    test(
      'Initializes with 2BHK template, 7 default rooms, 4-step wizard at step 0',
      () {
        expect(provider.currentStep, 0);
        expect(provider.category, PropertyCategory.residential);
        expect(provider.selectedTemplate, HomeLayoutTemplateType.twoBhk);
        expect(provider.isMultiFloor, isFalse);
        expect(provider.draftRooms.length, 7);
      },
    );

    test('2 BHK has 7 default rooms', () {
      provider.selectTemplate(HomeLayoutTemplateType.twoBhk);
      expect(provider.draftRooms.length, 7);
      expect(provider.draftRooms.map((r) => r.name), contains('Bedroom 1'));
      expect(provider.draftRooms.map((r) => r.name), contains('Bedroom 2'));
    });

    test('Villa has 2 floors by default', () {
      provider.selectTemplate(HomeLayoutTemplateType.villa);
      expect(provider.isMultiFloor, isTrue);
      expect(provider.floorCount, 2);
      expect(provider.draftFloors.length, 2);
      expect(provider.draftFloors[0].name, 'Ground Floor');
      expect(provider.draftFloors[1].name, '1st Floor');
    });

    test(
      'Villa floor increase (2 -> 3 floors) preserves existing floors/rooms and adds ONLY new floor',
      () {
        provider.selectTemplate(HomeLayoutTemplateType.villa);
        final groundRoomCount = provider.draftFloors[0].rooms.length;

        // Add custom room to Ground Floor
        provider.addRoom(
          'Wine Cellar',
          floorLocalId: provider.draftFloors[0].localId,
        );
        expect(provider.draftFloors[0].rooms.length, groundRoomCount + 1);

        // Increase floor count 2 -> 3
        provider.increaseFloorCount();
        expect(provider.floorCount, 3);
        expect(provider.draftFloors.length, 3);

        // Verify Ground Floor and First Floor preserved with custom room
        expect(provider.draftFloors[0].rooms.length, groundRoomCount + 1);
        expect(
          provider.draftFloors[0].rooms.map((r) => r.name),
          contains('Wine Cellar'),
        );
        expect(provider.draftFloors[2].name, '2nd Floor');
      },
    );

    test('Villa floor decrease (3 -> 2 floors) removes ONLY highest floor', () {
      provider.selectTemplate(HomeLayoutTemplateType.villa);
      provider.setFloorCount(3);
      expect(provider.draftFloors.length, 3);

      provider.decreaseFloorCount();
      expect(provider.floorCount, 2);
      expect(provider.draftFloors.length, 2);
      expect(provider.draftFloors[0].name, 'Ground Floor');
      expect(provider.draftFloors[1].name, '1st Floor');
    });

    test('Deleted room persistence across step navigation', () {
      provider.selectTemplate(HomeLayoutTemplateType.twoBhk);
      final roomToDelete = provider.draftRooms.firstWhere(
        (r) => r.name == 'Bedroom 2',
      );

      provider.deleteRoom(roomToDelete.localId);
      expect(provider.draftRooms.any((r) => r.name == 'Bedroom 2'), isFalse);

      // Navigate across steps
      provider.goNext(); // Step 1
      provider.goNext(); // Step 2
      provider.goBack(); // Step 1

      expect(provider.draftRooms.any((r) => r.name == 'Bedroom 2'), isFalse);
    });

    test('Added room persistence across step navigation', () {
      provider.selectTemplate(HomeLayoutTemplateType.twoBhk);
      provider.addRoom('Home Office');

      expect(provider.draftRooms.map((r) => r.name), contains('Home Office'));

      // Navigate back and forward
      provider.goNext();
      provider.goBack();

      expect(provider.draftRooms.map((r) => r.name), contains('Home Office'));
    });

    test(
      'Category switch (Residential -> Commercial) preserves name & address, resets template & rooms',
      () {
        provider.setPropertyName('Central Park Tower');
        provider.setAddress('100 Main St');
        provider.selectTemplate(HomeLayoutTemplateType.threeBhk);

        expect(provider.propertyName, 'Central Park Tower');
        expect(provider.address, '100 Main St');

        // Switch category to Commercial
        provider.setCategory(PropertyCategory.commercial);

        expect(provider.category, PropertyCategory.commercial);
        expect(provider.propertyName, 'Central Park Tower');
        expect(provider.address, '100 Main St');
        expect(provider.selectedTemplate, HomeLayoutTemplateType.office);
      },
    );

    test('Office is single-level (no floor controls)', () {
      provider.selectTemplate(HomeLayoutTemplateType.office);
      expect(provider.isMultiFloor, isFalse);
      expect(provider.draftRooms.map((r) => r.name), contains('Reception'));
    });

    test('Hotel has 3 floors by default', () {
      provider.selectTemplate(HomeLayoutTemplateType.hotel);
      expect(provider.isMultiFloor, isTrue);
      expect(provider.floorCount, 3);
      expect(provider.draftFloors.length, 3);
    });

    test('Custom layout starts empty', () {
      provider.selectTemplate(HomeLayoutTemplateType.custom);
      expect(provider.draftRooms.isEmpty, isTrue);
    });
  });
}
