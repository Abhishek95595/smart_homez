import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/resolved_client.dart';

class ClientService {
  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Resolves the app user UUID (Phase 2).
  Future<ResolvedClient?> resolveClient({
    required String email,
    String? phone,
    String? name,
  }) async {
    final response = await _api.post(
      ApiEndpoints.resolveClient,
      data: {'email': email, 'phone': phone ?? '', 'name': name ?? 'App User'},
    );

    // Defensive parsing for likely wrappers {"success": true, "data": {...}}
    final dynamic data = response.data;
    ResolvedClient? client;

    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] != null) {
        client = ResolvedClient.fromJson(data['data']);
      } else if (data.containsKey('client') && data['client'] != null) {
        client = ResolvedClient.fromJson(data['client']);
      } else if (data.containsKey('id')) {
        client = ResolvedClient.fromJson(data);
      }
    }

    if (client != null) {
      debugPrint('[Client] Resolved UUID: ${client.id}');
      await _storage.write(key: 'resolved_client_uuid', value: client.id);
    }

    return client;
  }

  Future<String?> getResolvedUuid() =>
      _storage.read(key: 'resolved_client_uuid');
}
