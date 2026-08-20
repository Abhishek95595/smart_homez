enum AlexaConnectionState {
  notConnected,
  connecting,
  connected,
  syncing,
  error,
}

class AlexaStatus {
  final bool connected;
  final int deviceCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const AlexaStatus({
    required this.connected,
    this.deviceCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
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
        json['deviceCount'] ?? json['device_count'] ?? json['devices_connected'] ?? 0;

    return AlexaStatus(
      connected: json['connected'] == true || json['is_connected'] == true,
      deviceCount: devCountVal is num ? devCountVal.toInt() : 0,
      lastSyncedAt: parsedSync,
      errorMessage: json['errorMessage']?.toString(),
    );
  }

  factory AlexaStatus.notConnected() => const AlexaStatus(connected: false);

  AlexaStatus copyWith({
    bool? connected,
    int? deviceCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return AlexaStatus(
      connected: connected ?? this.connected,
      deviceCount: deviceCount ?? this.deviceCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'connected': connected,
        'deviceCount': deviceCount,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        if (errorMessage != null) 'errorMessage': errorMessage,
      };
}
