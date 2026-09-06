import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:smart_homez/main.dart';
import 'package:smart_homez/screens/auth/login_screen.dart';

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

  testWidgets('App launches and opens login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartBuildingApp());
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
