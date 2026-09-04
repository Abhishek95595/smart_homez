import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/models/scene_model.dart';
import 'package:smart_homez/providers/scene_provider.dart';
import 'package:smart_homez/services/scene_service.dart';

class FakeSceneService implements SceneService {
  List<SceneModel> mockScenes = [];
  bool shouldFail = false;
  bool activateResult = true;

  @override
  Future<List<SceneModel>> getScenes(String clientId) async {
    if (shouldFail) throw Exception('Network error');
    return List.from(mockScenes);
  }

  @override
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
    if (shouldFail) return null;
    final created = SceneModel(
      id: 'scene_new_1',
      name: name,
      description: description,
      icon: icon,
      isFavorite: isFavorite,
      actions: actions,
      recurrenceDays: recurrenceDays,
      scheduledTime: scheduledTime,
      timezoneOffsetMinutes: timezoneOffsetMinutes,
      isScheduleEnabled: isScheduleEnabled,
    );
    mockScenes.insert(0, created);
    return created;
  }

  @override
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
    if (shouldFail) return null;
    final index = mockScenes.indexWhere((s) => s.id == sceneId);
    if (index == -1) return null;
    final old = mockScenes[index];
    final updated = SceneModel(
      id: old.id,
      tenantId: tenantId ?? old.tenantId,
      clientId: clientId,
      name: name ?? old.name,
      description: description ?? old.description,
      icon: icon ?? old.icon,
      isFavorite: isFavorite ?? old.isFavorite,
      actions: actions ?? old.actions,
      recurrenceDays: recurrenceDays ?? old.recurrenceDays,
      scheduledTime: scheduledTime ?? old.scheduledTime,
      timezoneOffsetMinutes: timezoneOffsetMinutes ?? old.timezoneOffsetMinutes,
      isScheduleEnabled: isScheduleEnabled ?? old.isScheduleEnabled,
    );
    mockScenes[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteScene(String clientId, String sceneId) async {
    if (shouldFail) return false;
    mockScenes.removeWhere((s) => s.id == sceneId);
    return true;
  }

  @override
  Future<bool> activateScene(String clientId, String sceneId) async {
    if (shouldFail) return false;
    return activateResult;
  }

  @override
  Future<SceneModel?> getScene(String clientId, String sceneId) async {
    return mockScenes.firstWhere((s) => s.id == sceneId);
  }

  @override
  Future<SceneExecutionStatus> getSceneStatus(
    String clientId,
    String sceneId,
  ) async {
    return SceneExecutionStatus.idle(sceneId: sceneId);
  }
}

void main() {
  group('SceneProvider Tests', () {
    late FakeSceneService fakeService;
    late SceneProvider provider;
    const testClientId = '6782976c-e9a4-41c9-a754-05e4ba0a97b2';

    setUp(() {
      fakeService = FakeSceneService();
      fakeService.mockScenes = [
        SceneModel(
          id: 'scene_1',
          name: 'Movie Night',
          icon: 'film',
          isFavorite: true,
          actions: [
            SceneActionModel(deviceId: 'dev_1', command: 'on'),
            SceneActionModel(
              deviceId: 'dev_2',
              command: 'brightness',
              commandValue: 20,
            ),
          ],
        ),
        SceneModel(
          id: 'scene_2',
          name: 'Good Morning',
          icon: 'sun',
          isFavorite: false,
          isScheduleEnabled: true,
          scheduledTime: '07:00',
          actions: [SceneActionModel(deviceId: 'dev_3', command: 'on')],
        ),
      ];
      provider = SceneProvider(sceneService: fakeService);
    });

    test(
      'fetchScenes with null clientId sets error state without network calls',
      () async {
        await provider.fetchScenes(null);
        expect(provider.scenes, isEmpty);
        expect(provider.state, equals(SceneProviderState.error));
        expect(
          provider.errorMessage,
          equals('Unable to determine the active client.'),
        );
      },
    );

    test('fetchScenes updates scenes list correctly', () async {
      expect(provider.scenes, isEmpty);
      await provider.fetchScenes(testClientId);
      expect(provider.scenes.length, equals(2));
      expect(provider.scenes[0].name, equals('Movie Night'));
      expect(provider.state, equals(SceneProviderState.loaded));
    });

    test('search filtering works properly', () async {
      await provider.fetchScenes(testClientId);
      expect(provider.filteredScenes.length, equals(2));

      provider.setSearchQuery('movie');
      expect(provider.filteredScenes.length, equals(1));
      expect(provider.filteredScenes.first.name, equals('Movie Night'));

      provider.setSearchQuery('NonExistent');
      expect(provider.filteredScenes, isEmpty);
    });

    test('quickScenes getter returns only isFavorite scenes', () async {
      await provider.fetchScenes(testClientId);
      expect(provider.quickScenes.length, equals(1));
      expect(provider.quickScenes.first.id, equals('scene_1'));
    });

    test('createScene adds scene to beginning of list', () async {
      await provider.fetchScenes(testClientId);
      final created = await provider.createScene(
        testClientId,
        name: 'Away Mode',
        icon: 'home',
        isFavorite: true,
        actions: [SceneActionModel(deviceId: 'dev_1', command: 'off')],
      );

      expect(created, isNotNull);
      expect(provider.scenes.length, equals(3));
      expect(provider.scenes.first.name, equals('Away Mode'));
    });

    test('updateScene updates scene state in place', () async {
      await provider.fetchScenes(testClientId);
      final updated = await provider.updateScene(
        testClientId,
        sceneId: 'scene_1',
        name: 'Cinema Night',
      );

      expect(updated, isNotNull);
      expect(provider.scenes.first.name, equals('Cinema Night'));
    });

    test(
      'toggleFavorite updates favorite state optimistic and backend',
      () async {
        await provider.fetchScenes(testClientId);
        final scene2 = provider.scenes[1];
        expect(scene2.isFavorite, isFalse);

        final success = await provider.toggleFavorite(testClientId, scene2);
        expect(success, isTrue);
        expect(provider.scenes[1].isFavorite, isTrue);
      },
    );

    test('deleteScene removes scene from list', () async {
      await provider.fetchScenes(testClientId);
      final success = await provider.deleteScene(testClientId, 'scene_1');
      expect(success, isTrue);
      expect(provider.scenes.length, equals(1));
      expect(provider.scenes.first.id, equals('scene_2'));
    });

    test('activateScene handles loading set and returns success', () async {
      await provider.fetchScenes(testClientId);
      expect(provider.isActivating('scene_1'), isFalse);

      final future = provider.activateScene(testClientId, 'scene_1');
      // While running
      expect(provider.isActivating('scene_1'), isTrue);

      final success = await future;
      expect(success, isTrue);
      expect(provider.isActivating('scene_1'), isFalse);
    });
  });
}
