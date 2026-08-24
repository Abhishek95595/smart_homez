enum AlexaConnectionState {
  notConnected,
  scanning,
  connecting,
  connected,
  syncing,
  error,
}

class AlexaWifiDevice {
  final String id;
  final String name;
  final String model;
  final String room;
  final String ipAddress;
  final String wifiFrequency;
  final int signalStrength;

  const AlexaWifiDevice({
    required this.id,
    required this.name,
    required this.model,
    required this.room,
    required this.ipAddress,
    this.wifiFrequency = '5 GHz',
    this.signalStrength = 4,
  });
}

class AlexaStatus {
  final bool connected;
  final int deviceCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final String? selectedDeviceName;
  final String? selectedDeviceIp;

  const AlexaStatus({
    required this.connected,
    this.deviceCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
    this.selectedDeviceName,
    this.selectedDeviceIp,
  });

  factory AlexaStatus.fromJson(Map<String, dynamic> json) {
    DateTime? parsedSync;
    final dynamic syncVal = json['lastSyncedAt'] ?? json['last_synced_at'];
    if (syncVal != null) {
      try {
        parsedSync = DateTime.parse(syncVal.toString());
      } catch (_) {}
    }

    final dynamic devCountVal =
        json['deviceCount'] ??
        json['device_count'] ??
        json['devices_connected'] ??
        0;

    return AlexaStatus(
      connected: json['connected'] == true || json['is_connected'] == true,
      deviceCount: devCountVal is num ? devCountVal.toInt() : 0,
      lastSyncedAt: parsedSync,
      errorMessage: json['errorMessage']?.toString(),
      selectedDeviceName:
          json['selectedDeviceName']?.toString() ??
          json['device_name']?.toString(),
      selectedDeviceIp:
          json['selectedDeviceIp']?.toString() ?? json['device_ip']?.toString(),
    );
  }

  factory AlexaStatus.notConnected() => const AlexaStatus(connected: false);

  AlexaStatus copyWith({
    bool? connected,
    int? deviceCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
    String? selectedDeviceName,
    String? selectedDeviceIp,
  }) {
    return AlexaStatus(
      connected: connected ?? this.connected,
      deviceCount: deviceCount ?? this.deviceCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDeviceName: selectedDeviceName ?? this.selectedDeviceName,
      selectedDeviceIp: selectedDeviceIp ?? this.selectedDeviceIp,
    );
  }

  Map<String, dynamic> toJson() => {
    'connected': connected,
    'deviceCount': deviceCount,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (selectedDeviceName != null) 'selectedDeviceName': selectedDeviceName,
    if (selectedDeviceIp != null) 'selectedDeviceIp': selectedDeviceIp,
  };
}
