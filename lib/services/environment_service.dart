import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class EnvironmentService {
  EnvironmentService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Astronomical solar status for a home (ISO-8601 UTC sunrise, solar noon, sunset + sun state).
  Future<Map<String, dynamic>?> getSolarStatus() async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.environmentSolar,
      );
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (error) {
      debugPrint('[EnvironmentService] Solar status error: $error');
      return null;
    }
  }

  /// Read the client-facing Dusk-to-Dawn setting for a home.
  Future<Map<String, dynamic>?> getDuskDawn() async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.environmentDuskDawn,
      );
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (error) {
      debugPrint('[EnvironmentService] Get dusk-dawn error: $error');
      return null;
    }
  }

  /// Update the Dusk-to-Dawn setting for a home.
  Future<bool> setDuskDawn(Map<String, dynamic> payload) async {
    try {
      final Response<dynamic> response = await _api.put(
        ApiEndpoints.environmentDuskDawn,
        data: payload,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data['success'] == true;
      }
      return false;
    } catch (error) {
      debugPrint('[EnvironmentService] Set dusk-dawn error: $error');
      return false;
    }
  }

  /// Evaluates local temperature, humidity, and rain conditions and returns prompt cards.
  Future<List<Map<String, dynamic>>> getWeatherPrompts() async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.environmentWeatherPrompts,
      );
      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
      return const [];
    } catch (error) {
      debugPrint('[EnvironmentService] Weather prompts error: $error');
      return const [];
    }
  }

  /// Update and persist the home's exact location + geofence + Home Wi-Fi SSID.
  Future<bool> setHomeLocation(Map<String, dynamic> payload) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.environmentHomeLocation,
        data: payload,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data['success'] == true;
      }
      return false;
    } catch (error) {
      debugPrint('[EnvironmentService] Set home location error: $error');
      return false;
    }
  }

  /// Report family member presence (Wi-Fi + GPS hybrid).
  Future<bool> reportPresence(Map<String, dynamic> payload) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.environmentPresence,
        data: payload,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data['success'] == true;
      }
      return false;
    } catch (error) {
      debugPrint('[EnvironmentService] Report presence error: $error');
      return false;
    }
  }

  /// Aggregate family presence for a home (Home State + member statuses).
  Future<Map<String, dynamic>?> getPresence() async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.environmentPresence,
      );
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (error) {
      debugPrint('[EnvironmentService] Get presence error: $error');
      return null;
    }
  }

  /// List favorite scenes for native lockscreen widgets (iOS WidgetKit / Android App Widgets).
  Future<List<Map<String, dynamic>>> getWidgets() async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.environmentWidgets,
      );
      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
      return const [];
    } catch (error) {
      debugPrint('[EnvironmentService] Get widgets error: $error');
      return const [];
    }
  }
}
