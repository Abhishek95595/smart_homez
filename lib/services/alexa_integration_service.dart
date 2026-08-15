import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class AlexaIntegrationService {
  AlexaIntegrationService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Issue a short-lived, single-use SSO token for App-to-App Alexa account linking.
  Future<String?> generateLinkToken() async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.alexaLinkToken,
      );
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          response.data,
        );
        if (data['success'] == true && data['token'] != null) {
          return data['token'].toString();
        }
      }
      return null;
    } catch (error) {
      debugPrint('[AlexaService] Link token error: $error');
      return null;
    }
  }

  /// Unified Alexa Smart Home v3 directive endpoint.
  Future<Map<String, dynamic>?> sendDirective(
    Map<String, dynamic> directive,
  ) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.alexaDirective,
        data: directive,
      );
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (error) {
      debugPrint('[AlexaService] Directive error: $error');
      return null;
    }
  }

  /// Discovery endpoint (returns a v3 Discover.Response envelope).
  Future<Map<String, dynamic>?> getDiscovery() async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.alexaDiscovery,
      );
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (error) {
      debugPrint('[AlexaService] Discovery error: $error');
      return null;
    }
  }

  /// State report endpoint.
  Future<Map<String, dynamic>?> getStateReport(
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.alexaState,
        data: payload,
      );
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (error) {
      debugPrint('[AlexaService] State report error: $error');
      return null;
    }
  }

  /// Commands endpoint.
  Future<Map<String, dynamic>?> sendCommands(
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.alexaCommands,
        data: payload,
      );
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (error) {
      debugPrint('[AlexaService] Commands error: $error');
      return null;
    }
  }
}
