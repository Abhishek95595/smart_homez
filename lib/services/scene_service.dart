import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/scene_model.dart';

class SceneService {
  SceneService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// 1. GET /api/v1/scenes
  /// List all scenes for the authenticated client.
  Future<List<SceneModel>> getScenes() async {
    try {
      final Response<dynamic> response = await _api.get(ApiEndpoints.scenes);
      final dynamic responseBody = response.data;
      if (responseBody is! Map) return const [];

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      final dynamic data = body['data'];

      if (body['success'] != true || data is! List) {
        return const [];
      }

      return data
          .whereType<Map>()
          .map((item) => SceneModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (error) {
      debugPrint('[SceneService] Get scenes error: $error');
      return const [];
    }
  }

  /// 2. POST /api/v1/scenes
  /// Create a new scene for the authenticated client with one or more device actions.
  Future<SceneModel?> createScene({
    String? tenantId,
    String? clientId,
    required String name,
    String? description,
    String? icon,
    bool isFavorite = false,
    required List<SceneActionModel> actions,
  }) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.scenes,
        data: {
          'tenantId': ?tenantId,
          'clientId': ?clientId,
          'name': name.trim(),
          'description': ?description?.trim(),
          'icon': ?icon,
          'isFavorite': isFavorite,
          'actions': actions.map((a) => a.toJson()).toList(),
        },
      );

      final dynamic responseBody = response.data;
      if (responseBody is! Map) return null;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      final dynamic data = body['data'];

      if (body['success'] != true || data is! Map) return null;

      return SceneModel.fromJson(Map<String, dynamic>.from(data));
    } catch (error) {
      debugPrint('[SceneService] Create scene error: $error');
      return null;
    }
  }

  /// 3. GET /api/v1/scenes/{id}
  /// Get a single scene by its ID, including its device actions.
  Future<SceneModel?> getScene(String sceneId) async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.scene(sceneId),
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

  /// 4. PUT /api/v1/scenes/{id}
  /// Update a scene's name, description, icon, isFavorite, or its device actions.
  Future<SceneModel?> updateScene({
    required String sceneId,
    String? tenantId,
    String? clientId,
    String? name,
    String? description,
    String? icon,
    bool? isFavorite,
    List<SceneActionModel>? actions,
  }) async {
    try {
      final Response<dynamic> response = await _api.put(
        ApiEndpoints.scene(sceneId),
        data: {
          'tenantId': ?tenantId,
          'clientId': ?clientId,
          'name': ?name?.trim(),
          'description': ?description?.trim(),
          'icon': ?icon,
          'isFavorite': ?isFavorite,
          'actions': ?actions?.map((a) => a.toJson()).toList(),
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

  /// 5. DELETE /api/v1/scenes/{id}
  /// Permanently delete a scene (returns 204 or success: true).
  Future<bool> deleteScene(String sceneId) async {
    try {
      final Response<dynamic> response = await _api.delete(
        ApiEndpoints.scene(sceneId),
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

  /// 6. POST /api/v1/scenes/{id}/activate
  /// Activate a scene — sends all of its device commands immediately.
  Future<bool> activateScene(String sceneId) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.activateScene(sceneId),
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

  /// 7. GET /api/v1/scenes/{id}/status
  /// Phase 3 — Real-time sequential scene execution progress.
  /// Idle scenes return a deterministic 0/0 idle shape.
  Future<SceneExecutionStatus> getSceneStatus(String sceneId) async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.sceneStatus(sceneId),
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
