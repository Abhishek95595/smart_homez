import 'package:flutter/foundation.dart';
import '../models/scene_model.dart';
import '../services/scene_service.dart';

enum SceneProviderState { initial, loading, loaded, saving, error }

class SceneProvider extends ChangeNotifier {
  SceneProvider({SceneService? sceneService})
    : _service = sceneService ?? SceneService();

  final SceneService _service;

  List<SceneModel> _scenes = [];
  SceneProviderState _state = SceneProviderState.initial;
  String? _errorMessage;
  String _searchQuery = '';
  String? _lastLoadedClientId;
  final Set<String> _activatingSceneIds = {};

  // Getters
  List<SceneModel> get scenes => List.unmodifiable(_scenes);
  SceneProviderState get state => _state;
  bool get isLoading => _state == SceneProviderState.loading;
  bool get isSaving => _state == SceneProviderState.saving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get lastLoadedClientId => _lastLoadedClientId;
  Set<String> get activatingSceneIds => Set.unmodifiable(_activatingSceneIds);

  bool isActivating(String sceneId) => _activatingSceneIds.contains(sceneId);

  List<SceneModel> get filteredScenes {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _scenes;
    return _scenes.where((s) => s.name.toLowerCase().contains(query)).toList();
  }

  List<SceneModel> get quickScenes {
    return _scenes.where((s) => s.isFavorite).toList();
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetState() {
    _scenes = [];
    _state = SceneProviderState.initial;
    _errorMessage = null;
    _lastLoadedClientId = null;
    _activatingSceneIds.clear();
    notifyListeners();
  }

  // ── 1. Fetch Scenes ──
  Future<void> fetchScenes(String? clientId) async {
    if (clientId == null || clientId.trim().isEmpty) {
      _scenes = [];
      _errorMessage = 'Unable to determine the active client.';
      _state = SceneProviderState.error;
      _lastLoadedClientId = null;
      notifyListeners();
      return;
    }

    final trimmedId = clientId.trim();
    if (_lastLoadedClientId != trimmedId) {
      _scenes = []; // Clear previous client scenes to avoid stale data display
    }

    _state = SceneProviderState.loading;
    _errorMessage = null;
    _lastLoadedClientId = trimmedId;
    notifyListeners();

    try {
      final result = await _service.getScenes(trimmedId);
      _scenes = result;
      _state = SceneProviderState.loaded;
    } catch (e) {
      _errorMessage = 'Failed to load scenes: $e';
      _state = SceneProviderState.error;
    } finally {
      notifyListeners();
    }
  }

  // ── 2. Create Scene ──
  Future<SceneModel?> createScene(
    String? clientId, {
    String? tenantId,
    required String name,
    String? description,
    String? icon,
    bool isFavorite = false,
    required List<SceneActionModel> actions,
    int recurrenceDays = 0,
    String? scheduledTime,
    int? timezoneOffsetMinutes,
    bool isScheduleEnabled = false,
  }) async {
    if (clientId == null || clientId.trim().isEmpty) {
      _errorMessage = 'Unable to determine the active client.';
      _state = SceneProviderState.error;
      notifyListeners();
      return null;
    }

    final trimmedId = clientId.trim();
    _state = SceneProviderState.saving;
    _errorMessage = null;
    notifyListeners();

    final tzOffset =
        timezoneOffsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes;

    try {
      final newScene = await _service.createScene(
        trimmedId,
        tenantId: tenantId,
        name: name,
        description: description,
        icon: icon,
        isFavorite: isFavorite,
        actions: actions,
        recurrenceDays: recurrenceDays,
        scheduledTime: scheduledTime,
        timezoneOffsetMinutes: tzOffset,
        isScheduleEnabled: isScheduleEnabled,
      );

      if (newScene != null) {
        _scenes.insert(0, newScene);
        _state = SceneProviderState.loaded;
        notifyListeners();
        return newScene;
      } else {
        _errorMessage = 'Failed to create scene.';
        _state = SceneProviderState.error;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error creating scene: $e';
      _state = SceneProviderState.error;
      notifyListeners();
      return null;
    }
  }

  // ── 3. Update Scene ──
  Future<SceneModel?> updateScene(
    String? clientId, {
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
  }) async {
    if (clientId == null || clientId.trim().isEmpty) {
      _errorMessage = 'Unable to determine the active client.';
      _state = SceneProviderState.error;
      notifyListeners();
      return null;
    }

    final trimmedId = clientId.trim();
    _state = SceneProviderState.saving;
    _errorMessage = null;
    notifyListeners();

    final tzOffset =
        timezoneOffsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes;

    try {
      final updated = await _service.updateScene(
        trimmedId,
        sceneId: sceneId,
        tenantId: tenantId,
        name: name,
        description: description,
        icon: icon,
        isFavorite: isFavorite,
        actions: actions,
        recurrenceDays: recurrenceDays,
        scheduledTime: scheduledTime,
        timezoneOffsetMinutes: tzOffset,
        isScheduleEnabled: isScheduleEnabled,
      );

      if (updated != null) {
        final index = _scenes.indexWhere((s) => s.id == sceneId);
        if (index != -1) {
          _scenes[index] = updated;
        }
        _state = SceneProviderState.loaded;
        notifyListeners();
        return updated;
      } else {
        _errorMessage = 'Failed to update scene.';
        _state = SceneProviderState.error;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error updating scene: $e';
      _state = SceneProviderState.error;
      notifyListeners();
      return null;
    }
  }

  // ── 4. Toggle Favorite ──
  Future<bool> toggleFavorite(String? clientId, SceneModel scene) async {
    if (clientId == null || clientId.trim().isEmpty) {
      _errorMessage = 'Unable to determine the active client.';
      notifyListeners();
      return false;
    }

    final trimmedId = clientId.trim();
    final newFav = !scene.isFavorite;
    _errorMessage = null;

    // Optimistic update
    final index = _scenes.indexWhere((s) => s.id == scene.id);
    if (index != -1) {
      _scenes[index] = SceneModel(
        id: scene.id,
        tenantId: scene.tenantId,
        clientId: scene.clientId,
        name: scene.name,
        description: scene.description,
        icon: scene.icon,
        isFavorite: newFav,
        actions: scene.actions,
        recurrenceDays: scene.recurrenceDays,
        scheduledTime: scene.scheduledTime,
        timezoneOffsetMinutes: scene.timezoneOffsetMinutes,
        isScheduleEnabled: scene.isScheduleEnabled,
      );
      notifyListeners();
    }

    final result = await _service.updateScene(
      trimmedId,
      sceneId: scene.id,
      isFavorite: newFav,
    );

    if (result == null && index != -1) {
      // Rollback on failure
      _scenes[index] = scene;
      _errorMessage = 'Failed to update Quick Scene status.';
      notifyListeners();
      return false;
    }
    return true;
  }

  // ── 5. Delete Scene ──
  Future<bool> deleteScene(String? clientId, String sceneId) async {
    if (clientId == null || clientId.trim().isEmpty) {
      _errorMessage = 'Unable to determine the active client.';
      notifyListeners();
      return false;
    }

    final trimmedId = clientId.trim();
    _errorMessage = null;
    final success = await _service.deleteScene(trimmedId, sceneId);
    if (success) {
      _scenes.removeWhere((s) => s.id == sceneId);
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Failed to delete scene.';
      notifyListeners();
      return false;
    }
  }

  // ── 6. Activate Scene ──
  Future<bool> activateScene(String? clientId, String sceneId) async {
    if (clientId == null || clientId.trim().isEmpty) {
      _errorMessage = 'Unable to determine the active client.';
      notifyListeners();
      return false;
    }

    if (_activatingSceneIds.contains(sceneId)) return false;

    final trimmedId = clientId.trim();
    _activatingSceneIds.add(sceneId);
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.activateScene(trimmedId, sceneId);
      if (!success) {
        _errorMessage = 'Activation failed for scene.';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Activation failed: $e';
      return false;
    } finally {
      _activatingSceneIds.remove(sceneId);
      notifyListeners();
    }
  }
}
