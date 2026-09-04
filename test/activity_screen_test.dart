import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_homez/models/alert.dart';
import 'package:smart_homez/providers/alert_provider.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/screens/activity/activity_screen.dart';
import 'package:smart_homez/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActivityScreen Redesign & Functionality Tests', () {
    testWidgets('1. ActivityScreen presents timeline, search, and filters', (
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
            home: const ActivityScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Activity Stream'), findsOneWidget);
      expect(find.text('LIVE SYSTEM EVENT FEED'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All Feed'), findsOneWidget);
      expect(find.text('New Unread'), findsOneWidget);
      expect(find.text('Acknowledged'), findsWidgets);
      expect(find.text('Resolved'), findsWidgets);
    });

    testWidgets(
      '2. Renders dynamic alerts with acknowledge & resolve buttons',
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
              home: const ActivityScreen(),
            ),
          ),
        );

        await tester.pump();

        final firstAlert = alertProvider.alerts.first;
        expect(find.text(firstAlert.alertType.label), findsWidgets);

        // Tap acknowledge on first unacknowledged alert card
        final ackButton = find.text('Acknowledge').first;
        await tester.tap(ackButton);
        await tester.pump();

        expect(firstAlert.acknowledged, isTrue);
      },
    );

    testWidgets('3. Activity screen renders safely under Hasomi Light Theme', (
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
            home: const ActivityScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Activity Stream'), findsOneWidget);
      expect(find.text('Live System Events'), findsOneWidget);
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
              home: const ActivityScreen(),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Activity Stream'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
