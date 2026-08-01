import 'package:json_annotation/json_annotation.dart';

part 'api_hierarchy.g.dart';

@JsonSerializable()
class ApiHome {
  final String id;
  final String name;
  final String? address;
  final List<ApiFloor>? floors;

  ApiHome({
    required this.id,
    required this.name,
    this.address,
    this.floors,
  });

  factory ApiHome.fromJson(Map<String, dynamic> json) => _$ApiHomeFromJson(json);
  Map<String, dynamic> toJson() => _$ApiHomeToJson(this);
}

@JsonSerializable()
class ApiFloor {
  final String id;
  final String name;
  @JsonKey(name: 'floor_number')
  final int floorNumber;
  final List<ApiRoom>? rooms;

  ApiFloor({
    required this.id,
    required this.name,
    required this.floorNumber,
    this.rooms,
  });

  factory ApiFloor.fromJson(Map<String, dynamic> json) => _$ApiFloorFromJson(json);
  Map<String, dynamic> toJson() => _$ApiFloorToJson(this);
}

@JsonSerializable()
class ApiRoom {
  final String id;
  final String name;
  final List<ApiDevice>? devices;

  ApiRoom({
    required this.id,
    required this.name,
    this.devices,
  });

  factory ApiRoom.fromJson(Map<String, dynamic> json) => _$ApiRoomFromJson(json);
  Map<String, dynamic> toJson() => _$ApiRoomToJson(this);
}

@JsonSerializable()
class ApiDevice {
  final String id;
  final String name;
  final String? command;
  final dynamic value;

  ApiDevice({
    required this.id,
    required this.name,
    this.command,
    this.value,
  });

  factory ApiDevice.fromJson(Map<String, dynamic> json) => _$ApiDeviceFromJson(json);
  Map<String, dynamic> toJson() => _$ApiDeviceToJson(this);
}
