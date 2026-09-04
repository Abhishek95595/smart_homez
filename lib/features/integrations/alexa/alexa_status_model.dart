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
  final bool linked;
  final bool connected;
  final int deviceCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final String? selectedDeviceName;
  final String? selectedDeviceIp;

  const AlexaStatus({
    this.linked = false,
    required this.connected,
    this.deviceCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
    this.selectedDeviceName,
    this.selectedDeviceIp,
  });

  factory AlexaStatus.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = json;
    if (json['data'] is Map<String, dynamic>) {
      data = Map<String, dynamic>.from(json['data'] as Map);
    }

    DateTime? parsedSync;
    final dynamic syncVal = data['lastSyncedAt'] ?? data['last_synced_at'];
    if (syncVal != null) {
      try {
        parsedSync = DateTime.parse(syncVal.toString());
      } catch (_) {}
    }

    final dynamic devCountVal =
        data['deviceCount'] ??
        data['device_count'] ??
        data['devices_connected'] ??
        0;

    final bool isLinked = data['linked'] == true || data['is_linked'] == true;
    final bool isConnected =
        data['connected'] == true || data['is_connected'] == true;

    return AlexaStatus(
      linked: isLinked,
      connected: isConnected,
      deviceCount: devCountVal is num ? devCountVal.toInt() : 0,
      lastSyncedAt: parsedSync,
      errorMessage: data['errorMessage']?.toString(),
      selectedDeviceName:
          data['selectedDeviceName']?.toString() ??
          data['device_name']?.toString(),
      selectedDeviceIp:
          data['selectedDeviceIp']?.toString() ?? data['device_ip']?.toString(),
    );
  }

  factory AlexaStatus.notConnected() =>
      const AlexaStatus(linked: false, connected: false);

  AlexaStatus copyWith({
    bool? linked,
    bool? connected,
    int? deviceCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
    String? selectedDeviceName,
    String? selectedDeviceIp,
  }) {
    return AlexaStatus(
      linked: linked ?? this.linked,
      connected: connected ?? this.connected,
      deviceCount: deviceCount ?? this.deviceCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDeviceName: selectedDeviceName ?? this.selectedDeviceName,
      selectedDeviceIp: selectedDeviceIp ?? this.selectedDeviceIp,
    );
  }

  Map<String, dynamic> toJson() => {
    'linked': linked,
    'connected': connected,
    'deviceCount': deviceCount,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (selectedDeviceName != null) 'selectedDeviceName': selectedDeviceName,
    if (selectedDeviceIp != null) 'selectedDeviceIp': selectedDeviceIp,
  };
}
