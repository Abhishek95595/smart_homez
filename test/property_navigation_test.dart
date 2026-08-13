import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/device.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/services/device_repository.dart';

void main() {
  Future<DeviceProvider> createProvider() async {
    final provider = DeviceProvider(
      repository: MemoryDeviceRepository(const <Device>[]),
    );

    while (provider.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }

    return provider;
  }

  test('resident can see and control devices in their own flat', () async {
    final provider = await createProvider();
    addTearDown(provider.dispose);

    final createdDevice = await provider.addDevice(
      type: DeviceType.light,
      name: 'Bedroom Light',
      macAddress: '11:22:33:44:55:66',
    );

    final testDevice = createdDevice.copyWith(flatId: 'flat_101');

    await provider.updateDevice(
      testDevice,
      type: testDevice.type,
      name: testDevice.name,
      macAddress: testDevice.macAddress,
    );

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
    final bedroomLight = visible.firstWhere(
      (device) => device.name == 'Bedroom Light',
    );

    expect(bedroomLight.flatId, 'flat_101');
    expect(provider.canControlDevice(bedroomLight, resident), isTrue);
  });

  test('optional names and MAC address receive safe defaults', () async {
    final provider = await createProvider();
    addTearDown(provider.dispose);

    final newDevice = await provider.addDevice(
      type: DeviceType.light,
      name: '',
      macAddress: '  aa:bb:cc:dd:ee:ff  ',
      propertyId: 'bldg_A',
      floorId: 'floor_1',
      roomId: 'room_1',
      roomName: 'Living Room',
    );

    expect(newDevice.name, 'Light');
    expect(newDevice.macAddress, 'AA:BB:CC:DD:EE:FF');
    expect(newDevice.zone, 'Living Room');
  });
}
