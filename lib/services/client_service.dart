import 'dart:convert';
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
      data: {
        'email': email,
        'phone': phone ?? '',
        'name': name ?? 'App User',
      },
    );

    // 1. Log the raw response for debugging (Masking full JWT/Secrets)
    debugPrint('[Client Response] RAW: ${jsonEncode(response.data)}');

    // Defensive parsing for likely wrappers {"success": true, "data": {...}}
    final dynamic responseData = response.data;
    ResolvedClient? client;

    if (responseData is Map<String, dynamic>) {
      // 5. Update parser for wrappers
      if (responseData.containsKey('data') && responseData['data'] != null) {
        client = ResolvedClient.fromJson(responseData['data']);
      } else if (responseData.containsKey('client') && responseData['client'] != null) {
        client = ResolvedClient.fromJson(responseData['client']);
      } else if (responseData.containsKey('id') || responseData.containsKey('clientId')) {
        client = ResolvedClient.fromJson(responseData);
      }
    }

    if (client != null && client.id.isNotEmpty) {
      debugPrint('[Client] Resolved UUID: ${client.id}');
      await _storage.write(key: 'resolved_client_uuid', value: client.id);
    }
    
    return client;
  }

  Future<String?> getResolvedUuid() => _storage.read(key: 'resolved_client_uuid');
}
