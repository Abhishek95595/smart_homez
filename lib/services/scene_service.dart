import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/scene_model.dart';
import '../core/network/api_exception.dart';

class SceneService {
  SceneService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  bool _isValidUuid(String? str) {
    if (str == null) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(str);
  }

  /// 1. GET /api/v1/clients/{clientId}/scenes
  /// List all scenes for the authenticated client.
  Future<List<SceneModel>> getScenes(String clientId) async {
    if (!_isValidUuid(clientId)) {
      debugPrint('[SceneService] Invalid clientId: $clientId');
      return const [];
    }
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.clientScenes(clientId),
      );
      final dynamic responseBody = response.data;
      if (responseBody is! Map) return const [];

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      final dynamic data = body['data'];

      if (body['success'] != true || data is! Map || data['scenes'] is! List) {
        return const [];
      }

      final List<dynamic> scenesList = data['scenes'];
      return scenesList
          .whereType<Map>()
          .map((item) => SceneModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (error) {
      debugPrint('[SceneService] Get scenes error: $error');
      return const [];
    }
  }

  /// 2. POST /api/v1/clients/{clientId}/scenes
  /// Create a new scene for the authenticated client with one or more device actions.
  Future<SceneModel?> createScene(
    String clientId, {
    String? tenantId,
    required String name,
    String? description,
    String? icon,
    bool isFavorite = false,
    required List<SceneActionModel> actions,
    int recurrenceDays = 0,
    String? scheduledTime,
    int timezoneOffsetMinutes = 330,
    bool isScheduleEnabled = false,
    String? requestId,
  }) async {
    if (!_isValidUuid(clientId)) {
      debugPrint('[SceneService] Invalid clientId: $clientId');
      return null;
    }
    final Map<String, dynamic> payload = {
      if (_isValidUuid(tenantId)) 'tenantId': tenantId,
      'clientId': clientId,
      'name': name.trim(),
      'description': description?.trim(),
      'icon': icon,
      'isFavorite': isFavorite,
      'actions': actions.map((a) => a.toJson()).toList(),
      'recurrenceDays': recurrenceDays,
      'scheduledTime': scheduledTime,
      'timezoneOffsetMinutes': timezoneOffsetMinutes,
      'isScheduleEnabled': isScheduleEnabled,
    };
    if (kDebugMode) {
      debugPrint('[SceneService] POST scene ${requestId ?? 'none'}');
      debugPrint(
        '[SceneService] POST client scenes payload: ${jsonEncode(payload)}',
      );
    }

    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.clientScenes(clientId),
        data: payload,
      );

      final dynamic responseBody = response.data;
      if (responseBody is! Map) return null;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      final dynamic data = body['data'];

      if (body['success'] != true || data is! Map) return null;

