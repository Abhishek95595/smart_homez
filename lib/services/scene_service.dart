import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/scene_model.dart';

class SceneService {
  SceneService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

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

  /// Get a single scene by its ID.
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

  /// Create a new scene with one or more device actions.
  Future<SceneModel?> createScene({
    required String name,
    required List<SceneActionModel> actions,
  }) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.scenes,
        data: {
          'name': name.trim(),
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

  /// Update an existing scene's name or device actions.
  Future<SceneModel?> updateScene({
    required String sceneId,
    String? name,
    List<SceneActionModel>? actions,
  }) async {
    try {
      final Response<dynamic> response = await _api.put(
        ApiEndpoints.scene(sceneId),
        data: {
          if (name != null) 'name': name.trim(),
          if (actions != null)
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
      debugPrint('[SceneService] Update scene error: $error');
      return null;
    }
  }

  /// Permanently delete a scene.
  Future<bool> deleteScene(String sceneId) async {
    try {
      final Response<dynamic> response = await _api.delete(
        ApiEndpoints.scene(sceneId),
      );
      final dynamic responseBody = response.data;
      if (responseBody is! Map) return false;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      return body['success'] == true;
    } catch (error) {
      debugPrint('[SceneService] Delete scene error: $error');
      return false;
    }
  }

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

  /// Real-time sequential scene execution progress.
  Future<Map<String, dynamic>?> getSceneStatus(String sceneId) async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.sceneStatus(sceneId),
      );
      final dynamic responseBody = response.data;
      if (responseBody is! Map) return null;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      if (body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data']);
      }
      return null;
    } catch (error) {
      debugPrint('[SceneService] Get scene status error: $error');
      return null;
    }
  }
}
