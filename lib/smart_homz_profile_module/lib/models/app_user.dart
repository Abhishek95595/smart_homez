import 'user_role.dart';

/// Represents a logged-in user of the platform.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String tenantId; // society id
  final String? buildingId;
  final String? towerId;
  final String? flatId;
  final String avatarInitials;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.tenantId,
    this.buildingId,
    this.towerId,
    this.flatId,
    required this.avatarInitials,
  });

  String get unitLabel {
    if (towerId == null || flatId == null) return 'Facility Team';
    return '$towerId / $flatId';
  }
}
