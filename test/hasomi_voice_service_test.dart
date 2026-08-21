import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/models/device.dart';
import 'package:smart_homez/services/hasomi_voice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HasomiVoiceService Tests', () {
    final service = HasomiVoiceService.instance;

    final List<Device> testDevices = [
      Device(
        deviceId: 'dev_light_lr',
        name: 'Living Room Light',
        type: DeviceType.light,
        firmwareVersion: '1.0',
        macAddress: 'AA:BB:CC',
        tenantId: 'tenant1',
        buildingId: 'b1',
        roomName: 'Living Room',
        zone: 'Living Room',
        status: DeviceStatus.online,
        isOn: false,
        lastHeartbeat: DateTime.now(),
      ),
      Device(
        deviceId: 'dev_fan_lr',
        name: 'Living Room Fan',
        type: DeviceType.fan,
        firmwareVersion: '1.0',
        macAddress: 'AA:BB:DD',
        tenantId: 'tenant1',
        buildingId: 'b1',
        roomName: 'Living Room',
        zone: 'Living Room',
        status: DeviceStatus.online,
        isOn: false,
        lastHeartbeat: DateTime.now(),
      ),
      Device(
        deviceId: 'dev_light_br',
        name: 'Bedroom Light',
        type: DeviceType.light,
        firmwareVersion: '1.0',
        macAddress: 'AA:BB:EE',
        tenantId: 'tenant1',
        buildingId: 'b1',
        roomName: 'Bedroom',
        zone: 'Bedroom',
        status: DeviceStatus.online,
        isOn: false,
        lastHeartbeat: DateTime.now(),
      ),
      Device(
        deviceId: 'dev_abhishek_light',
        name: 'Abhishek Dimable Light',
        type: DeviceType.light,
        firmwareVersion: '1.0',
        macAddress: 'AA:BB:FF',
        tenantId: 'tenant1',
        buildingId: 'b1',
        roomName: 'Abhishek Room',
        zone: 'Abhishek Room',
        status: DeviceStatus.online,
        isOn: false,
        lastHeartbeat: DateTime.now(),
      ),
    ];

    test('generateGreeting uses logged in user name', () {
      final greeting = service.generateGreeting('Aditya Vikram Singh');
      expect(greeting, equals('Hi Aditya, what can I help you with?'));
    });

    test('parseCommand identifies action, devices, and rooms', () {
      const input = 'Switch off the light and fan of the living room';
      final intent = service.parseCommand(input, testDevices);

      expect(intent.action, equals(HasomiAction.turnOff));
      expect(intent.roomNames, contains('Living Room'));
      expect(intent.deviceTypes, contains('light'));
      expect(intent.deviceTypes, contains('fan'));
    });

    test('parseCommand normalizes ON commands', () {
      const input = 'Turn on the bedroom light';
      final intent = service.parseCommand(input, testDevices);

      expect(intent.action, equals(HasomiAction.turnOn));
      expect(intent.roomNames, contains('Bedroom'));
      expect(intent.deviceTypes, contains('light'));
    });

    test('exact device name matching targets only specified device', () {
      const input = 'Turn on Bedroom Light';
      final intent = service.parseCommand(input, testDevices);
      expect(intent.action, equals(HasomiAction.turnOn));

      final exactMatches = testDevices
          .where((d) => input.toLowerCase().contains(d.name.toLowerCase()))
          .toList();
      expect(exactMatches.length, equals(1));
      expect(exactMatches.first.name, equals('Bedroom Light'));
    });

    test(
      'calling Abhishek Dimable Light turn on targets ONLY Abhishek Dimable Light',
      () {
        const input = 'Abhishek Dimable Light turn on';
        final intent = service.parseCommand(input, testDevices);
        expect(intent.action, equals(HasomiAction.turnOn));

        final exactMatches = testDevices
            .where((d) => input.toLowerCase().contains(d.name.toLowerCase()))
            .toList();
        expect(exactMatches.length, equals(1));
        expect(exactMatches.first.name, equals('Abhishek Dimable Light'));
      },
    );
  });
}
