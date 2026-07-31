import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/property_provider.dart';
import 'package:smart_homez/services/device_repository.dart';
import 'package:smart_homez/services/property_repository.dart';

/// Use these helpers in widget/provider tests to avoid opening Hive boxes.
/// This keeps tests fast and prevents:
/// "HiveError: You need to initialize Hive or provide a path to store the box."
DeviceProvider createTestDeviceProvider() {
  return DeviceProvider(repository: MemoryDeviceRepository());
}

PropertyProvider createTestPropertyProvider() {
  return PropertyProvider(repository: MemoryPropertyRepository());
}
