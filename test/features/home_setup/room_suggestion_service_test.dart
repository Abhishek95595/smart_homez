import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/features/home_setup/data/models/home_setup_response.dart';
import 'package:smart_homez/features/home_setup/data/models/unassigned_device_model.dart';
import 'package:smart_homez/features/home_setup/data/room_suggestion_service.dart';

void main() {
  const service = RoomSuggestionService();

  final availableRooms = [
    CreatedRoom(id: 'r_living', name: 'Living Room', type: 'Living Room'),
    CreatedRoom(id: 'r_bed1', name: 'Master Bedroom', type: 'Bedroom'),
    CreatedRoom(id: 'r_bed2', name: 'Kids Bedroom', type: 'Bedroom'),
    CreatedRoom(id: 'r_kitchen', name: 'Kitchen', type: 'Kitchen'),
    CreatedRoom(id: 'r_bath', name: 'Main Bathroom', type: 'Bathroom'),
  ];

  group('RoomSuggestionService Tests', () {
    test('Matches exact suggestedRoomId when present in availableRooms', () {
      const device = UnassignedDevice(
        id: 'd1',
        name: 'Ceiling Fan',
        type: 'fan',
        suggestedRoomId: 'r_living',
      );

      final matchedRoomId = service.resolveSuggestedRoomId(
        device: device,
        availableRooms: availableRooms,
      );

      expect(matchedRoomId, 'r_living');
    });

    test('Matches by suggestedRoomName when suggestedRoomId is missing', () {
      const device = UnassignedDevice(
        id: 'd2',
        name: 'Philips Hue',
        type: 'light',
        suggestedRoomName: 'Kitchen',
      );

      final matchedRoomId = service.resolveSuggestedRoomId(
        device: device,
        availableRooms: availableRooms,
      );

      expect(matchedRoomId, 'r_kitchen');
    });

    test(
      'Falls back to device name keywords when backend provides no suggestion',
      () {
        const device = UnassignedDevice(
          id: 'd3',
          name: 'Master Bedroom Lamp',
          type: 'light',
        );

        final matchedRoomId = service.resolveSuggestedRoomId(
          device: device,
          availableRooms: availableRooms,
        );

        expect(matchedRoomId, 'r_bed1');
      },
    );

    test('Returns null when no match or suggestion exists', () {
      const device = UnassignedDevice(
        id: 'd4',
        name: 'Generic Zigbee Switch 001',
        type: 'switch',
      );

      final matchedRoomId = service.resolveSuggestedRoomId(
        device: device,
        availableRooms: availableRooms,
      );

      expect(matchedRoomId, isNull);
    });
  });
}
