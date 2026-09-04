import 'package:flutter/material.dart';

class UnassignedDevice {
  final String id;
  final String name;
  final String type;
  final String? icon;
  final String? vendor;
  final String? suggestedRoomId;
  final String? suggestedRoomName;
  final double? confidence; // 0.0 to 1.0 if provided by backend

  const UnassignedDevice({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.vendor,
    this.suggestedRoomId,
    this.suggestedRoomName,
    this.confidence,
  });

  IconData get iconData {
    final norm = type.toLowerCase();
    if (norm.contains('light') ||
        norm.contains('bulb') ||
        norm.contains('lamp')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (norm.contains('fan')) {
      return Icons.mode_fan_off_outlined;
    }
    if (norm.contains('ac') ||
        norm.contains('air') ||
        norm.contains('climate') ||
        norm.contains('thermostat')) {
      return Icons.ac_unit_rounded;
    }
    if (norm.contains('pump') || norm.contains('water')) {
      return Icons.water_drop_outlined;
    }
    if (norm.contains('smoke') ||
        norm.contains('fire') ||
        norm.contains('gas')) {
      return Icons.local_fire_department_outlined;
    }
    if (norm.contains('tv') ||
        norm.contains('media') ||
        norm.contains('screen')) {
      return Icons.tv_rounded;
    }
    if (norm.contains('lock') ||
        norm.contains('door') ||
        norm.contains('security')) {
      return Icons.lock_outline_rounded;
    }
    if (norm.contains('plug') ||
        norm.contains('socket') ||
        norm.contains('switch')) {
      return Icons.power_outlined;
    }
    if (norm.contains('camera')) {
      return Icons.videocam_outlined;
    }
    if (norm.contains('sensor')) {
      return Icons.sensors_rounded;
    }
    return Icons.devices_other_rounded;
  }

  factory UnassignedDevice.fromJson(Map<String, dynamic> json) {
    // Backend may return confidence as num, string or nested
    double? parsedConfidence;
    final dynamic rawConf =
        json['confidence'] ??
        json['suggestion_confidence'] ??
        json['match_score'];
    if (rawConf is num) {
      parsedConfidence = rawConf.toDouble();
    } else if (rawConf is String) {
      parsedConfidence = double.tryParse(rawConf);
    }

    return UnassignedDevice(
      id: (json['id'] ?? json['device_id'] ?? json['deviceId'] ?? '')
          .toString(),
      name:
          (json['name'] ??
                  json['device_name'] ??
                  json['deviceName'] ??
                  'Unnamed Device')
              .toString(),
      type:
          (json['type'] ?? json['device_type'] ?? json['deviceType'] ?? 'other')
              .toString(),
      icon: json['icon']?.toString(),
      vendor: json['vendor']?.toString(),
      suggestedRoomId:
          (json['suggested_room_id'] ??
                  json['suggestedRoomId'] ??
                  json['suggested_room']?['id'])
              ?.toString(),
      suggestedRoomName:
          (json['suggested_room_name'] ??
                  json['suggestedRoomName'] ??
                  json['suggested_room']?['name'])
              ?.toString(),
      confidence: parsedConfidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    if (icon != null) 'icon': icon,
    if (vendor != null) 'vendor': vendor,
    if (suggestedRoomId != null) 'suggested_room_id': suggestedRoomId,
    if (suggestedRoomName != null) 'suggested_room_name': suggestedRoomName,
    if (confidence != null) 'confidence': confidence,
  };
}
