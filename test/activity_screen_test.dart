import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/providers/alert_provider.dart';
import 'package:flutter_app/screens/activity/activity_screen.dart';
import 'package:flutter_app/theme/app_theme.dart';

void main() {
  testWidgets('activity screen presents the searchable timeline and filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AlertProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ActivityScreen(),
        ),
      ),
    );

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'New'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Acknowledged'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Resolved'), findsOneWidget);
  });
}
