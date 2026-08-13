import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:smart_homez/data/repositories/tenant_api_repository.dart';
import 'package:smart_homez/services/api_service.dart';
import 'package:smart_homez/data/models/requests/create_automation_request.dart';
import 'package:smart_homez/models/automation_model.dart';

@GenerateNiceMocks([MockSpec<ApiService>(), MockSpec<Response>()])
import 'tenant_api_repository_test.mocks.dart';

void main() {
  late TenantApiRepository repository;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    repository = TenantApiRepository(apiService: mockApiService);
  });

  group('TenantApiRepository - Automations', () {
    test('getAutomation calls correct endpoint and parses response', () async {
      final mockData = {
        'success': true,
        'data': {
          'id': 'auto-123',
          'name': 'Morning Lights',
          'isActive': true,
          'conditions': [
            {'conditionType': 'Time', 'timeValue': '08:00'},
          ],
          'actions': [
            {'actionType': 'Command', 'command': 'on'},
          ],
        },
      };

      final mockResponse = MockResponse<dynamic>();
      when(mockResponse.data).thenReturn(mockData);
      when(mockApiService.get(any)).thenAnswer((_) async => mockResponse);

      final result = await repository.getAutomation('auto-123');

      expect(result.id, 'auto-123');
      expect(result.name, 'Morning Lights');
      expect(result.isActive, true);
      expect(result.conditions.length, 1);
      verify(mockApiService.get('/api/v1/automations/auto-123')).called(1);
    });

    test('createAutomation sends correct JSON body and omits nulls', () async {
      final request = CreateAutomationRequest(
        name: 'Night Mode',
        isActive: true,
        description: null,
        conditions: [
          const CreateAutomationConditionRequest(
            conditionType: 'Time',
            timeValue: '22:00',
          ),
        ],
        actions: [
          const CreateAutomationActionRequest(
            actionType: 'Command',
            command: 'off',
          ),
        ],
      );

      final mockData = {
        'success': true,
        'data': {'id': 'new-id', 'name': 'Night Mode', 'isActive': true},
      };

      final mockResponse = MockResponse<dynamic>();
      when(mockResponse.data).thenReturn(mockData);
      when(
        mockApiService.post(any, body: anyNamed('body')),
      ).thenAnswer((_) async => mockResponse);

      final result = await repository.createAutomation(request);

      expect(result.id, 'new-id');
      verify(
        mockApiService.post(
          '/api/v1/automations',
          body: argThat(
            predicate((Object? body) {
              if (body is! Map) return false;
              return body['name'] == 'Night Mode' &&
                  body['isActive'] == true &&
                  !body.containsKey('description') &&
                  (body['conditions'] as List)[0]['timeValue'] == '22:00';
            }),
            named: 'body',
          ),
        ),
      ).called(1);
    });

    test('toggleAutomation propagates API failure', () async {
      final mockResponse = MockResponse<dynamic>();
      when(mockResponse.data).thenReturn({
        'success': false,
        'error': {'message': 'Toggle failed'},
      });
      when(
        mockApiService.post(any, body: anyNamed('body')),
      ).thenAnswer((_) async => mockResponse);

      expect(
        () => repository.toggleAutomation(automationId: 'id', isActive: true),
        throwsA(predicate((e) => e.toString().contains('Toggle failed'))),
      );
    });

    test('AutomationModel handles non-list conditions and actions', () {
      final model = AutomationModel.fromJson({
        'id': '1',
        'name': 'Test',
        'conditions': 'invalid',
        'actions': {'invalid': true},
      });

      expect(model.conditions, isEmpty);
      expect(model.actions, isEmpty);
    });

    test('AutomationModel handles malformed numeric values', () {
      final model = AutomationModel.fromJson({
        'id': '1',
        'name': 'Test',
        'isActive': true,
        'conditions': [
          {'sortOrder': 'abc', 'offsetMinutes': '15'},
        ],
      });

      expect(model.conditions[0].sortOrder, 0);
      expect(model.conditions[0].offsetMinutes, 15);
    });

    test('getAutomations collection endpoint', () async {
      final mockData = {
        'success': true,
        'data': [
          {'id': '1', 'name': 'A1', 'isActive': true},
          {'id': '2', 'name': 'A2', 'isActive': false},
        ],
      };
      final mockResponse = MockResponse<dynamic>();
      when(mockResponse.data).thenReturn(mockData);
      when(
        mockApiService.get('/api/v1/automations'),
      ).thenAnswer((_) async => mockResponse);

      final results = await repository.getAutomations();

      expect(results.length, 2);
      expect(results[0].name, 'A1');
    });

    test('updateAutomation sends PUT with correct body', () async {
      final request = CreateAutomationRequest(
        name: 'Updated Name',
        isActive: false,
      );
      final mockResponse = MockResponse<dynamic>();
      when(mockResponse.data).thenReturn({
        'success': true,
        'data': {'id': 'id-1', 'name': 'Updated Name', 'isActive': false},
      });
      when(
        mockApiService.put(any, body: anyNamed('body')),
      ).thenAnswer((_) async => mockResponse);

      await repository.updateAutomation(automationId: 'id-1', request: request);

      verify(
        mockApiService.put(
          '/api/v1/automations/id-1',
          body: argThat(
            predicate((Object? body) {
              if (body is! Map) return false;
              return body['name'] == 'Updated Name' &&
                  body['isActive'] == false;
            }),
            named: 'body',
          ),
        ),
      ).called(1);
    });

    test('throws Exception with API error message on failure', () async {
      final mockResponse = MockResponse<dynamic>();
      when(mockResponse.data).thenReturn({
        'success': false,
        'error': {'message': 'Custom API Error'},
      });
      when(mockApiService.get(any)).thenAnswer((_) async => mockResponse);

      expect(
        () => repository.getAutomation('fail-id'),
        throwsA(
          predicate(
            (e) => e is Exception && e.toString().contains('Custom API Error'),
          ),
        ),
      );
    });
  });
}
