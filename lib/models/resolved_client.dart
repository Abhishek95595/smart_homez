import 'package:json_annotation/json_annotation.dart';

part 'resolved_client.g.dart';

@JsonSerializable(createFactory: false)
class ResolvedClient {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final bool isNew;
  final bool notFound;

  ResolvedClient({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.isNew = false,
    this.notFound = false,
  });

  /// Defensive parsing matching Swagger response payload:
  /// {
  ///   "client_id": "4427abe3-fade-402c-ada5-4a17371b00a9",
  ///   "client_name": "...",
  ///   "email": "...",
  ///   "phone": "...",
  ///   "is_new": false,
  ///   "not_found": false
  /// }
  factory ResolvedClient.fromJson(Map<String, dynamic> json) {
    return ResolvedClient(
      id: (json['client_id'] ?? json['id'] ?? json['clientId'] ?? '')
          .toString(),
      name: (json['client_name'] ?? json['name'])?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      isNew: json['is_new'] == true,
      notFound: json['not_found'] == true,
    );
  }

  Map<String, dynamic> toJson() => _$ResolvedClientToJson(this);
}
