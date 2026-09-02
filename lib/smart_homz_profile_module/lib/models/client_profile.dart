import 'package:flutter/foundation.dart';

/// Model representing the authenticated client's detailed profile from GET /api/v1/clients/{clientId}.
@immutable
class ClientProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final bool isActive;
  final String? timezone;
  final int homeCount;
  final int deviceCount;
  final int onlineDeviceCount;
  final String? permissionLevel;
  final DateTime? createdAt;

  const ClientProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.isActive = true,
    this.timezone,
    this.homeCount = 0,
    this.deviceCount = 0,
    this.onlineDeviceCount = 0,
    this.permissionLevel,
    this.createdAt,
  });

  /// The ratio of online devices to total devices, clamped between 0.0 and 1.0.
  /// Safely returns 0.0 if there are no devices.
  double get onlineRatio {
    if (deviceCount <= 0) return 0.0;
    return (onlineDeviceCount / deviceCount).clamp(0.0, 1.0);
  }

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final dateStr = json['created_at'] ?? json['createdAt'];
    if (dateStr != null && dateStr is String) {
      parsedDate = DateTime.tryParse(dateStr);
    }

    return ClientProfile(
      id: (json['client_id'] ?? json['id'] ?? '') as String,
      name:
          (json['client_name'] ?? json['name'] ?? 'Smart Home User') as String,
      email: (json['email'] ?? json['client_email']) as String?,
      phone:
          (json['phone'] ?? json['mobile'] ?? json['phone_number']) as String?,
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      timezone: (json['timezone'] ?? json['time_zone']) as String?,
      homeCount: (json['home_count'] ?? json['homeCount'] ?? 0) as int,
      deviceCount: (json['device_count'] ?? json['deviceCount'] ?? 0) as int,
      onlineDeviceCount:
          (json['online_device_count'] ?? json['onlineDeviceCount'] ?? 0)
              as int,
      permissionLevel:
          (json['permission_level'] ?? json['permissionLevel']) as String?,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': id,
      'client_name': name,
      'email': email,
      'phone': phone,
      'is_active': isActive,
      'timezone': timezone,
      'home_count': homeCount,
      'device_count': deviceCount,
      'online_device_count': onlineDeviceCount,
      'permission_level': permissionLevel,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ClientProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool? isActive,
    String? timezone,
    int? homeCount,
    int? deviceCount,
    int? onlineDeviceCount,
    String? permissionLevel,
    DateTime? createdAt,
  }) {
    return ClientProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      timezone: timezone ?? this.timezone,
      homeCount: homeCount ?? this.homeCount,
      deviceCount: deviceCount ?? this.deviceCount,
      onlineDeviceCount: onlineDeviceCount ?? this.onlineDeviceCount,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
