import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_homez/models/property_hierarchy.dart';
import 'package:smart_homez/widgets/property_summary_card.dart';

void main() {
  testWidgets('property menu contains only the three requested actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertySummaryCard(
            property: const ManagedProperty(
              id: 'property_1',
              name: 'Lakeview Home',
              address: 'Bengaluru',
            ),
            floorCount: 2,
            roomCount: 4,
            deviceCount: 9,
            onlineDeviceCount: 9,
            onOpen: () {},
            onEdit: () {},
            onDelete: () {},
            onHistory: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Property actions'));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Device history'), findsOneWidget);
    expect(find.text('Open property'), findsNothing);
    expect(find.byType(PopupMenuItem<String>), findsNWidgets(3));
  });
}
