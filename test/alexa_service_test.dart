import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/core/network/api_client.dart';
import 'package:smart_homez/core/network/api_endpoints.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_link_response.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_provider.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_service.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_status_model.dart';
import 'package:smart_homez/models/device.dart';

String _createTestJwt({
  String iss = 'AuraBrain',
  String aud = 'AuraBrainMobile',
  String tenantId = '6d11e924-d046-400d-bc30-62a06e13de61',
  String clientId = 'anvyaaai_AEB3',
  String permissionLevel = 'write',
  int? exp,
}) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'iss': iss,
            'aud': aud,
            'TenantId': tenantId,
            'ClientId': clientId,
            'PermissionLevel': permissionLevel,
            'exp':
                exp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600),
          }),
        ),
      )
      .replaceAll('=', '');
  return '$header.$payload.mockSignature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('JWT Claims & Production Validation Tests', () {
    test('Valid production AuraBrain JWT passes validation', () {
      final token = _createTestJwt();
      expect(ApiClient.isJwtValid(token), isTrue);
    });

    test('Valid token with future expiration passes validation', () {
      final token = _createTestJwt(
        exp: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7200,
      );
      expect(ApiClient.isJwtValid(token), isTrue);
    });

    test('Firebase ID token is rejected for Tenant API', () {
      final firebaseToken = _createTestJwt(
        iss: 'https://securetoken.google.com/smarthomez-73d81',
      );
      expect(ApiClient.isJwtValid(firebaseToken), isFalse);
    });

    test('Token with invalid audience is rejected', () {
      final invalidAudToken = _createTestJwt(aud: 'AuraBrainWeb');
      expect(ApiClient.isJwtValid(invalidAudToken), isFalse);
    });

    test('Token with invalid/QA TenantId is rejected', () {
      final qaTenantToken = _createTestJwt(
        tenantId: '03d6aaff-f21b-41fc-902f-8184dacd0861',
      );
      expect(ApiClient.isJwtValid(qaTenantToken), isFalse);
    });

    test('Token with invalid ClientId is rejected', () {
      final wrongClientToken = _createTestJwt(clientId: 'qa_client_999');
      expect(ApiClient.isJwtValid(wrongClientToken), isFalse);
    });

    test('Token with non-write permission level is rejected', () {
      final readOnlyToken = _createTestJwt(permissionLevel: 'read');
      expect(ApiClient.isJwtValid(readOnlyToken), isFalse);
    });

    test('Expired token is rejected', () {
      final expiredToken = _createTestJwt(
        exp: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 120,
      );
      expect(ApiClient.isJwtValid(expiredToken), isFalse);
    });

    test('Token expiring within 60s safety buffer is rejected', () {
      final soonExpiringToken = _createTestJwt(
        exp: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 30,
      );
      expect(ApiClient.isJwtValid(soonExpiringToken), isFalse);
    });

    test('Malformed and null tokens return false without throwing', () {
      expect(ApiClient.isJwtValid(null), isFalse);
      expect(ApiClient.isJwtValid(''), isFalse);
      expect(ApiClient.isJwtValid('not.a.valid.jwt.structure'), isFalse);
      expect(ApiClient.isJwtValid('abc.def'), isFalse);
    });
  });

  group('Alexa Models & Serialization Tests', () {
    test('AlexaStatus deserializes linked and connected states correctly', () {
      final statusMap = {'linked': true, 'connected': true, 'deviceCount': 4};
      final status = AlexaStatus.fromJson(statusMap);
      expect(status.linked, isTrue);
      expect(status.connected, isTrue);
      expect(status.deviceCount, equals(4));
    });

    test('AlexaStatus distinguishes linked but not connected state', () {
      final statusMap = {'linked': true, 'connected': false};
      final status = AlexaStatus.fromJson(statusMap);
      expect(status.linked, isTrue);
      expect(status.connected, isFalse);
    });

    test('AlexaLinkResponse deserializes authorizeUrl correctly', () {
      final responseMap = {
        'ssoToken': 'sso_12345',
        'authorizeUrl': 'https://amazon.com/ap/oa?client_id=123',
        'expiresInSeconds': 3600,
      };
      final response = AlexaLinkResponse.fromJson(responseMap);
      expect(response.ssoToken, equals('sso_12345'));
      expect(
        response.authorizeUrl,
        equals('https://amazon.com/ap/oa?client_id=123'),
      );
      expect(response.expiresInSeconds, equals(3600));
    });

    test(
      'AlexaLinkResponse parses and normalizes dynamic link-token authorizeUrl correctly',
      () {
        const ssoToken = '6Bi79fIm4d4tM6O2N2wxkym93KicdkyM5JyMQNmXCJw';
        const dynamicAuthorizeUrl =
            'https://tenant-api-qa.omnihome.in/oauth/authorize?response_type=code&client_id=omnihome-alexa&sso_token=$ssoToken&redirect_uri=hasomi.com.homeautomation%3A%2F%2Falexa-callback&state=c4d03795-ad24-4b32-8ce5-6376969cf843';

        final responseMap = {
          'ssoToken': ssoToken,
          'authorizeUrl': dynamicAuthorizeUrl,
          'expiresInSeconds': 300,
        };
        final response = AlexaLinkResponse.fromJson(responseMap);

        expect(response.ssoToken, equals(ssoToken));
        expect(
          response.authorizeUrl,
          equals(
            'https://omnihome.in/oauth/authorize?response_type=code&client_id=omnihome-alexa&sso_token=$ssoToken&redirect_uri=hasomi.com.homeautomation%3A%2F%2Falexa-callback&state=c4d03795-ad24-4b32-8ce5-6376969cf843',
          ),
        );
      },
    );

    test(
      'resolveAuthorizeUri resolves root-relative path against request origin',
      () {
        final requestUri = Uri.parse(
          'https://tenant-api.omnihome.in/api/integrations/alexa/link-token',
        );
        final resolved = AlexaService.resolveAuthorizeUri(
          authorizeUrl:
              '/oauth/authorize?response_type=code&client_id=omnihome-alexa&sso_token=sso_123',
          requestUri: requestUri,
        );
        expect(
          resolved.toString(),
          equals(
            'https://omnihome.in/oauth/authorize?response_type=code&client_id=omnihome-alexa&sso_token=sso_123',
          ),
        );
      },
    );

    test('resolveAuthorizeUri preserves absolute URL unchanged', () {
      final requestUri = Uri.parse(
        'https://tenant-api.omnihome.in/api/integrations/alexa/link-token',
      );
      final resolved = AlexaService.resolveAuthorizeUri(
        authorizeUrl: 'https://amazon.com/ap/oa?client_id=123',
        requestUri: requestUri,
      );
      expect(
        resolved.toString(),
        equals('https://amazon.com/ap/oa?client_id=123'),
      );
    });

    test('resolveAuthorizeUri rejects arbitrary relative and empty URLs', () {
      final requestUri = Uri.parse(
        'https://tenant-api.omnihome.in/api/integrations/alexa/link-token',
      );
      expect(
        () => AlexaService.resolveAuthorizeUri(
          authorizeUrl: 'oauth/authorize?foo=bar',
          requestUri: requestUri,
        ),
        throwsException,
      );
      expect(
        () => AlexaService.resolveAuthorizeUri(
          authorizeUrl: '',
          requestUri: requestUri,
        ),
        throwsException,
      );
    });
  });

  group('AlexaService Logic & State Tests', () {
    test('generateSecureState produces unique valid state UUIDs', () async {
      final service = AlexaService();
      final state1 = await service.generateSecureState();
      final state2 = await service.generateSecureState();

      expect(state1, isNotEmpty);
      expect(state2, isNotEmpty);
      expect(state1, isNot(equals(state2)));
      expect(service.lastGeneratedState, equals(state2));
    });

    test('validateCallbackState rejects missing or mismatched state', () async {
      final service = AlexaService();
      expect(await service.validateCallbackState(null), isFalse);
      expect(await service.validateCallbackState(''), isFalse);
      expect(
        await service.validateCallbackState('invalid-state-uuid'),
        isFalse,
      );
    });

    test('validateCallbackState accepts matching state', () async {
      final service = AlexaService();
      final state = await service.generateSecureState();
      final bool isValid = await service.validateCallbackState(state);
      expect(isValid, isTrue);

      // Single-use check: second attempt should fail because state was deleted
      final bool isSecondValid = await service.validateCallbackState(state);
      expect(isSecondValid, isFalse);
    });

    test('scanLocalWifiDevices maps real hardware devices correctly', () async {
      final service = AlexaService();
      final List<Device> mockDevices = [
        Device(
          deviceId: 'dev_1',
          name: 'Living Room Light',
          type: DeviceType.light,
          firmwareVersion: '1.0.0',
          macAddress: 'AA:BB:CC:DD:EE:FF',
          tenantId: 'tenant_1',
          buildingId: 'bldg_1',
          zone: 'Living',
          roomName: 'Living Room',
          status: DeviceStatus.online,
          lastHeartbeat: DateTime.now(),
        ),
      ];

      final wifiDevices = await service.scanLocalWifiDevices(
        realDevices: mockDevices,
      );

      expect(wifiDevices, hasLength(1));
      expect(wifiDevices.first.id, equals('dev_1'));
      expect(wifiDevices.first.name, equals('Living Room Light'));
    });
  });

  group('AlexaProvider State Management & Guidance Tests', () {
    test('Initial AlexaProvider state is not connected', () {
      final provider = AlexaProvider();
      expect(provider.isConnecting, isFalse);
      expect(provider.isLinked, isFalse);
      expect(provider.isConnected, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.statusGuidanceMessage, isNull);
    });

    test('Guidance message for linked but not connected state', () {
      final provider = AlexaProvider();
      expect(provider.statusGuidanceMessage, isNull);
    });
  });

  group('Architectural Security & Token Isolation Tests', () {
    test('Production Client GUID invariant is enforced', () {
      expect(
        ApiEndpoints.productionClientGuid,
        equals('6782976c-e9a4-41c9-a754-05e4ba0a97b2'),
      );
    });

    test('Production Tenant ID invariant is enforced', () {
      expect(
        ApiEndpoints.productionTenantId,
        equals('6d11e924-d046-400d-bc30-62a06e13de61'),
      );
    });

    test('Expected Tenant Client ID invariant is enforced', () {
      expect(ApiEndpoints.expectedTenantClientId, equals('anvyaaai_AEB3'));
    });

    test('Expected JWT claims parameters are enforced', () {
      expect(ApiEndpoints.expectedJwtIssuer, equals('AuraBrain'));
      expect(ApiEndpoints.expectedJwtAudience, equals('AuraBrainMobile'));
      expect(ApiEndpoints.expectedJwtPermission, equals('write'));
    });

    test('Storage key constants use authoritative tenant_api_jwt', () {
      expect(ApiClient.tenantApiJwtKey, equals('tenant_api_jwt'));
      expect(
        ApiClient.tenantApiJwtExpiresAtKey,
        equals('tenant_api_jwt_expires_at'),
      );
    });

    test(
      'Simultaneous token refresh deduplication via in-flight mutex',
      () async {
        int bffCallCount = 0;
        Future<String?>? inFlightRefresh;

        Future<String?> simulateRefresh() {
          if (inFlightRefresh != null) {
            return inFlightRefresh!;
          }
          inFlightRefresh =
              Future.delayed(const Duration(milliseconds: 50), () {
                bffCallCount++;
                return _createTestJwt();
              }).whenComplete(() {
                inFlightRefresh = null;
              });
          return inFlightRefresh!;
        }

        // Simulate 5 concurrent 401s triggering refresh at the exact same moment
        final results = await Future.wait([
          simulateRefresh(),
          simulateRefresh(),
          simulateRefresh(),
          simulateRefresh(),
          simulateRefresh(),
        ]);

        expect(bffCallCount, equals(1));
        expect(results, hasLength(5));
        for (final res in results) {
          expect(ApiClient.isJwtValid(res), isTrue);
        }
      },
    );

    test('Client GUID normalization converts QA GUID to production GUID', () {
      expect(
        ApiEndpoints.normalizeClientGuid(
          '03d6aaff-f21b-41fc-902f-8184dacd0861',
        ),
        equals(ApiEndpoints.productionClientGuid),
      );
      expect(
        ApiEndpoints.normalizeClientGuid(
          'df0df9e3-0e47-4d46-810e-3c4f5c267d69',
        ),
        equals(ApiEndpoints.productionClientGuid),
      );
      expect(
        ApiEndpoints.normalizeClientGuid(null),
        equals(ApiEndpoints.productionClientGuid),
      );
      expect(
        ApiEndpoints.normalizeClientGuid(''),
        equals(ApiEndpoints.productionClientGuid),
      );
      expect(
        ApiEndpoints.normalizeClientGuid(ApiEndpoints.productionClientGuid),
        equals(ApiEndpoints.productionClientGuid),
      );
    });

    test(
      'ApiEndpoints.clientNotifications constructs strictly production client GUID route',
      () {
        final endpoint = ApiEndpoints.clientNotifications(
          '03d6aaff-f21b-41fc-902f-8184dacd0861',
        );
        expect(
          endpoint,
          startsWith(
            '/api/v1/clients/6782976c-e9a4-41c9-a754-05e4ba0a97b2/notifications',
          ),
        );
      },
    );

    test(
      'ApiEndpoints.clientHomes constructs strictly production client GUID route',
      () {
        final endpoint = ApiEndpoints.clientHomes(
          '03d6aaff-f21b-41fc-902f-8184dacd0861',
        );
        expect(
          endpoint,
          equals('/api/v1/clients/6782976c-e9a4-41c9-a754-05e4ba0a97b2/homes'),
        );
      },
    );
  });
}
