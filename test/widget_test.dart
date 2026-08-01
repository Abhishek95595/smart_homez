import 'package:flutter_test/flutter_test.dart';

import 'package:smart_homez/main.dart';

void main() {
  testWidgets('App launches landing page and opens login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartBuildingApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Homez'), findsWidgets);
    expect(find.text('Get started free'), findsWidgets);

    final startButton = find.text('Start').evaluate().isNotEmpty
        ? find.text('Start')
        : find.text('Get started');
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Secure Access'), findsOneWidget);
    expect(find.text('Connect & Sign In'), findsOneWidget);
  });

  testWidgets('Landing page opens the interactive product demo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartBuildingApp());
    await tester.pumpAndSettle();

    final demoButton = find.text('See how it works');
    await tester.ensureVisible(demoButton);
    await tester.tap(demoButton);
    await tester.pumpAndSettle();

    expect(find.text('How Smart Homez works'), findsOneWidget);
    expect(find.text('1. Add any property'), findsOneWidget);
  });
}
