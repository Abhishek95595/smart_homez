import 'package:json_annotation/json_annotation.dart';

part 'resolved_client.g.dart';

@JsonSerializable()
class ResolvedClient {
  final String id;
  final String? name;
  final String? email;
  final String? phone;

  ResolvedClient({required this.id, this.name, this.email, this.phone});

  factory ResolvedClient.fromJson(Map<String, dynamic> json) =>
      _$ResolvedClientFromJson(json);
  Map<String, dynamic> toJson() => _$ResolvedClientToJson(this);
}
