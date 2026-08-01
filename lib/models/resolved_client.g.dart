// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolved_client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResolvedClient _$ResolvedClientFromJson(Map<String, dynamic> json) =>
    ResolvedClient(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$ResolvedClientToJson(ResolvedClient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
    };
