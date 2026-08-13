import 'package:json_annotation/json_annotation.dart';

part 'resolved_client.g.dart';

@JsonSerializable(createFactory: false)
class ResolvedClient {
  final String id;
  final String? name;
  final String? email;
  final String? phone;

  ResolvedClient({required this.id, this.name, this.email, this.phone});

  /// Defensive parsing to prevent "Null is not a subtype of type String" in type cast
  factory ResolvedClient.fromJson(Map<String, dynamic> json) {
    return ResolvedClient(
      id: (json['id'] ?? json['clientId'] ?? '').toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$ResolvedClientToJson(this);
}
