import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class AlexaIntegrationService {
  AlexaIntegrationService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Issue a short-lived, single-use SSO token for App-to-App Alexa account linking.
  Future<Map<String, dynamic>?> generateLinkToken({
    String? redirectUri,
    String? state,
    String? scope,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        if (redirectUri != null && redirectUri.isNotEmpty)
          'redirectUri': redirectUri,
        if (state != null && state.isNotEmpty) 'state': state,
        if (scope != null && scope.isNotEmpty) 'scope': scope,
      };

      final Response<dynamic> response = await _api.post(
        ApiEndpoints.alexaLinkToken,
        data: body.isEmpty ? null : body,
      );

      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          response.data,
        );
        data['success'] = true;
        return data;
      }
      return {'success': false, 'error': 'Invalid server response'};
    } catch (error) {
      debugPrint('[AlexaService] Link token error: $error');
      final String msg = error.toString().contains('401')
          ? 'Session expired or Alexa connection server requires authentication.'
          : error
                .toString()
                .replaceFirst('Exception: ', '')
                .replaceFirst('ApiException: ', '');
      return {'success': false, 'error': msg};
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

  /// Convenience method to send an Alexa Smart Home v3 TurnOn/TurnOff PowerController directive.
  Future<bool> executeAlexaPowerCommand({
    required String endpointId,
    required bool turnOn,
  }) async {
    final Map<String, dynamic> directive = {
      'directive': {
        'header': {
          'namespace': 'Alexa.PowerController',
          'name': turnOn ? 'TurnOn' : 'TurnOff',
          'payloadVersion': '3',
          'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'endpoint': {'endpointId': endpointId},
        'payload': <String, dynamic>{},
      },
    };

    final result = await sendDirective(directive);
    if (result != null) return true;

    // Fallback to commands endpoint if directive returns null/error
    final cmdResult = await sendCommands({
      'endpointId': endpointId,
      'command': turnOn ? 'TurnOn' : 'TurnOff',
    });

    return cmdResult != null;
  }

  /// Convenience method to send an Alexa Smart Home v3 SetBrightness directive.
  Future<bool> executeAlexaBrightnessCommand({
    required String endpointId,
    required int brightnessLevel,
  }) async {
    final Map<String, dynamic> directive = {
      'directive': {
        'header': {
          'namespace': 'Alexa.BrightnessController',
          'name': 'SetBrightness',
          'payloadVersion': '3',
          'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'endpoint': {'endpointId': endpointId},
        'payload': {'brightness': brightnessLevel.clamp(0, 100)},
      },
    };

    final result = await sendDirective(directive);
    if (result != null) return true;

    final cmdResult = await sendCommands({
      'endpointId': endpointId,
      'command': 'SetBrightness',
      'value': brightnessLevel,
    });

    return cmdResult != null;
  }
}
