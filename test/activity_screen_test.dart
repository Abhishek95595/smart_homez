import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_homez/providers/alert_provider.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/screens/activity/activity_screen.dart';
import 'package:smart_homez/theme/app_theme.dart';

void main() {
  testWidgets('activity screen presents the searchable timeline and filters', (
    tester,
  ) async {
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

    expect(find.text('Activity Stream'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All Feed'), findsOneWidget);
    expect(find.text('New Unread'), findsOneWidget);
    expect(find.text('Acknowledged'), findsWidgets);
    expect(find.text('Resolved'), findsWidgets);
  });
}
