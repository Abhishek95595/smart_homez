import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final bool success;
  final String? token;
  final String? expiresAt;
  final String? clientName;
  final String? clientId;
  final String? permissionLevel;
  final String? error;

  AuthResponse({
    required this.success,
    this.token,
    this.expiresAt,
    this.clientName,
    this.clientId,
    this.permissionLevel,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
