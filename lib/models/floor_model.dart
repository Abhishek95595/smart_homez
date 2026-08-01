import 'package:json_annotation/json_annotation.dart';

part 'floor_model.g.dart';

@JsonSerializable()
class FloorModel {
  final String id;
  final String name;
  @JsonKey(name: 'floor_number')
  final int floorNumber;

  FloorModel({
    required this.id,
    required this.name,
    required this.floorNumber,
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) => _$FloorModelFromJson(json);
  Map<String, dynamic> toJson() => _$FloorModelToJson(this);
}
