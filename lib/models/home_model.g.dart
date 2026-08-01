// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeModel _$HomeModelFromJson(Map<String, dynamic> json) => HomeModel(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String?,
  category: json['category'] as String?,
  propertyType: json['propertyType'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$HomeModelToJson(HomeModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'category': instance.category,
  'propertyType': instance.propertyType,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
