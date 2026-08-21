import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:smart_homez/main.dart';

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

  testWidgets('App launches landing page and opens login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartBuildingApp());
    await tester.pumpAndSettle();

    expect(find.text('Hasomi'), findsWidgets);
    expect(find.text('Get started free'), findsWidgets);

    final startButton = find.text('Start').evaluate().isNotEmpty
        ? find.text('Start')
        : find.text('Get started');

    expect(startButton, findsWidgets);
    await tester.tap(startButton.first);
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('Landing page opens the interactive product demo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartBuildingApp());
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
