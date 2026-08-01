// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'floor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FloorModel _$FloorModelFromJson(Map<String, dynamic> json) => FloorModel(
  id: json['id'] as String,
  name: json['name'] as String,
  floorNumber: (json['floor_number'] as num).toInt(),
);

Map<String, dynamic> _$FloorModelToJson(FloorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'floor_number': instance.floorNumber,
    };
