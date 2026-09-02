import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smart_homez/core/network/api_client.dart';
import 'package:smart_homez/models/scene_model.dart';
import 'package:smart_homez/services/scene_service.dart';

@GenerateNiceMocks([MockSpec<ApiClient>()])
import 'scene_service_test.mocks.dart';

void main() {
  late MockApiClient mockApi;
  late SceneService sceneService;

  setUp(() {
    mockApi = MockApiClient();
    sceneService = SceneService(apiClient: mockApi);
  });

  group('SceneService - Client-Scoped Scenes API Endpoints compliance', () {
    const String testClientId = '3fa85f64-5717-4562-b3fc-2c963f66afa6';
    const String testSceneId = 'fb8c6a16-33a4-4d7d-88be-a7fa6a8e5477';
    const String testIdleSceneId = 'ab8c6a16-33a4-4d7d-88be-a7fa6a8e5479';

    // 1. GET /api/v1/clients/{clientId}/scenes
    test(
      '1. GET /api/v1/clients/{clientId}/scenes: List all scenes for authenticated client',
      () async {
        when(mockApi.get('/api/v1/clients/$testClientId/scenes')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/api/v1/clients/$testClientId/scenes',
            ),
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'scenes': [
                  {
                    'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
                    'tenantId': 'tenant_01',
                    'clientId': testClientId,
                    'name': 'Movie Time',
                    'description': 'Dim living room lights and set AC',
                    'icon': 'movie',
                    'isFavorite': true,
                    'actions': [
                      {
                        'deviceId': 'dev_light_1',
                        'command': 'brightness',
                        'commandValue': '20',
                        'toggleOnActivate': false,
                        'sortOrder': 1,
                        'delaySeconds': 0,
                      },
                    ],
                  },
                ],
              },
            },
          ),
        );

        final scenes = await sceneService.getScenes(testClientId);

        expect(scenes.length, 1);
        final s = scenes.first;
        expect(s.id, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
        expect(s.name, 'Movie Time');
        expect(s.description, 'Dim living room lights and set AC');
        expect(s.isFavorite, true);
        expect(s.actions.length, 1);
        expect(s.actions.first.deviceId, 'dev_light_1');
        expect(s.actions.first.command, 'brightness');
        expect(s.actions.first.commandValue, '20');
        verify(mockApi.get('/api/v1/clients/$testClientId/scenes')).called(1);
      },
    );

    // 2. POST /api/v1/clients/{clientId}/scenes
    test(
      '2. POST /api/v1/clients/{clientId}/scenes: Create a new scene with device actions',
      () async {
        when(
          mockApi.post(
            '/api/v1/clients/$testClientId/scenes',
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/api/v1/clients/$testClientId/scenes',
            ),
            statusCode: 201,
            data: {
              'success': true,
              'data': {
                'id': 'scene_new_1',
                'tenantId': 'tenant_1',
                'clientId': testClientId,
                'name': 'Night Secure',
                'description': 'Turn off all exterior lights and lock doors',
                'icon': 'night',
                'isFavorite': true,
                'actions': [
                  {
                    'deviceId': 'dev_light_ext',
                    'command': 'off',
                    'commandValue': '0',
                    'toggleOnActivate': false,
                    'sortOrder': 1,
                    'delaySeconds': 0,
                  },
                ],
              },
            },
          ),
        );

        final created = await sceneService.createScene(
          testClientId,
          tenantId: 'tenant_1',
          name: 'Night Secure',
          description: 'Turn off all exterior lights and lock doors',
          icon: 'night',
          isFavorite: true,
          actions: [
            SceneActionModel(
              deviceId: 'dev_light_ext',
              command: 'off',
              commandValue: null,
              sortOrder: 1,
            ),
          ],
        );

        expect(created, isNotNull);
        expect(created!.name, 'Night Secure');
        expect(created.isFavorite, true);
        expect(created.actions.first.deviceId, 'dev_light_ext');
        verify(
          mockApi.post(
            '/api/v1/clients/$testClientId/scenes',
            data: {
              'clientId': testClientId,
              'name': 'Night Secure',
              'description': 'Turn off all exterior lights and lock doors',
              'icon': 'night',
              'isFavorite': true,
              'actions': [
                {
                  'deviceId': 'dev_light_ext',
                  'command': 'off',
                  'commandValue': null,
                  'toggleOnActivate': false,
                  'sortOrder': 1,
                  'delaySeconds': 0,
                },
              ],
              'recurrenceDays': 0,
              'scheduledTime': null,
              'timezoneOffsetMinutes': 330,
              'isScheduleEnabled': false,
            },
          ),
        ).called(1);
      },
    );

    // 3. GET /api/v1/clients/{clientId}/scenes/{id}
    test(
      '3. GET /api/v1/clients/{clientId}/scenes/{id}: Get a single scene by its ID',
      () async {
        when(
          mockApi.get('/api/v1/clients/$testClientId/scenes/$testSceneId'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/api/v1/clients/$testClientId/scenes/$testSceneId',
            ),
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'id': testSceneId,
                'name': 'Morning Boost',
                'actions': [
                  {
                    'deviceId': 'dev_coffee',
                    'command': 'brew',
                    'commandValue': 'espresso',
                  },
                ],
              },
            },
          ),
        );

        final scene = await sceneService.getScene(testClientId, testSceneId);

        expect(scene, isNotNull);
        expect(scene!.id, testSceneId);
        expect(scene.name, 'Morning Boost');
        expect(scene.actions.first.command, 'brew');
        verify(
          mockApi.get('/api/v1/clients/$testClientId/scenes/$testSceneId'),
        ).called(1);
      },
    );

    // 4. PUT /api/v1/clients/{clientId}/scenes/{id}
    test(
      '4. PUT /api/v1/clients/{clientId}/scenes/{id}: Update a scene name or device actions',
      () async {
        when(
          mockApi.put(
            '/api/v1/clients/$testClientId/scenes/$testSceneId',
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/api/v1/clients/$testClientId/scenes/$testSceneId',
            ),
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'id': testSceneId,
                'name': 'Updated Morning Boost',
                'isFavorite': true,
                'actions': [
                  {
                    'deviceId': 'dev_coffee',
                    'command': 'brew',
                    'commandValue': 'double_shot',
                    'sortOrder': 1,
                  },
                ],
              },
            },
          ),
        );

        final updated = await sceneService.updateScene(
          testClientId,
          sceneId: testSceneId,
          name: 'Updated Morning Boost',
          isFavorite: true,
          actions: [
            SceneActionModel(
              deviceId: 'dev_coffee',
              command: 'brew',
              commandValue: 'double_shot',
              sortOrder: 1,
            ),
          ],
        );

        expect(updated, isNotNull);
        expect(updated!.name, 'Updated Morning Boost');
        expect(updated.isFavorite, true);
        verify(
          mockApi.put(
            '/api/v1/clients/$testClientId/scenes/$testSceneId',
            data: argThat(isA<Map>(), named: 'data'),
          ),
        ).called(1);
      },
    );

    // 5. DELETE /api/v1/clients/{clientId}/scenes/{id} (204 No Content)
    test(
      '5. DELETE /api/v1/clients/{clientId}/scenes/{id}: Permanently delete a scene (204 Deleted)',
      () async {
        when(
          mockApi.delete('/api/v1/clients/$testClientId/scenes/$testSceneId'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/api/v1/clients/$testClientId/scenes/$testSceneId',
            ),
            statusCode: 204,
          ),
        );

        final success = await sceneService.deleteScene(
          testClientId,
          testSceneId,
        );

        expect(success, isTrue);
        verify(
          mockApi.delete('/api/v1/clients/$testClientId/scenes/$testSceneId'),
        ).called(1);
      },
    );

    // 6. POST /api/v1/clients/{clientId}/scenes/{id}/activate
    test(
      '6. POST /api/v1/clients/{clientId}/scenes/{id}/activate: Activate a scene immediately',
      () async {
        when(
          mockApi.post(
            '/api/v1/clients/$testClientId/scenes/$testSceneId/activate',
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path:
                  '/api/v1/clients/$testClientId/scenes/$testSceneId/activate',
            ),
            statusCode: 200,
            data: {'success': true, 'message': 'Scene activated'},
          ),
        );

        final success = await sceneService.activateScene(
          testClientId,
          testSceneId,
        );

        expect(success, isTrue);
        verify(
          mockApi.post(
            '/api/v1/clients/$testClientId/scenes/$testSceneId/activate',
          ),
        ).called(1);
      },
    );

    // 7. GET /api/v1/clients/{clientId}/scenes/{id}/status
    test(
      '7. GET /api/v1/clients/{clientId}/scenes/{id}/status: Phase 3 sequential scene execution progress & deterministic idle shape',
      () async {
        // Active execution status
        when(
          mockApi.get(
            '/api/v1/clients/$testClientId/scenes/$testSceneId/status',
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/api/v1/clients/$testClientId/scenes/$testSceneId/status',
            ),
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'scene_id': testSceneId,
                'status': 'executing',
                'current_step': 3,
                'total_steps': 5,
                'percentage': 60.0,
              },
            },
          ),
        );

        final active = await sceneService.getSceneStatus(
          testClientId,
          testSceneId,
        );
        expect(active.isIdle, isFalse);
        expect(active.currentStep, 3);
        expect(active.totalSteps, 5);
        expect(active.percentage, 60.0);
        expect(active.status, 'executing');

        // Idle shape
        when(
          mockApi.get(
            '/api/v1/clients/$testClientId/scenes/$testIdleSceneId/status',
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path:
                  '/api/v1/clients/$testClientId/scenes/$testIdleSceneId/status',
            ),
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'scene_id': testIdleSceneId,
                'status': 'idle',
                'current_step': 0,
                'total_steps': 0,
                'percentage': 0.0,
              },
            },
          ),
        );

        final idle = await sceneService.getSceneStatus(
          testClientId,
          testIdleSceneId,
        );
        expect(idle.isIdle, isTrue);
        expect(idle.currentStep, 0);
        expect(idle.totalSteps, 0);
        expect(idle.percentage, 0.0);
      },
    );
  });
}
