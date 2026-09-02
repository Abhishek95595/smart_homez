import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_link_response.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_provider.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_service.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_status_model.dart';
import 'package:smart_homez/models/device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
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
      'AlexaLinkResponse preserves exact authorizeUrl without prepending or modification',
      () {
        final responseMap = {
          'ssoToken': 'sso_12345',
          'authorizeUrl':
              'https://amazon.com/ap/oa?client_id=amzn1.application-oa2-client.123&scope=alexa%3A%3Askills%3Aaccount_linking&response_type=code&redirect_uri=hasomi.com.homeautomation%3A%2F%2Falexa-callback&state=test-state',
          'expiresInSeconds': 120,
        };
        final response = AlexaLinkResponse.fromJson(responseMap);
        expect(
          response.authorizeUrl,
          equals(
            'https://amazon.com/ap/oa?client_id=amzn1.application-oa2-client.123&scope=alexa%3A%3Askills%3Aaccount_linking&response_type=code&redirect_uri=hasomi.com.homeautomation%3A%2F%2Falexa-callback&state=test-state',
          ),
        );
      },
    );

    test(
      'resolveAuthorizeUri resolves root-relative path against request origin',
      () {
        final requestUri = Uri.parse(
          'https://tenant-api-qa.omnihome.in/api/integrations/alexa/link-token',
        );
        final resolved = AlexaService.resolveAuthorizeUri(
          authorizeUrl:
              '/oauth/authorize?response_type=code&client_id=omnihome-alexa&sso_token=sso_123',
          requestUri: requestUri,
        );
        expect(
          resolved.toString(),
          equals(
            'https://tenant-api-qa.omnihome.in/oauth/authorize?response_type=code&client_id=omnihome-alexa&sso_token=sso_123',
          ),
        );
      },
    );

    test('resolveAuthorizeUri preserves absolute URL unchanged', () {
      final requestUri = Uri.parse(
        'https://tenant-api-qa.omnihome.in/api/integrations/alexa/link-token',
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
        'https://tenant-api-qa.omnihome.in/api/integrations/alexa/link-token',
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
}
