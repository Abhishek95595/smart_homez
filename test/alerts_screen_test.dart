import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_homez/providers/alert_provider.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/screens/alerts/alerts_screen.dart';
import 'package:smart_homez/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlertsScreen Redesign & Safety Functionality Tests', () {
    testWidgets('1. AlertsScreen presents header, search, tabs, and filters', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AlertProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AlertsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Safety & Alerts'), findsOneWidget);
      expect(find.text('REAL-TIME INCIDENT MONITOR'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Ack.'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Critical'), findsWidgets);
    });

    testWidgets(
      '2. Renders critical incident hero card when critical alerts exist',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final alertProvider = AlertProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: alertProvider),
              ChangeNotifierProvider(create: (_) => AuthProvider()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const AlertsScreen(),
            ),
          ),
        );

        await tester.pump();

        if (alertProvider.criticalActiveCount > 0) {
          expect(
            find.text(
              'Immediate attention required for active property safety',
            ),
            findsOneWidget,
          );
          expect(find.text('VIEW'), findsOneWidget);
        }
      },
    );

    testWidgets('3. Alerts screen renders safely under Hasomi Light Theme', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AlertProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AlertsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Safety & Alerts'), findsOneWidget);
      expect(find.text('REAL-TIME INCIDENT MONITOR'), findsOneWidget);
    });

    testWidgets(
      '4. Small-screen 360dp viewport renders safely without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AlertProvider()),
              ChangeNotifierProvider(create: (_) => AuthProvider()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const AlertsScreen(),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Safety & Alerts'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
