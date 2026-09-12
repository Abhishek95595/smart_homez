import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/screens/environment/environment_screen.dart';
import 'package:smart_homez/services/environment_service.dart';

class FakeEnvironmentService extends EnvironmentService {
  @override
  Future<Map<String, dynamic>?> getSolarStatus() async {
    return {
      'sunrise': '06:14 AM',
      'sunset': '06:48 PM',
      'solarNoon': '12:31 PM',
      'sunState': 'Daylight Optimal',
      'temperature': '24.5',
      'humidity': '52',
      'aqi': '38',
      'uvIndex': '2.4',
    };
  }

  @override
  Future<Map<String, dynamic>?> getDuskDawn() async {
    return {'enabled': true, 'mode': 'automatic'};
  }

  @override
  Future<List<Map<String, dynamic>>> getWeatherPrompts() async {
    return [
      {
        'title': 'Natural Ventilation',
        'description': 'Open windows for optimal breeze.',
        'type': 'wind',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>?> getPresence() async {
    return {
      'homeState': 'occupied',
      'members': [
        {'name': 'Rahul Sharma', 'status': 'home'},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>?> getHomeLocation() async {
    return {
      'latitude': '28.6139',
      'longitude': '77.2090',
      'geofenceRadius': 100,
      'wifiSsid': 'Hasomi_Home_5G',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getWidgets() async {
    return [
      {'name': 'Evening Chill', 'id': 'sc_1'},
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnvironmentScreen & EnvironmentService Tests', () {
    test('EnvironmentService exposes all 6 environment API methods', () {
      final service = EnvironmentService();
      expect(service.getSolarStatus, isNotNull);
      expect(service.getDuskDawn, isNotNull);
      expect(service.setDuskDawn, isNotNull);
      expect(service.getWeatherPrompts, isNotNull);
      expect(service.getHomeLocation, isNotNull);
      expect(service.setHomeLocation, isNotNull);
      expect(service.getPresence, isNotNull);
      expect(service.reportPresence, isNotNull);
      expect(service.getWidgets, isNotNull);
    });

    testWidgets(
      'EnvironmentScreen renders with solar arc, metrics, and cards',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeService = FakeEnvironmentService();

        await tester.pumpWidget(
          MaterialApp(home: EnvironmentScreen(service: fakeService)),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Check title
        expect(find.text('Smart Environment'), findsOneWidget);

        // Check section titles
        expect(find.text('Solar Cycle'), findsOneWidget);
        expect(find.text('Live Conditions'), findsOneWidget);
        expect(find.text('Dusk-to-Dawn'), findsOneWidget);
        expect(find.text('Family Presence'), findsOneWidget);
        expect(find.text('Home Location'), findsOneWidget);

        // Check metric titles
        expect(find.text('Temperature'), findsOneWidget);
        expect(find.text('Humidity'), findsOneWidget);
        expect(find.text('Air Quality'), findsOneWidget);
        expect(find.text('UV Index'), findsOneWidget);

        // Check presence & prompt data loaded
        expect(find.text('Rahul Sharma'), findsOneWidget);
        expect(find.text('Natural Ventilation'), findsOneWidget);
        expect(find.text('Evening Chill'), findsOneWidget);
      },
    );
  });
}
