import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/screens/environment/environment_screen.dart';
import 'package:smart_homez/services/environment_service.dart';
import 'package:smart_homez/theme/app_theme.dart';

class RealDataEnvironmentService extends EnvironmentService {
  bool setDuskDawnCalled = false;
  Map<String, dynamic>? lastDuskDawnPayload;

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
  Future<bool> setDuskDawn(Map<String, dynamic> payload) async {
    setDuskDawnCalled = true;
    lastDuskDawnPayload = payload;
    return true;
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

class NullDataEnvironmentService extends EnvironmentService {
  @override
  Future<Map<String, dynamic>?> getSolarStatus() async => null;

  @override
  Future<Map<String, dynamic>?> getDuskDawn() async => null;

  @override
  Future<List<Map<String, dynamic>>> getWeatherPrompts() async => const [];

  @override
  Future<Map<String, dynamic>?> getPresence() async => null;

  @override
  Future<Map<String, dynamic>?> getHomeLocation() async => null;

  @override
  Future<List<Map<String, dynamic>>> getWidgets() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnvironmentScreen Data Integrity & Null Safety Tests', () {
    testWidgets('1. Real API values render correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = RealDataEnvironmentService();

      await tester.pumpWidget(
        MaterialApp(home: EnvironmentScreen(service: service)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Smart Environment'), findsOneWidget);
      expect(find.text('24.5°C'), findsOneWidget);
      expect(find.text('52% RH'), findsOneWidget);
      expect(find.text('38 AQI'), findsOneWidget);
      expect(find.text('2.4 UV'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Natural Ventilation'), findsOneWidget);
      expect(find.text('Evening Chill'), findsOneWidget);
    });

    testWidgets(
      '2. Null sensor data does NOT render synthetic fallbacks (24.5, 52, 38, 2.4)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final service = NullDataEnvironmentService();

        await tester.pumpWidget(
          MaterialApp(home: EnvironmentScreen(service: service)),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Synthetic fallbacks must NOT be rendered
        expect(find.text('24.5°C'), findsNothing);
        expect(find.text('52% RH'), findsNothing);
        expect(find.text('38 AQI'), findsNothing);
        expect(find.text('2.4 UV'), findsNothing);

        // Safe neutral representations must be rendered instead
        expect(find.text('Unavailable'), findsWidgets);
      },
    );

    testWidgets(
      '3. Missing solar data does NOT display sample sunrise/sunset times',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final service = NullDataEnvironmentService();

        await tester.pumpWidget(
          MaterialApp(home: EnvironmentScreen(service: service)),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('06:14 AM'), findsNothing);
        expect(find.text('06:48 PM'), findsNothing);
        expect(find.text('12:31 PM'), findsNothing);
        expect(find.text('12h 34m'), findsNothing);

        expect(find.text('--:--'), findsWidgets);
      },
    );

    testWidgets(
      '4. Missing presence data displays "Presence Unavailable", NOT "Home Empty"',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final service = NullDataEnvironmentService();

        await tester.pumpWidget(
          MaterialApp(home: EnvironmentScreen(service: service)),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Presence Unavailable'), findsOneWidget);
        expect(find.text('UNAVAILABLE'), findsWidgets);
        expect(find.text('Home Empty'), findsNothing);
      },
    );

    testWidgets('5. Empty weather prompts and widgets hide sections', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = NullDataEnvironmentService();

      await tester.pumpWidget(
        MaterialApp(home: EnvironmentScreen(service: service)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Smart Recommendations'), findsNothing);
      expect(find.text('Quick Shortcuts'), findsNothing);
    });

    testWidgets(
      '6. Environment screen renders under Hasomi Light Theme without exceptions',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final service = RealDataEnvironmentService();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EnvironmentScreen(service: service),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Smart Environment'), findsOneWidget);
        expect(find.text('Solar Cycle'), findsOneWidget);
      },
    );

    testWidgets('7. Small-screen 360dp width renders safely without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = RealDataEnvironmentService();

      await tester.pumpWidget(
        MaterialApp(home: EnvironmentScreen(service: service)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Smart Environment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
