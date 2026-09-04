import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_homez/models/robot_avatar.dart';
import 'package:smart_homez/screens/voice/hasomi_screen.dart';
import 'package:smart_homez/utils/robot_avatar_mapper.dart';
import 'package:smart_homez/widgets/hasomi_bottom_voice_bar.dart';
import 'package:smart_homez/widgets/robot_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RobotAvatar Model & Extension Tests', () {
    test('1. Exactly 12 RobotAvatarType enum values exist', () {
      expect(RobotAvatarType.values.length, equals(12));
    });

    test('2. Every RobotAvatarType has a unique storage ID', () {
      final Set<String> ids = {};
      for (final type in RobotAvatarType.values) {
        expect(type.storageId, startsWith('robot_'));
        expect(
          ids.add(type.storageId),
          isTrue,
          reason: 'Duplicate storageId: ${type.storageId}',
        );
      }
      expect(ids.length, equals(12));
    });

    test('3. Every RobotAvatarType has a unique asset path', () {
      final Set<String> paths = {};
      for (final type in RobotAvatarType.values) {
        expect(
          paths.add(type.assetPath),
          isTrue,
          reason: 'Duplicate assetPath: ${type.assetPath}',
        );
      }
      expect(paths.length, equals(12));
    });

    test('4. All asset files exist on disk', () {
      for (final type in RobotAvatarType.values) {
        final File file = File(type.assetPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Missing asset file: ${type.assetPath}',
        );
      }
    });

    test(
      '10 & 11. fromStorageId maps valid, legacy, and unknown/null IDs cleanly',
      () {
        // Valid IDs
        expect(
          RobotAvatarTypeX.fromStorageId('robot_happy'),
          equals(RobotAvatarType.happy),
        );
        expect(
          RobotAvatarTypeX.fromStorageId('robot_alert'),
          equals(RobotAvatarType.alert),
        );
        expect(
          RobotAvatarTypeX.fromStorageId('robot_confident'),
          equals(RobotAvatarType.confident),
        );

        // Legacy IDs fallback
        expect(
          RobotAvatarTypeX.fromStorageId('smart_robot'),
          equals(RobotAvatarType.neutral),
        );
        expect(
          RobotAvatarTypeX.fromStorageId('new_robot'),
          equals(RobotAvatarType.happy),
        );
        expect(
          RobotAvatarTypeX.fromStorageId('fire_safety'),
          equals(RobotAvatarType.alert),
        );
        expect(
          RobotAvatarTypeX.fromStorageId('water_robot'),
          equals(RobotAvatarType.confident),
        );

        // Unknown & null fallback -> neutral
        expect(
          RobotAvatarTypeX.fromStorageId('corrupted_id_123'),
          equals(RobotAvatarType.neutral),
        );
        expect(
          RobotAvatarTypeX.fromStorageId(null),
          equals(RobotAvatarType.neutral),
        );
        expect(
          RobotAvatarTypeX.fromStorageId(''),
          equals(RobotAvatarType.neutral),
        );
      },
    );
  });

  group('RobotAvatarMapper Tests', () {
    test('6. mapHasomiState maps HasomiState to correct RobotAvatarType', () {
      expect(
        RobotAvatarMapper.mapHasomiState(HasomiState.ready),
        equals(RobotAvatarType.neutral),
      );
      expect(
        RobotAvatarMapper.mapHasomiState(HasomiState.listeningForCommand),
        equals(RobotAvatarType.listening),
      );
      expect(
        RobotAvatarMapper.mapHasomiState(HasomiState.controllingDevices),
        equals(RobotAvatarType.thinking),
      );
      expect(
        RobotAvatarMapper.mapHasomiState(HasomiState.wakeWordDetected),
        equals(RobotAvatarType.happy),
      );
    });

    test('7. speaking mapping operates when isSpeaking is true', () {
      expect(
        RobotAvatarMapper.mapHasomiState(
          HasomiState.listeningForCommand,
          isSpeaking: true,
        ),
        equals(RobotAvatarType.speaking),
      );
      expect(
        RobotAvatarMapper.mapVoiceBarState(
          HasomiVoiceBarState.idle,
          isSpeaking: true,
        ),
        equals(RobotAvatarType.speaking),
      );
    });

    test('8. success and error mapping for result state', () {
      expect(
        RobotAvatarMapper.mapHasomiState(
          HasomiState.displayResult,
          overallSuccess: true,
        ),
        equals(RobotAvatarType.success),
      );
      expect(
        RobotAvatarMapper.mapHasomiState(
          HasomiState.displayResult,
          overallSuccess: false,
        ),
        equals(RobotAvatarType.concerned),
      );
      expect(
        RobotAvatarMapper.mapVoiceBarState(HasomiVoiceBarState.success),
        equals(RobotAvatarType.success),
      );
      expect(
        RobotAvatarMapper.mapVoiceBarState(HasomiVoiceBarState.error),
        equals(RobotAvatarType.concerned),
      );
    });

    test('9. alert severity mapping', () {
      expect(
        RobotAvatarMapper.mapAlertSeverity(activeAlertCount: 0),
        equals(RobotAvatarType.confident),
      );
      expect(
        RobotAvatarMapper.mapAlertSeverity(
          activeAlertCount: 2,
          maxSeverity: 'CRITICAL',
        ),
        equals(RobotAvatarType.alert),
      );
      expect(
        RobotAvatarMapper.mapAlertSeverity(
          activeAlertCount: 1,
          maxSeverity: 'HIGH',
        ),
        equals(RobotAvatarType.alert),
      );
      expect(
        RobotAvatarMapper.mapAlertSeverity(
          activeAlertCount: 1,
          maxSeverity: 'WARNING',
        ),
        equals(RobotAvatarType.concerned),
      );
    });
  });

  group('RobotAvatar Widget Render & Responsive Tests', () {
    testWidgets('5. Renders RobotAvatar for all 12 types without error', (
      WidgetTester tester,
    ) async {
      for (final type in RobotAvatarType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: RobotAvatar(type: type, size: 100)),
            ),
          ),
        );
        expect(find.byType(RobotAvatar), findsOneWidget);
      }
    });

    testWidgets('13. AnimatedSwitcher uses ValueKey(type) for child keying', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RobotAvatar(type: RobotAvatarType.happy, size: 80),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<RobotAvatarType>(RobotAvatarType.happy)),
        findsOneWidget,
      );
    });

    testWidgets(
      '12. Renders cleanly on various screen widths (320px, 360px, 390px, 430px)',
      (WidgetTester tester) async {
        const widths = [320.0, 360.0, 390.0, 430.0, 768.0];

        for (final w in widths) {
          tester.view.physicalSize = Size(w, 800);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: RobotAvatar.large(type: RobotAvatarType.confident),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
        }

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      },
    );
  });
}
