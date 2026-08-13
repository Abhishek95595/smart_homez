class DeviceModel {
  final String id;
  final String name;
  final String? type;
  final String? subtype;
  final String? vendor;
  final String? status;
  final dynamic value;
  final String? homeId;
  final String? floorId;
  final String? roomId;
  final String? homeName;
  final String? floorName;
  final String? roomName;
  final String? zone;
  final bool isOnline;
  final bool isOn;
  final int? brightness;
  final DateTime? lastUpdated;

  const DeviceModel({
    required this.id,
    required this.name,
    this.type,
    this.subtype,
    this.vendor,
    this.status,
    this.value,
    this.homeId,
    this.floorId,
    this.roomId,
    this.homeName,
    this.floorName,
    this.roomName,
    this.zone,
    this.isOnline = false,
    this.isOn = false,
    this.brightness,
    this.lastUpdated,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    final state = json['state'] is Map
        ? Map<String, dynamic>.from(json['state'] as Map)
        : <String, dynamic>{};

    final rawState = (state['state'] ?? json['status'] ?? json['value'] ?? '')
        .toString()
        .trim();
    final normalized = rawState.toLowerCase();

    return DeviceModel(
      id: (json['id'] ?? json['deviceId'] ?? json['device_id'] ?? '')
          .toString(),
      name: (json['name'] ?? json['deviceName'] ?? 'Unnamed Device').toString(),
      type: json['type']?.toString(),
      subtype: json['subtype']?.toString(),
      vendor: json['vendor']?.toString(),
      status: rawState.isEmpty ? null : rawState,
      value: state['state'] ?? json['value'],
      homeId: (json['homeId'] ?? json['home_id'])?.toString(),
      floorId: (json['floorId'] ?? json['floor_id'])?.toString(),
      roomId: (json['roomId'] ?? json['room_id'])?.toString(),
      homeName: (json['home'] ?? json['homeName'] ?? json['home_name'])
          ?.toString(),
      floorName: (json['floor'] ?? json['floorName'] ?? json['floor_name'])
          ?.toString(),
      roomName: (json['room'] ?? json['roomName'] ?? json['room_name'])
          ?.toString(),
      zone: json['zone']?.toString(),
      isOnline: json['is_online'] == true || json['isOnline'] == true,
      isOn:
          normalized == 'on' ||
          normalized == '1' ||
          normalized == 'true' ||
          normalized == 'active',
      brightness: _toInt(state['brightness'] ?? json['brightness']),
      lastUpdated: DateTime.tryParse(
        (json['last_updated'] ?? json['lastUpdated'] ?? '').toString(),
      )?.toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'subtype': subtype,
    'vendor': vendor,
    'status': status,
    'value': value,
    'homeId': homeId,
    'floorId': floorId,
    'roomId': roomId,
    'homeName': homeName,
    'floorName': floorName,
    'roomName': roomName,
    'zone': zone,
    'isOnline': isOnline,
    'isOn': isOn,
    'brightness': brightness,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
