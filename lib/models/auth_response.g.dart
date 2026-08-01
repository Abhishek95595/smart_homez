// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  success: json['success'] as bool,
  token: json['token'] as String?,
  expiresAt: json['expiresAt'] as String?,
  clientName: json['clientName'] as String?,
  clientId: json['clientId'] as String?,
  permissionLevel: json['permissionLevel'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'token': instance.token,
      'expiresAt': instance.expiresAt,
      'clientName': instance.clientName,
      'clientId': instance.clientId,
      'permissionLevel': instance.permissionLevel,
      'error': instance.error,
    };
