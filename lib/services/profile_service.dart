import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/client_profile.dart';
import '../models/home_model.dart';

/// Service responsible for fetching client profile metadata and associated homes
/// from the AuraBrain Tenant API using authenticated client-scoped endpoints.
class ProfileService {
  final ApiClient _apiClient;

  ProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Validates whether [clientId] is a valid UUID format.
  bool isValidClientUuid(String? clientId) {
    if (clientId == null) return false;
    return _uuidRegex.hasMatch(clientId.trim());
  }

  /// Fetches the client profile using GET /api/v1/clients/{clientId}.
  Future<ClientProfile?> getClientProfile(String clientId) async {
    final cleanId = clientId.trim();
    if (!isValidClientUuid(cleanId)) {
      debugPrint('[ProfileService] Rejected non-UUID clientId: $cleanId');
      return null;
    }

    try {
      final endpoint = ApiEndpoints.client(cleanId);
      final response = await _apiClient.get(endpoint);

      if (response.data != null) {
        final Map<String, dynamic> data;
        if (response.data is Map<String, dynamic>) {
          final resMap = response.data as Map<String, dynamic>;
          if (resMap['data'] is Map<String, dynamic>) {
            data = resMap['data'] as Map<String, dynamic>;
          } else {
            data = resMap;
          }
        } else {
          return null;
        }

        return ClientProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('[ProfileService] Error fetching client profile: $e');
      return null;
    }
  }

  /// Fetches homes belonging to the client using GET /api/v1/clients/{clientId}/homes.
  Future<List<HomeModel>> getClientHomes(String clientId) async {
    final cleanId = clientId.trim();
    if (!isValidClientUuid(cleanId)) {
      debugPrint(
        '[ProfileService] Rejected non-UUID clientId for homes: $cleanId',
      );
      return [];
    }

    try {
      final endpoint = ApiEndpoints.clientHomes(cleanId);
      final response = await _apiClient.get(endpoint);

      if (response.data != null) {
        final dynamic rawList;
        if (response.data is Map<String, dynamic>) {
          final resMap = response.data as Map<String, dynamic>;
          rawList = resMap['data'] ?? resMap['homes'] ?? [];
        } else if (response.data is List) {
          rawList = response.data;
        } else {
          return [];
        }

        if (rawList is List) {
          return rawList
              .whereType<Map<String, dynamic>>()
              .map((json) => HomeModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[ProfileService] Error fetching client homes: $e');
      return [];
    }
  }
}
