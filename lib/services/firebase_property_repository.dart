import 'property_repository.dart';

/// Backend-ready placeholder for Firebase/Firestore storage.
///
/// When Firebase is added, this class should use a collection layout like:
///
/// tenants/{tenantId}/properties/{propertyId}
/// tenants/{tenantId}/properties/{propertyId}/floors/{floorId}
/// tenants/{tenantId}/properties/{propertyId}/floors/{floorId}/rooms/{roomId}
///
/// Keep the provider and screens unchanged; only inject this repository instead
/// of [HivePropertyRepository] in `main.dart` or an environment switch.
class FirebasePropertyRepository implements PropertyRepository {
  final String tenantId;

  const FirebasePropertyRepository({required this.tenantId});

  @override
  Future<PropertySnapshot?> load() {
    throw UnimplementedError(
      'FirebasePropertyRepository.load must be implemented after adding '
      'firebase_core and cloud_firestore.',
    );
  }

  @override
  Future<void> save(PropertySnapshot snapshot) {
    throw UnimplementedError(
      'FirebasePropertyRepository.save must be implemented after adding '
      'firebase_core and cloud_firestore.',
    );
  }
}
