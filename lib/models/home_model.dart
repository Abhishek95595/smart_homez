import 'package:json_annotation/json_annotation.dart';

part 'home_model.g.dart';

@JsonSerializable()
class HomeModel {
  final String id;
  final String name;
  final String? address;
  final String? category;
  final String? propertyType;
  final double? latitude;
  final double? longitude;

  HomeModel({
    required this.id,
    required this.name,
    this.address,
    this.category,
    this.propertyType,
    this.latitude,
    this.longitude,
  });

  factory HomeModel.fromJson(Map<String, dynamic> json) =>
      _$HomeModelFromJson(json);
  Map<String, dynamic> toJson() => _$HomeModelToJson(this);
}
