import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/data/mock_data.dart';
import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/device.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/services/device_repository.dart';

void main() {
  test('resident can see and control devices in their own flat', () async {
    final provider = DeviceProvider(repository: MemoryDeviceRepository());
    while (provider.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    
    // Create a specific test device belonging to a flat
    final testDevice = (await provider.addDevice(
      type: DeviceType.light,
      name: 'Bedroom Light',
      macAddress: '11:22:33:44:55:66',
    )).copyWith(flatId: 'flat_101');
    
    // Replace the device in provider for the test
    provider.updateDevice(testDevice, type: testDevice.type, name: testDevice.name, macAddress: testDevice.macAddress);

    final resident = const AppUser(
      id: 'res_1',
      name: 'Test Resident',
      email: 'res@test.com',
      phone: '123',
      role: UserRole.resident,
      tenantId: 't1',
      flatId: 'flat_101',
      avatarInitials: 'TR',
    );

    final visible = provider.visibleDevices(resident);
    expect(visible.any((d) => d.name == 'Bedroom Light'), isTrue);
    expect(provider.canControlDevice(visible.firstWhere((d) => d.name == 'Bedroom Light'), resident), isTrue);
  });

  test('optional names and MAC address receive safe defaults', () async {
    final provider = DeviceProvider(repository: MemoryDeviceRepository());
    while (provider.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }

    final newDevice = await provider.addDevice(
      type: DeviceType.light,
      name: '',
      macAddress: '  aa:bb:cc:dd:ee:ff  ',
      propertyId: 'bldg_A',
      floorId: 'floor_1',
      roomId: 'room_1',
      roomName: 'Living Room',
    );

    expect(newDevice.name, equals('Light'));
    expect(newDevice.macAddress, equals('AA:BB:CC:DD:EE:FF'));
    expect(newDevice.zone, equals('Living Room'));
  });
}
