/// User roles as defined in the PRD role matrix.
enum UserRole { superAdmin, facilityManager, resident, security, maintenance }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.facilityManager:
        return 'Society Manager';
      case UserRole.resident:
        return 'Resident';
      case UserRole.security:
        return 'Security Staff';
      case UserRole.maintenance:
        return 'Maintenance Staff';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.superAdmin:
        return 'Admin';
      case UserRole.facilityManager:
        return 'Manager';
      case UserRole.resident:
        return 'Resident';
      case UserRole.security:
        return 'Security';
      case UserRole.maintenance:
        return 'Maintenance';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.resident,
    );
  }

  /// Whether this role can issue device commands (relay_on/off etc).
  bool get canControlDevices =>
      this == UserRole.superAdmin ||
      this == UserRole.facilityManager ||
      this == UserRole.resident;

  /// Whether this role can see the full building/tower hierarchy (BMS view).
  bool get canViewAllBuildings =>
      this == UserRole.superAdmin || this == UserRole.facilityManager;

  /// Whether this role can manage tickets/work orders.
  bool get canManageTickets =>
      this == UserRole.superAdmin ||
      this == UserRole.facilityManager ||
      this == UserRole.maintenance;

  /// Whether this role can provision/manage devices & users.
  bool get canAdminister =>
      this == UserRole.superAdmin || this == UserRole.facilityManager;

  /// Whether this role can add/edit/delete homes, floors, rooms, and devices.
  bool get canManageProperties => canAdminister;

  /// Whether this role sees the Energy Analytics tab.
  /// Security/Maintenance focus on safety & work orders, not billing data.
  bool get canViewEnergy =>
      this == UserRole.superAdmin ||
      this == UserRole.facilityManager ||
      this == UserRole.resident;

  /// Whether this role sees the Water/Pump Automation tab at all.
  bool get canViewWater => this != UserRole.security;

  /// Whether this role can actually start/stop the pump or change pump mode.
  /// Residents can view tank/pump state but not operate shared infrastructure.
  bool get canControlWaterPump =>
      this == UserRole.superAdmin ||
      this == UserRole.facilityManager ||
      this == UserRole.maintenance;

  /// Whether this role can acknowledge/close safety alerts (operational action).
  bool get canAcknowledgeAlerts => this != UserRole.resident;

  /// Whether this role can access the Admin Console (property/user overview).
  bool get canAccessAdminConsole => canAdminister;

  /// Whether this role can access Tenant Administration.
  bool get canAccessTenantAdmin => canAdminister;

  /// Whether this role can access Platform Administration.
  bool get canAccessPlatformAdmin => this == UserRole.superAdmin;
}
