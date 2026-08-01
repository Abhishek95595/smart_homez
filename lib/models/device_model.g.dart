// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceModel _$DeviceModelFromJson(Map<String, dynamic> json) => DeviceModel(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String?,
  status: json['status'] as String?,
  command: json['command'] as String?,
  value: json['value'],
  homeId: json['homeId'] as String?,
  floorId: json['floorId'] as String?,
  roomId: json['roomId'] as String?,
  zone: json['zone'] as String?,
);

Map<String, dynamic> _$DeviceModelToJson(DeviceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'status': instance.status,
      'command': instance.command,
      'value': instance.value,
      'homeId': instance.homeId,
      'floorId': instance.floorId,
      'roomId': instance.roomId,
      'zone': instance.zone,
    };
