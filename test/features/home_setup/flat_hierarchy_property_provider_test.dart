import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/models/property_hierarchy.dart';
import 'package:smart_homez/providers/property_provider.dart';
import 'package:smart_homez/services/property_repository.dart';

class InMemoryPropertyRepository implements PropertyRepository {
  PropertySnapshot snapshot = const PropertySnapshot(
    properties: [],
    floors: [],
    rooms: [],
  );

  @override
  Future<PropertySnapshot> load() async => snapshot;

  @override
  Future<void> save(PropertySnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}

void main() {
  late InMemoryPropertyRepository repo;
  late PropertyProvider provider;

  setUp(() async {
    repo = InMemoryPropertyRepository();
    repo.snapshot = PropertySnapshot(
      properties: [
        const ManagedProperty(
          id: 'home_flat_1',
          name: 'Flat Apartment',
          address: '42 Downtown St',
        ),
        const ManagedProperty(
          id: 'home_villa_1',
          name: 'Grand Villa',
          address: '100 Palm St',
        ),
      ],
      floors: [
        const ManagedFloor(
          id: 'floor_g',
          propertyId: 'home_villa_1',
          name: 'Ground Floor',
          level: 0,
        ),
      ],
      rooms: [
        const ManagedRoom(
          id: 'room_flat_living',
          propertyId: 'home_flat_1',
          floorId: null,
          name: 'Living Room',
          type: 'Living Room',
        ),
        const ManagedRoom(
          id: 'room_flat_bed',
          propertyId: 'home_flat_1',
          floorId: null,
          name: 'Bedroom',
          type: 'Bedroom',
        ),
        const ManagedRoom(
          id: 'room_villa_kitchen',
          propertyId: 'home_villa_1',
          floorId: 'floor_g',
          name: 'Villa Kitchen',
          type: 'Kitchen',
        ),
      ],
    );

    provider = PropertyProvider(repository: repo);
    await provider.reload();
  });

  group('PropertyProvider Flat Hierarchy Tests', () {
    test('isFlatHome returns true for homes with 0 floors', () {
      expect(provider.isFlatHome('home_flat_1'), isTrue);
      expect(provider.isFlatHome('home_villa_1'), isFalse);
    });

    test(
      'roomsForHome retrieves flat rooms and floor-associated rooms accurately',
      () {
        final flatRooms = provider.roomsForHome('home_flat_1');
        expect(flatRooms.length, 2);
        expect(
          flatRooms.map((r) => r.name),
          containsAll(['Living Room', 'Bedroom']),
        );

        final villaRooms = provider.roomsForHome('home_villa_1');
        expect(villaRooms.length, 1);
        expect(villaRooms.first.name, 'Villa Kitchen');
      },
    );

    test('addRoom supports flat rooms where floorId is null', () async {
      final newRoom = await provider.addRoom(
        homeId: 'home_flat_1',
        floorId: null,
        name: 'Balcony',
        type: 'Balcony',
      );

      expect(newRoom.propertyId, 'home_flat_1');
      expect(newRoom.floorId, isNull);
      expect(newRoom.name, 'Balcony');

      final updatedRooms = provider.roomsForHome('home_flat_1');
      expect(updatedRooms.length, 3);
    });

    test(
      'deleteProperty removes flat rooms and associated floors/rooms',
      () async {
        await provider.deleteProperty('home_flat_1');
        expect(provider.propertyById('home_flat_1'), isNull);
        expect(provider.roomsForHome('home_flat_1'), isEmpty);

        // Villa rooms should remain untouched
        expect(provider.roomsForHome('home_villa_1').length, 1);
      },
    );
  });
}
