// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_hierarchy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiHome _$ApiHomeFromJson(Map<String, dynamic> json) => ApiHome(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String?,
  floors: (json['floors'] as List<dynamic>?)
      ?.map((e) => ApiFloor.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ApiHomeToJson(ApiHome instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'floors': instance.floors,
};

ApiFloor _$ApiFloorFromJson(Map<String, dynamic> json) => ApiFloor(
  id: json['id'] as String,
  name: json['name'] as String,
  floorNumber: (json['floor_number'] as num).toInt(),
  rooms: (json['rooms'] as List<dynamic>?)
      ?.map((e) => ApiRoom.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ApiFloorToJson(ApiFloor instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'floor_number': instance.floorNumber,
  'rooms': instance.rooms,
};

ApiRoom _$ApiRoomFromJson(Map<String, dynamic> json) => ApiRoom(
  id: json['id'] as String,
  name: json['name'] as String,
  devices: (json['devices'] as List<dynamic>?)
      ?.map((e) => ApiDevice.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ApiRoomToJson(ApiRoom instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'devices': instance.devices,
};

ApiDevice _$ApiDeviceFromJson(Map<String, dynamic> json) => ApiDevice(
  id: json['id'] as String,
  name: json['name'] as String,
  command: json['command'] as String?,
  value: json['value'],
);

Map<String, dynamic> _$ApiDeviceToJson(ApiDevice instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'command': instance.command,
  'value': instance.value,
};
