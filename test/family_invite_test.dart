import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:smart_homez/models/family_member_model.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/family_provider.dart';
import 'package:smart_homez/screens/family/family_invite_screen.dart';
import 'package:smart_homez/services/family_service.dart';

import 'test_helpers.dart';

class FakeFamilyService extends FamilyService {
  final List<FamilyMember> fakeRoster = [
    FamilyMember(
      id: 'fam_1',
      name: 'Aditya Singh',
      phone: '+91 98765 43210',
      role: 'member',
      status: 'joined',
      allDevicesGranted: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Future<List<FamilyMember>> getFamilyMembers(String clientId) async {
    return List.from(fakeRoster);
  }

  @override
  Future<Map<String, dynamic>> inviteFamilyMember({
    required String clientId,
    String? phone,
    String? email,
    String? name,
    String? role,
    String? accessLevel,
  }) async {
    final newMember = FamilyMember(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      email: email,
      role: role ?? accessLevel ?? 'member',
      status: 'pending',
      allDevicesGranted: true,
    );
    fakeRoster.add(newMember);
    return {'id': newMember.id, 'success': true};
  }

  @override
  Future<bool> updateDevicePermissions({
    required String clientId,
    required String memberId,
    required List<FamilyDevicePermissionEntry> permissions,
  }) async {
    return true;
  }

  @override
  Future<bool> updateMemberRole({
    required String clientId,
    required String memberId,
    required String role,
  }) async {
    final idx = fakeRoster.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      fakeRoster[idx] = fakeRoster[idx].copyWith(role: role);
    }
    return true;
  }

  @override
  Future<bool> removeFamilyMember({
    required String clientId,
    required String memberId,
  }) async {
    fakeRoster.removeWhere((m) => m.id == memberId);
    return true;
  }

  @override
  Future<bool> resendInvite({
    required String clientId,
    required String memberId,
    String? email,
    String? phone,
  }) async {
    return true;
  }

  @override
  Future<String?> getJoinLink({
    required String clientId,
    required String memberId,
  }) async {
    return 'https://tenant-api-qa.omnihome.in/invite?token=test_token_$memberId';
  }
}

Widget _buildFamilyTestApp({
  required FamilyProvider familyProvider,
  required DeviceProvider deviceProvider,
  AuthProvider? authProvider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? AuthProvider(),
      ),
      ChangeNotifierProvider<FamilyProvider>.value(value: familyProvider),
      ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('FamilyMember Model Tests', () {
    test('FamilyMember serialization & deserialization', () {
      final member = FamilyMember(
        id: 'mem_123',
        name: 'Aditya Singh',
        phone: '+919876543210',
        role: 'admin',
        status: 'pending',
        allDevicesGranted: true,
        permissions: const [
          FamilyDevicePermissionEntry(
            deviceId: 'dev_1',
            deviceName: 'Living Room Light',
            canView: true,
            canControl: true,
          ),
        ],
      );

      final json = member.toJson();
      expect(json['id'], 'mem_123');
      expect(json['phone'], '+919876543210');
      expect(json['allDevicesGranted'], isTrue);

      final fromJson = FamilyMember.fromJson(json);
      expect(fromJson.id, 'mem_123');
      expect(fromJson.name, 'Aditya Singh');
      expect(fromJson.phone, '+919876543210');
      expect(fromJson.permissions.length, 1);
      expect(fromJson.permissions.first.deviceId, 'dev_1');
      expect(fromJson.isPending, isTrue);
      expect(fromJson.isAdmin, isTrue);
      expect(fromJson.roleDisplay, 'Admin');
    });
  });

  group('FamilyProvider Tests', () {
    test('Invite member by phone with all devices granted', () async {
      final fakeService = FakeFamilyService();
      final familyProvider = FamilyProvider(familyService: fakeService);
      familyProvider.setClientId('test_client_uuid');
      final deviceProvider = createTestDeviceProvider();

      final member = await familyProvider.inviteMemberByPhone(
        phone: '+919876543210',
        name: 'Alice',
        accessLevel: 'admin',
        grantAllDevices: true,
        availableDevices: deviceProvider.devices,
      );

      expect(member, isNotNull);
      expect(member!.phone, '+919876543210');
      expect(member.name, 'Alice');
      expect(member.role, 'admin');
      expect(member.allDevicesGranted, isTrue);
      expect(
        familyProvider.members.any((m) => m.phone == '+919876543210'),
        isTrue,
      );
    });

    test('Promote member to admin updates role', () async {
      final fakeService = FakeFamilyService();
      final familyProvider = FamilyProvider(familyService: fakeService);
      familyProvider.setClientId('test_client_uuid');
      await familyProvider.fetchMembers();

      final firstId = familyProvider.members.first.id;
      final ok = await familyProvider.updateMemberRole(
        memberId: firstId,
        role: 'admin',
      );

      expect(ok, isTrue);
      expect(
        familyProvider.members.firstWhere((m) => m.id == firstId).isAdmin,
        isTrue,
      );
    });

    test('Revoke family member removes member from roster', () async {
      final fakeService = FakeFamilyService();
      final familyProvider = FamilyProvider(familyService: fakeService);
      familyProvider.setClientId('test_client_uuid');
      await familyProvider.fetchMembers();

      final initialCount = familyProvider.members.length;
      expect(initialCount, greaterThan(0));

      final firstId = familyProvider.members.first.id;
      final success = await familyProvider.removeMember(firstId);

      expect(success, isTrue);
      expect(familyProvider.members.any((m) => m.id == firstId), isFalse);
    });
    test('Update and fetch member device permissions', () async {
      final fakeService = FakeFamilyService();
      final familyProvider = FamilyProvider(familyService: fakeService);
      familyProvider.setClientId('test_client_uuid');
      await familyProvider.fetchMembers();

      final firstId = familyProvider.members.first.id;
      final newPermissions = [
        const FamilyDevicePermissionEntry(
          deviceId: 'dev_1',
          canView: true,
          canControl: false,
        ),
        const FamilyDevicePermissionEntry(
          deviceId: 'dev_2',
          canView: true,
          canControl: true,
        ),
      ];

      final success = await familyProvider.updateMemberDevicePermissions(
        memberId: firstId,
        permissions: newPermissions,
        totalAvailableDevicesCount: 4,
      );

      expect(success, isTrue);
      final member = familyProvider.members.firstWhere((m) => m.id == firstId);
      expect(member.permissions.length, 2);
      expect(member.allDevicesGranted, isFalse);
    });
  });

  group('FamilyInviteScreen Widget Tests', () {
    testWidgets(
      'Renders FamilyInviteScreen with Primary Admin card and real members',
      (WidgetTester tester) async {
        final fakeService = FakeFamilyService();
        final familyProvider = FamilyProvider(familyService: fakeService);
        familyProvider.setClientId('test_client_uuid');
        final deviceProvider = createTestDeviceProvider();

        await familyProvider.fetchMembers();

        await tester.pumpWidget(
          _buildFamilyTestApp(
            familyProvider: familyProvider,
            deviceProvider: deviceProvider,
            child: const FamilyInviteScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Family & Device Access'), findsOneWidget);
        expect(find.text('Total Active'), findsOneWidget);
        expect(find.text('Pending Invites'), findsOneWidget);
        expect(find.text('Home Devices'), findsOneWidget);
        expect(find.text('Family Members & Roles'), findsOneWidget);
        expect(find.text('Primary Admin'), findsOneWidget);
        expect(find.text('Aditya Singh'), findsOneWidget);
        expect(find.byType(FamilyInviteScreen), findsOneWidget);
      },
    );

    testWidgets(
      'MemberDevicePermissionsBottomSheet allows per-device View and Control customization',
      (WidgetTester tester) async {
        final fakeService = FakeFamilyService();
        final familyProvider = FamilyProvider(familyService: fakeService);
        familyProvider.setClientId('test_client_uuid');
        final deviceProvider = createTestDeviceProvider();
        await familyProvider.fetchMembers();

        final member = familyProvider.members.first;

        await tester.pumpWidget(
          _buildFamilyTestApp(
            familyProvider: familyProvider,
            deviceProvider: deviceProvider,
            child: Scaffold(
              body: Center(
                child: MemberDevicePermissionsBottomSheet(member: member),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Device Access Permissions'), findsOneWidget);
        expect(find.text('Grant All'), findsOneWidget);
        expect(find.text('Revoke All'), findsOneWidget);
        expect(find.text('Save Permissions'), findsOneWidget);

        // Tap Revoke All
        await tester.tap(find.text('Revoke All'));
        await tester.pumpAndSettle();

        // Tap Grant All
        await tester.tap(find.text('Grant All'));
        await tester.pumpAndSettle();

        // Tap Save Permissions
        await tester.tap(find.text('Save Permissions'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'FamilyInviteBottomSheet allows phone input, role selection and all devices toggle',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeService = FakeFamilyService();
        final familyProvider = FamilyProvider(familyService: fakeService);
        familyProvider.setClientId('test_client_uuid');
        final deviceProvider = createTestDeviceProvider();

        await tester.pumpWidget(
          _buildFamilyTestApp(
            familyProvider: familyProvider,
            deviceProvider: deviceProvider,
            child: const Scaffold(
              body: Center(
                child: FamilyInviteBottomSheet(initialMethod: 'phone'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Invite Family Member'), findsOneWidget);
        expect(find.text('Phone Number *'), findsOneWidget);
        expect(find.text('Access Role'), findsOneWidget);
        expect(find.text('Give Access to All Devices'), findsOneWidget);

        // Tap submit without phone -> validation error
        final submitBtn = find.text('Send Phone Invite & Grant Access');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Please enter the phone number to invite.'),
          findsOneWidget,
        );

        // Select Admin role
        await tester.tap(find.text('Admin'));
        await tester.pumpAndSettle();

        // Enter valid phone number and submit
        await tester.enterText(
          find.byType(TextFormField).first,
          '+919876543210',
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(find.text('Please enter a phone number.'), findsNothing);
      },
    );
  });
}
