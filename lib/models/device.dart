enum DeviceType {
  light,
  fan,
  ac,
  pump,
  smokeSensor,
  gasSensor,
  waterLevelSensor,
  energyMeter,
  scene,
}

extension DeviceTypeX on DeviceType {
  String get label {
    switch (this) {
      case DeviceType.light:
        return 'Light';
      case DeviceType.fan:
        return 'Fan';
      case DeviceType.ac:
        return 'AC';
      case DeviceType.pump:
        return 'Pump';
      case DeviceType.smokeSensor:
        return 'Smoke Sensor';
      case DeviceType.gasSensor:
        return 'Gas Sensor';
      case DeviceType.waterLevelSensor:
        return 'Water Level Sensor';
      case DeviceType.energyMeter:
        return 'Energy Meter';
      case DeviceType.scene:
        return 'Scene';
    }
  }

  bool get isControllable =>
      this == DeviceType.light ||
      this == DeviceType.fan ||
      this == DeviceType.ac ||
      this == DeviceType.pump ||
      this == DeviceType.scene;

  bool get isSensorOnly =>
      this == DeviceType.smokeSensor ||
      this == DeviceType.gasSensor ||
      this == DeviceType.waterLevelSensor ||
      this == DeviceType.energyMeter;
}

enum DeviceStatus { online, offline, fault, maintenance }

/// Mirrors device registry metadata as described in the PRD's
/// "Example device metadata" section.
class Device {
  final String deviceId;
  final DeviceType type;
  final String name;
  final String firmwareVersion;
  final String macAddress;
  final String tenantId;
  final String buildingId;
  final String? floorId;
  final String? roomId;
  final String? towerId;
  final String? flatId;
  final String zone; // room/common-area name
  final String? homeName;
  final String? floorName;
  final String? roomName;
  DeviceStatus status;
  bool isOn;
  double? dimLevel; // 0-100 for dimmable lights/fans
  DateTime lastHeartbeat;
  final Map<String, dynamic> configThresholds;

  Device({
    required this.deviceId,
    required this.type,
    required this.name,
    required this.firmwareVersion,
    required this.macAddress,
    required this.tenantId,
    required this.buildingId,
    this.floorId,
    this.roomId,
    this.towerId,
    this.flatId,
    required this.zone,
    this.homeName,
    this.floorName,
    this.roomName,
    this.status = DeviceStatus.online,
    this.isOn = false,
    this.dimLevel,
    required this.lastHeartbeat,
    this.configThresholds = const {},
  });

  Device copyWith({
    DeviceType? type,
    String? name,
    String? firmwareVersion,
    String? macAddress,
    String? buildingId,
    String? floorId,
    String? roomId,
    String? towerId,
    String? flatId,
    String? zone,
    String? homeName,
    String? floorName,
    String? roomName,
    DeviceStatus? status,
    bool? isOn,
    double? dimLevel,
    DateTime? lastHeartbeat,
  }) {
    return Device(
      deviceId: deviceId,
      type: type ?? this.type,
      name: name ?? this.name,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      macAddress: macAddress ?? this.macAddress,
      tenantId: tenantId,
      buildingId: buildingId ?? this.buildingId,
      floorId: floorId ?? this.floorId,
      roomId: roomId ?? this.roomId,
      towerId: towerId ?? this.towerId,
      flatId: flatId ?? this.flatId,
      zone: zone ?? this.zone,
      homeName: homeName ?? this.homeName,
      floorName: floorName ?? this.floorName,
      roomName: roomName ?? this.roomName,
      status: status ?? this.status,
      isOn: isOn ?? this.isOn,
      dimLevel: dimLevel ?? this.dimLevel,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      configThresholds: configThresholds,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'type': type.name,
    'name': name,
    'firmwareVersion': firmwareVersion,
    'macAddress': macAddress,
    'tenantId': tenantId,
    'buildingId': buildingId,
    'floorId': floorId,
    'roomId': roomId,
    'towerId': towerId,
    'flatId': flatId,
    'zone': zone,
    'homeName': homeName,
    'floorName': floorName,
    'roomName': roomName,
    'status': status.name,
    'isOn': isOn,
    'dimLevel': dimLevel,
    'lastHeartbeat': lastHeartbeat.toIso8601String(),
    'configThresholds': configThresholds,
  };

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['deviceId'] as String,
      type: DeviceType.values.byName(json['type'] as String),
      name: json['name'] as String,
      firmwareVersion: json['firmwareVersion'] as String? ?? '1.0.0',
      macAddress: json['macAddress'] as String? ?? '',
      tenantId: json['tenantId'] as String,
      buildingId: json['buildingId'] as String,
      floorId: json['floorId'] as String?,
      roomId: json['roomId'] as String?,
      towerId: json['towerId'] as String?,
      flatId: json['flatId'] as String?,
      zone: json['zone'] as String,
      homeName: json['homeName'] as String?,
      floorName: json['floorName'] as String?,
      roomName: json['roomName'] as String?,
      status: DeviceStatus.values.byName(
        json['status'] as String? ?? DeviceStatus.online.name,
      ),
      isOn: json['isOn'] as bool? ?? false,
      dimLevel: (json['dimLevel'] as num?)?.toDouble(),
      lastHeartbeat:
          DateTime.tryParse(json['lastHeartbeat'] as String? ?? '') ??
          DateTime.now(),
      configThresholds: Map<String, dynamic>.from(
        json['configThresholds'] as Map? ?? const {},
      ),
    );
  }

  /// MQTT command payload as per PRD spec:
  /// { "command": "relay_on", "target": "pump_1", "requested_by": "...", "timestamp": "..." }
  Map<String, dynamic> buildCommandPayload({
    required String command,
    required String requestedBy,
  }) {
    return {
      'command': command,
      'target': deviceId,
      'requested_by': requestedBy,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
