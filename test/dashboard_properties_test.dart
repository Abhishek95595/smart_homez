import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/device.dart';
import 'package:smart_homez/models/property_hierarchy.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/services/device_repository.dart';

void main() {
  test('visibleDevicesForProperty matches by both name and propertyId', () async {
    final user = const AppUser(
      id: 'usr_1',
      name: 'Aditya',
      email: 'aditya@example.com',
      phone: '1234567890',
      role: UserRole.resident,
      tenantId: 'tenant_1',
      avatarInitials: 'A',
    );

    final device1 = Device(
      deviceId: 'dev_1',
      type: DeviceType.light,
      name: 'Ceiling Light',
      firmwareVersion: '1.0.0',
      macAddress: 'AA:BB:CC:DD:EE:01',
      tenantId: 'tenant_1',
      buildingId: 'home_uuid_123',
      homeName: 'Aditya Home',
      zone: 'Living Room',
      lastHeartbeat: DateTime.now(),
    );

    final device2 = Device(
      deviceId: 'dev_2',
      type: DeviceType.fan,
      name: 'Ceiling Fan',
      firmwareVersion: '1.0.0',
      macAddress: 'AA:BB:CC:DD:EE:02',
      tenantId: 'tenant_1',
      buildingId: 'home_uuid_123',
      homeName: null,
      zone: 'Bedroom',
      lastHeartbeat: DateTime.now(),
    );

    final device3 = Device(
      deviceId: 'dev_3',
      type: DeviceType.ac,
      name: 'Office AC',
      firmwareVersion: '1.0.0',
      macAddress: 'AA:BB:CC:DD:EE:03',
      tenantId: 'tenant_1',
      buildingId: 'other_home_456',
      homeName: 'Other Home',
      zone: 'Main Office',
      lastHeartbeat: DateTime.now(),
    );

    final provider = DeviceProvider(
      repository: MemoryDeviceRepository([device1, device2, device3]),
    );

    while (provider.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }

    final property = const ManagedProperty(
      id: 'home_uuid_123',
      name: 'Aditya Home',
      address: '123 Street',
    );

    final matched = provider.visibleDevicesForProperty(
      user,
      property.name,
      propertyId: property.id,
    );

    expect(matched.length, 2);
    expect(matched.map((d) => d.deviceId).toSet(), {'dev_1', 'dev_2'});
  });
}
