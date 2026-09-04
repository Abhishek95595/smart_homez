import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:provider/provider.dart';
import 'package:smart_homez/main.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/screens/auth/login_screen.dart';
import 'package:smart_homez/screens/landing/landing_screen.dart';
import 'package:smart_homez/screens/splash/splash_screen.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDirectory = await Directory.systemTemp.createTemp(
      'smart_homez_widget_tests_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  testWidgets('SmartBuildingApp launches splash screen flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartBuildingApp());
    await tester.pump();
    expect(find.byType(VideoSplashScreen), findsOneWidget);
  });

  testWidgets('Landing page opens and navigates to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LandingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hasomi'), findsWidgets);
    expect(find.text('Get started free'), findsWidgets);

    final startButton = find.text('Start').evaluate().isNotEmpty
        ? find.text('Start')
        : find.text('Get started free');

    expect(startButton, findsWidgets);
    await tester.tap(startButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Landing page opens the interactive product demo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pumpAndSettle();

    final demoButton = find.text('See how it works');
    expect(demoButton, findsWidgets);

    await tester.ensureVisible(demoButton.first);
    await tester.tap(demoButton.first);
    await tester.pumpAndSettle();

    expect(find.text('How Hasomi works'), findsOneWidget);
    expect(find.text('1. Add any property'), findsOneWidget);
  });
}
