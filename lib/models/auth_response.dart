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

  /// 4. Replace unsafe casts with safe parsing
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] == true,
      token: json['token']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
      clientName: json['clientName']?.toString(),
      clientId: json['clientId']?.toString(),
      permissionLevel: json['permissionLevel']?.toString(),
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
