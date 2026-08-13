class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.homeCount,
    required this.deviceCount,
    required this.onlineDeviceCount,
    this.email,
    this.phone,
    this.timezone,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final bool isActive;
  final String? timezone;
  final int homeCount;
  final int deviceCount;
  final int onlineDeviceCount;

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      isActive: json['is_active'] == true,
      timezone: json['timezone']?.toString(),
      homeCount: (json['home_count'] as num?)?.toInt() ?? 0,
      deviceCount: (json['device_count'] as num?)?.toInt() ?? 0,
      onlineDeviceCount: (json['online_device_count'] as num?)?.toInt() ?? 0,
    );
  }
}
