import 'package:json_annotation/json_annotation.dart';

part 'device_model.g.dart';

@JsonSerializable()
class DeviceModel {
  final String id;
  final String name;
  final String? type;
  final String? status;
  final String? command;
  final dynamic value;
  final String? homeId;
  final String? floorId;
  final String? roomId;
  final String? zone;

  DeviceModel({
    required this.id,
    required this.name,
    this.type,
    this.status,
    this.command,
    this.value,
    this.homeId,
    this.floorId,
    this.roomId,
    this.zone,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) =>
      _$DeviceModelFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceModelToJson(this);
}
