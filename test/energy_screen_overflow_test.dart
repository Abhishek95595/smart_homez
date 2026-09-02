import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/energy_provider.dart';
import 'package:smart_homez/providers/property_provider.dart';
import 'package:smart_homez/providers/tariff_provider.dart';
import 'package:smart_homez/screens/energy/energy_screen.dart';

import 'test_helpers.dart';

Widget _buildTestEnergyApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => createTestPropertyProvider()),
      ChangeNotifierProvider(create: (_) => createTestDeviceProvider()),
      ChangeNotifierProvider(create: (_) => EnergyProvider()),
      ChangeNotifierProvider(create: (_) => TariffProvider()),
    ],
    child: const MaterialApp(home: EnergyScreen()),
  );
}

void main() {
  testWidgets('EnergyScreen renders without pixel overflow on narrow mobile screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildTestEnergyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Energy Monitoring'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EnergyScreen renders without overflow on standard mobile (360x740)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildTestEnergyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Energy Monitoring'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Energy comparison & insights modals render without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildTestEnergyApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Tap compare modal icon
    final swapIcon = find.byIcon(Icons.swap_vert_rounded);
    if (swapIcon.evaluate().isNotEmpty) {
      await tester.tap(swapIcon);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Energy Source Matrix'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Close modal
      await tester.tapAt(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Tap insights modal icon
    final insightsIcon = find.byIcon(Icons.auto_awesome_rounded);
    if (insightsIcon.evaluate().isNotEmpty) {
      await tester.tap(insightsIcon.first);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('AI Energy Audit & Insights'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
