import '../models/device.dart';
import 'device_repository.dart';

/// Backend-ready placeholder for Firebase/Firestore device registry storage.
///
/// Suggested collection layout:
///
/// tenants/{tenantId}/devices/{deviceId}
///
/// Device telemetry should not be written here as normal document updates.
/// Use MQTT/Realtime Database/Firestore time-series subcollections depending on
/// expected frequency. This repository is for registry metadata and room links.
class FirebaseDeviceRepository implements DeviceRepository {
  final String tenantId;

  const FirebaseDeviceRepository({required this.tenantId});

  @override
  Future<List<Device>?> load() {
    throw UnimplementedError(
      'FirebaseDeviceRepository.load must be implemented after adding '
      'firebase_core and cloud_firestore.',
    );
  }

  @override
  Future<void> save(List<Device> devices) {
    throw UnimplementedError(
      'FirebaseDeviceRepository.save must be implemented after adding '
      'firebase_core and cloud_firestore.',
    );
  }
}
