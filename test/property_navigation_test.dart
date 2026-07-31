import 'package:flutter_test/flutter_test.dart';

import 'package:smart_homez/data/mock_data.dart';
import 'package:smart_homez/models/device.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/property_provider.dart';
import 'package:smart_homez/services/device_repository.dart';
import 'package:smart_homez/services/property_repository.dart';

void main() {
  test('property hierarchy contains homes, floors and rooms', () {
    final society = MockData.buildSociety();
    final building = society.buildings.first;
    final tower = building.towers.first;
    final flat = tower.flats.first;

    expect(society.buildings, isNotEmpty);
    expect(building.towers, isNotEmpty);
    expect(tower.flats, isNotEmpty);
    expect(flat.rooms, isNotEmpty);
  });

  test('resident can see and control devices in their own flat', () async {
    final resident = MockData.demoUsers().firstWhere(
      (user) => user.role == UserRole.resident,
    );
    final provider = DeviceProvider(repository: MemoryDeviceRepository());
    while (provider.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    final residentDevices = provider.visibleDevicesAt(
      resident,
      buildingId: resident.buildingId,
      towerId: 'tower_A',
      flatId: 'flat_302',
    );

    expect(residentDevices, isNotEmpty);
    expect(
      residentDevices.any(
        (device) => provider.canControlDevice(device, resident),
      ),
      isTrue,
    );

    provider.dispose();
  });

  test('optional names and MAC address receive safe defaults', () async {
    final properties = PropertyProvider(repository: MemoryPropertyRepository());
    while (properties.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }

    final property = await properties.addProperty(
      name: '',
      address: 'Bengaluru',
      propertyType: 'House',
    );
    final floor = await properties.addFloor(
      propertyId: property.id,
      name: '',
      level: 1,
    );
    final room = await properties.addRoom(
      floorId: floor.id,
      name: '',
      type: 'Bedroom',
    );

    expect(property.name, startsWith('Untitled House'));
    expect(floor.name, 'Floor 1');
    expect(room.name, startsWith('Bedroom'));

    final devices = DeviceProvider(repository: MemoryDeviceRepository());
    while (devices.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    final device = await devices.addDevice(
      type: DeviceType.light,
      name: '',
      macAddress: '',
    );

    expect(device.name, isNotEmpty);
    expect(device.macAddress, isEmpty);
    expect(device.buildingId, isEmpty);
    expect(device.floorId, isNull);
    expect(device.roomId, isNull);
    expect(device.zone, 'Unassigned');

    devices.dispose();
    properties.dispose();
  });
}
