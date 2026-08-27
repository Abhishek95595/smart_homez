import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_link_response.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_provider.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_service.dart';
import 'package:smart_homez/features/integrations/alexa/alexa_status_model.dart';
import 'package:smart_homez/models/device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alexa Models & Serialization Tests', () {
    test('AlexaStatus deserializes linked and connected states correctly', () {
      final statusMap = {
        'linked': true,
        'connected': true,
        'deviceCount': 4,
      };
      final status = AlexaStatus.fromJson(statusMap);
      expect(status.linked, isTrue);
      expect(status.connected, isTrue);
      expect(status.deviceCount, equals(4));
    });

    test('AlexaLinkResponse deserializes authorizeUrl correctly', () {
      final responseMap = {
        'ssoToken': 'sso_12345',
        'authorizeUrl': 'https://amazon.com/ap/oa?client_id=123',
        'expiresInSeconds': 3600,
      };
      final response = AlexaLinkResponse.fromJson(responseMap);
      expect(response.ssoToken, equals('sso_12345'));
      expect(response.authorizeUrl, equals('https://amazon.com/ap/oa?client_id=123'));
      expect(response.expiresInSeconds, equals(3600));
    });
  });

  group('AlexaService Logic Tests', () {
    test('generateSecureState produces unique valid state UUIDs', () {
      final service = AlexaService();
      final state1 = service.generateSecureState();
      final state2 = service.generateSecureState();

      expect(state1, isNotEmpty);
      expect(state2, isNotEmpty);
      expect(state1, isNot(equals(state2)));
      expect(service.lastGeneratedState, equals(state2));
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

      final wifiDevices = await service.scanLocalWifiDevices(realDevices: mockDevices);

      expect(wifiDevices, hasLength(1));
      expect(wifiDevices.first.id, equals('dev_1'));
      expect(wifiDevices.first.name, equals('Living Room Light'));
    });
  });

  group('AlexaProvider State Management Tests', () {
    test('Initial AlexaProvider state is not connected', () {
      final provider = AlexaProvider();
      expect(provider.isConnecting, isFalse);
      expect(provider.isLinked, isFalse);
      expect(provider.isConnected, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });
}
