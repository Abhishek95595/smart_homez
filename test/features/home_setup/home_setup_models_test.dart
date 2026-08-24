import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/features/home_setup/data/models/bulk_assignment_models.dart';
import 'package:smart_homez/features/home_setup/data/models/home_layout_template.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_request.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_response.dart';
import 'package:smart_homez/features/home_setup/data/models/unassigned_device_model.dart';

void main() {
  group('HomeLayoutTemplate Tests', () {
    test(
      'All templates have titles, descriptions, icons and default structures',
      () {
        for (final template in HomeLayoutTemplateType.values) {
          expect(template.title.isNotEmpty, isTrue);
          expect(template.description.isNotEmpty, isTrue);
          expect(template.id.isNotEmpty, isTrue);
        }

        expect(
          HomeLayoutTemplateType.studio.defaultHierarchyMode,
          HierarchyMode.flat,
        );
        expect(
          HomeLayoutTemplateType.twoBhk.defaultHierarchyMode,
          HierarchyMode.flat,
        );
        expect(
          HomeLayoutTemplateType.threeBhk.defaultHierarchyMode,
          HierarchyMode.flat,
        );
        expect(
          HomeLayoutTemplateType.villa.defaultHierarchyMode,
          HierarchyMode.floorBased,
        );
        expect(
          HomeLayoutTemplateType.custom.defaultHierarchyMode,
          HierarchyMode.flat,
        );

        expect(
          HomeLayoutTemplateType.studio.defaultFlatRoomNames,
          contains('Living & Bedroom'),
        );
        expect(HomeLayoutTemplateType.twoBhk.defaultFlatRoomNames.length, 7);
        expect(HomeLayoutTemplateType.threeBhk.defaultFlatRoomNames.length, 9);
        expect(HomeLayoutTemplateType.villa.defaultVillaFloors.length, 3);
      },
    );

    test('CustomFloorDraft converts to JSON correctly', () {
      final draft = CustomFloorDraft(
        name: 'Basement',
        level: -1,
        rooms: ['Home Theater', 'Storage'],
      );
      final json = draft.toJson();
      expect(json['name'], 'Basement');
      expect(json['level'], -1);
      expect(json['rooms'], ['Home Theater', 'Storage']);
    });
  });

  group('HomeSetupRequest Serialization Tests', () {
    test('Serializes flat layout request correctly', () {
      final req = HomeSetupRequest(
        template: '2bhk',
        homeName: 'Beach Apartment',
        address: '42 Ocean Drive',
        hierarchyMode: HierarchyMode.flat,
        flatRooms: ['Living Room', 'Master Bedroom', 'Kitchen'],
      );

      final json = req.toJson();
      expect(json['template'], '2bhk');
      expect(json['home_name'], 'Beach Apartment');
      expect(json['address'], '42 Ocean Drive');
      expect(json['structure_type'], 'flat');
      expect(json['rooms'], [
        {'name': 'Living Room', 'type': 'Room'},
        {'name': 'Master Bedroom', 'type': 'Room'},
        {'name': 'Kitchen', 'type': 'Room'},
      ]);
      expect(json.containsKey('floors'), isFalse);
    });

    test('Serializes floor-based layout request correctly', () {
      final req = HomeSetupRequest(
        template: 'villa',
        homeName: 'Palm Villa',
        hierarchyMode: HierarchyMode.floorBased,
        floors: [
          CustomFloorDraft(
            name: 'Ground Floor',
            level: 0,
            rooms: ['Living Room', 'Kitchen'],
          ),
        ],
      );

      final json = req.toJson();
      expect(json['template'], 'villa');
      expect(json['home_name'], 'Palm Villa');
      expect(json['structure_type'], 'floor_based');
      expect(json['floors'], [
        {
          'name': 'Ground Floor',
          'floor_number': 0,
          'rooms': [
            {'name': 'Living Room', 'type': 'Room'},
            {'name': 'Kitchen', 'type': 'Room'},
          ],
        },
      ]);
      expect(json.containsKey('rooms'), isFalse);
    });
  });

  group('HomeSetupResponse Deserialization Tests', () {
    test('Parses flat response with rooms directly on home', () {
      final json = {
        'id': 'home_123',
        'name': 'My Flat',
        'address': '123 Main St',
        'structure_type': 'flat',
        'rooms': [
          {'id': 'room_1', 'name': 'Living Room', 'type': 'Living Room'},
          {'id': 'room_2', 'name': 'Bedroom', 'type': 'Bedroom'},
        ],
      };

      final result = HomeSetupResult.fromJson(json);
      expect(result.home.id, 'home_123');
      expect(result.home.name, 'My Flat');
      expect(result.floors, isEmpty);
      expect(result.rooms.length, 2);
      expect(result.allRooms.length, 2);
      expect(result.allRooms.first.name, 'Living Room');
      expect(result.allRooms.first.floorId, isNull);
    });

    test('Parses nested response under home/data payload', () {
      final json = {
        'home': {
          'id': 'home_456',
          'name': 'Grand Villa',
          'address': '99 Hilltop Road',
        },
        'floors': [
          {
            'id': 'floor_g',
            'name': 'Ground Floor',
            'level': 0,
            'rooms': [
              {'id': 'room_10', 'name': 'Foyer', 'floor_id': 'floor_g'},
              {'id': 'room_11', 'name': 'Kitchen', 'floor_id': 'floor_g'},
            ],
          },
          {
            'id': 'floor_1',
            'name': 'First Floor',
            'level': 1,
            'rooms': [
              {'id': 'room_20', 'name': 'Master Suite', 'floor_id': 'floor_1'},
            ],
          },
        ],
      };

      final result = HomeSetupResult.fromJson(json);
      expect(result.home.id, 'home_456');
      expect(result.floors.length, 2);
      expect(result.allRooms.length, 3);
      expect(result.allRooms[0].floorId, 'floor_g');
      expect(result.allRooms[2].floorId, 'floor_1');
    });
  });

  group('UnassignedDevice & BulkAssignment Tests', () {
    test('UnassignedDevice deserializes with confidence and icon resolver', () {
      final json = {
        'id': 'dev_101',
        'name': 'Living Room AC',
        'type': 'climate',
        'suggested_room_id': 'room_1',
        'suggested_room_name': 'Living Room',
        'confidence': 0.95,
      };

      final device = UnassignedDevice.fromJson(json);
      expect(device.id, 'dev_101');
      expect(device.name, 'Living Room AC');
      expect(device.type, 'climate');
      expect(device.suggestedRoomId, 'room_1');
      expect(device.suggestedRoomName, 'Living Room');
      expect(device.confidence, 0.95);
      expect(device.iconData, isNotNull);
    });

    test(
      'BulkAssignmentResponse handles full success and partial failures',
      () {
        final successJson = {
          'success': true,
          'data': {
            'assigned': ['dev_1', 'dev_2'],
            'failed': <Map<String, dynamic>>[],
          },
        };
        final successResp = BulkAssignmentResponse.fromJson(successJson);
        expect(successResp.success, isTrue);
        expect(successResp.hasFailures, isFalse);
        expect(successResp.assigned.length, 2);

        final partialJson = {
          'success': false,
          'data': {
            'assigned': ['dev_1'],
            'failed': [
              {'device_id': 'dev_2', 'error': 'Room not found'},
            ],
          },
        };
        final partialResp = BulkAssignmentResponse.fromJson(partialJson);
        expect(partialResp.hasFailures, isTrue);
        expect(partialResp.failedAssignments.length, 1);
        expect(partialResp.failedAssignments.first.deviceId, 'dev_2');
        expect(partialResp.failedAssignments.first.error, 'Room not found');
      },
    );
  });
}