      return SceneModel.fromJson(Map<String, dynamic>.from(data));
    } catch (error) {
      if (kDebugMode) {
        int? statusCode;
        dynamic responseData;
        dynamic validationErrors;

        if (error is ApiException) {
          statusCode = error.statusCode;
          responseData = error.data;
          if (error.data is Map) {
            validationErrors =
                (error.data as Map)['errors'] ?? (error.data as Map)['error'];
          }
        } else if (error is DioException) {
          statusCode = error.response?.statusCode;
          responseData = error.response?.data;
          if (error.response?.data is Map) {
            validationErrors =
                (error.response?.data as Map)['errors'] ??
                (error.response?.data as Map)['error'];
          }
        }

        if (statusCode == 400) {
          debugPrint('[SceneService] HTTP 400 Bad Request details:');
          debugPrint('  - Status Code: $statusCode');
          debugPrint('  - Request Body: ${jsonEncode(payload)}');
          debugPrint(
            '  - Response Data: ${responseData != null ? jsonEncode(responseData) : null}',
          );
          debugPrint(
            '  - Validation Errors: ${validationErrors != null ? jsonEncode(validationErrors) : null}',
          );
        } else {
          debugPrint(
            '[SceneService] Create scene error: $error (status: $statusCode)',
          );
        }
      }
      return null;
    }
  }

  /// 3. GET /api/v1/clients/{clientId}/scenes/{id}
  /// Get a single scene by its ID, including its device actions.
  Future<SceneModel?> getScene(String clientId, String sceneId) async {
    if (!_isValidUuid(clientId) || !_isValidUuid(sceneId)) {
      debugPrint(
        '[SceneService] Invalid clientId or sceneId: $clientId, $sceneId',
      );
      return null;
    }
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.clientScene(clientId, sceneId),
      );
      final dynamic responseBody = response.data;
      if (responseBody is! Map) return null;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      final dynamic data = body['data'];

      if (body['success'] != true || data is! Map) return null;

      return SceneModel.fromJson(Map<String, dynamic>.from(data));
    } catch (error) {
      debugPrint('[SceneService] Get scene error: $error');
      return null;
    }
  }

  /// 4. PUT /api/v1/clients/{clientId}/scenes/{id}
  /// Update a scene's name, description, icon, isFavorite, or its device actions.
  Future<SceneModel?> updateScene(
    String clientId, {
    required String sceneId,
    String? tenantId,
    String? name,
    String? description,
    String? icon,
    bool? isFavorite,
    List<SceneActionModel>? actions,
    int? recurrenceDays,
    String? scheduledTime,
    int? timezoneOffsetMinutes,
    bool? isScheduleEnabled,
    String? requestId,
  }) async {
    if (!_isValidUuid(clientId) || !_isValidUuid(sceneId)) {
      debugPrint(
        '[SceneService] Invalid clientId or sceneId: $clientId, $sceneId',
      );
      return null;
    }
    if (kDebugMode) {
      debugPrint('[SceneService] PUT scene ${requestId ?? 'none'}');
    }
    try {
      final Response<dynamic> response = await _api.put(
        ApiEndpoints.clientScene(clientId, sceneId),
        data: {
          if (_isValidUuid(tenantId)) 'tenantId': tenantId,
          'clientId': clientId,
          if (name != null) 'name': name.trim(),
          'description': description?.trim(),
          'icon': icon,
          'isFavorite': isFavorite,
          if (actions != null)
            'actions': actions.map((a) => a.toJson()).toList(),
          if (recurrenceDays != null) 'recurrenceDays': recurrenceDays,
          if (scheduledTime != null) 'scheduledTime': scheduledTime,
          if (timezoneOffsetMinutes != null)
            'timezoneOffsetMinutes': timezoneOffsetMinutes,
          if (isScheduleEnabled != null) 'isScheduleEnabled': isScheduleEnabled,
        },
      );

      final dynamic responseBody = response.data;
      if (responseBody is! Map) return null;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      final dynamic data = body['data'];

      if (body['success'] != true || data is! Map) return null;

      return SceneModel.fromJson(Map<String, dynamic>.from(data));
    } catch (error) {
      debugPrint('[SceneService] Update scene error: $error');
      return null;
    }
  }

  /// 5. DELETE /api/v1/clients/{clientId}/scenes/{id}
  /// Permanently delete a scene (returns 204 or success: true).
  Future<bool> deleteScene(String clientId, String sceneId) async {
    if (!_isValidUuid(clientId) || !_isValidUuid(sceneId)) {
      debugPrint(
        '[SceneService] Invalid clientId or sceneId: $clientId, $sceneId',
      );
      return false;
    }
    try {
      final Response<dynamic> response = await _api.delete(
        ApiEndpoints.clientScene(clientId, sceneId),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }

      final dynamic responseBody = response.data;
      if (responseBody is! Map) return false;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      return body['success'] == true;
    } catch (error) {
      debugPrint('[SceneService] Delete scene error: $error');
      return false;
    }
  }

  /// 6. POST /api/v1/clients/{clientId}/scenes/{id}/activate
  /// Activate a scene — sends all of its device commands immediately.
  Future<bool> activateScene(String clientId, String sceneId) async {
    if (!_isValidUuid(clientId) || !_isValidUuid(sceneId)) {
      debugPrint(
        '[SceneService] Invalid clientId or sceneId: $clientId, $sceneId',
      );
      return false;
    }
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.activateClientScene(clientId, sceneId),
      );
      final dynamic responseBody = response.data;
      if (responseBody is! Map) return false;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      return body['success'] == true;
    } catch (error) {
      debugPrint('[SceneService] Activate scene error: $error');
      return false;
    }
  }

  /// 7. GET /api/v1/clients/{clientId}/scenes/{id}/status
  /// Phase 3 — Real-time sequential scene execution progress.
  /// Idle scenes return a deterministic 0/0 idle shape.
  Future<SceneExecutionStatus> getSceneStatus(
    String clientId,
    String sceneId,
  ) async {
    if (!_isValidUuid(clientId) || !_isValidUuid(sceneId)) {
      debugPrint(
        '[SceneService] Invalid clientId or sceneId: $clientId, $sceneId',
      );
      return SceneExecutionStatus.idle(sceneId: sceneId);
    }
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.clientSceneStatus(clientId, sceneId),
      );
      final dynamic responseBody = response.data;
      if (responseBody is! Map) {
        return SceneExecutionStatus.idle(sceneId: sceneId);
      }

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      if (body['success'] == true && body['data'] is Map) {
        return SceneExecutionStatus.fromJson(
          Map<String, dynamic>.from(body['data']),
        );
      }
      return SceneExecutionStatus.idle(sceneId: sceneId);
    } catch (error) {
      debugPrint('[SceneService] Get scene status error: $error');
      return SceneExecutionStatus.idle(sceneId: sceneId);
    }
  }
}
