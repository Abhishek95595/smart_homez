import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_homez/core/network/api_client.dart';
import 'package:smart_homez/core/network/api_endpoints.dart';
import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/client_profile.dart';
import 'package:smart_homez/models/home_model.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/profile_provider.dart';
import 'package:smart_homez/providers/property_provider.dart';
import 'package:smart_homez/providers/theme_provider.dart';
import 'package:smart_homez/screens/profile/profile_screen.dart';
import 'package:smart_homez/screens/profile/profile_theme.dart';
import 'package:smart_homez/screens/profile/widgets/avatar_picker_sheet.dart';
import 'package:smart_homez/screens/profile/widgets/avatar_progress_ring.dart';
import 'package:smart_homez/screens/profile/widgets/profile_hero.dart';
import 'package:smart_homez/screens/profile/widgets/profile_home_card.dart';
import 'package:smart_homez/screens/profile/widgets/profile_logout_button.dart';
import 'package:smart_homez/screens/profile/widgets/profile_stats.dart';
import 'package:smart_homez/services/device_repository.dart';
import 'package:smart_homez/services/profile_service.dart';
import 'package:smart_homez/services/property_repository.dart';

class FakeApiClient implements ApiClient {
  final List<String> requestedPaths = [];
  final Map<String, dynamic> responses = {};

  void setResponse(String path, dynamic data) {
    responses[path] = data;
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    requestedPaths.add(path);
    final data = responses[path];
    return Response(
      requestOptions: RequestOptions(
        path: path,
        queryParameters: queryParameters,
      ),
      statusCode: 200,
      data: data,
    );
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    requestedPaths.add(path);
    final responseData = responses[path];
    return Response(
      requestOptions: RequestOptions(path: path, data: data),
      statusCode: 200,
      data: responseData,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. ProfileThemeData & Theme Resolution Tests', () {
    test('verifies Dark theme palette constants', () {
      const dark = ProfileTheme.dark;
      expect(dark.isDark, isTrue);
      expect(dark.background, equals(const Color(0xFF10151A)));
      expect(dark.panel, equals(const Color(0xFF1A2027)));
      expect(dark.raised, equals(const Color(0xFF20272F)));
      expect(dark.accent, equals(const Color(0xFF4DE8C0)));
      expect(dark.warmAccent, equals(const Color(0xFFFFB169)));
      expect(dark.textPrimary, equals(const Color(0xFFEEF2F4)));
      expect(dark.textSecondary, equals(const Color(0xFF9AA6B0)));
      expect(dark.textTertiary, equals(const Color(0xFF5D6871)));
      expect(dark.danger, equals(const Color(0xFFFF6B6B)));
    });

    test('verifies Light theme palette constants', () {
      const light = ProfileTheme.light;
      expect(light.isDark, isFalse);
      expect(light.background, equals(const Color(0xFFF5FAF9)));
      expect(light.panel, equals(const Color(0xFFFFFFFF)));
      expect(light.raised, equals(const Color(0xFFF0F5F4)));
      expect(light.secondarySurface, equals(const Color(0xFFEAF4F2)));
      expect(light.accent, equals(const Color(0xFF00A38E)));
      expect(light.accentSoft, equals(const Color(0xFFE3F7F2)));
      expect(light.warmAccent, equals(const Color(0xFFE88A35)));
      expect(light.warmAccentSoft, equals(const Color(0xFFFFF1E4)));
      expect(light.textPrimary, equals(const Color(0xFF14201F)));
      expect(light.textSecondary, equals(const Color(0xFF64726F)));
      expect(light.textTertiary, equals(const Color(0xFF929E9B)));
      expect(light.border, equals(const Color(0xFFE2EAE8)));
      expect(light.danger, equals(const Color(0xFFD94A4A)));
      expect(light.dangerSoft, equals(const Color(0xFFFFEEEE)));
    });

    testWidgets('resolves dark theme when brightness is dark', (tester) async {
      late ProfileThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              resolved = ProfileTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved.isDark, isTrue);
      expect(resolved.background, equals(const Color(0xFF10151A)));
    });

    testWidgets('resolves light theme when brightness is light', (
      tester,
    ) async {
      late ProfileThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              resolved = ProfileTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved.isDark, isFalse);
      expect(resolved.background, equals(const Color(0xFFF5FAF9)));
    });
  });

  group('2. ClientProfile Model Tests', () {
    test('parses snake_case backend payload correctly', () {
      final json = {
        'client_id': 'df0df9e3-0e47-4d46-810e-3c4f5c267d69',
        'client_name': 'Abhishek Verma',
        'email': 'abhishek@aurabrain.com',
        'phone': '+919876543210',
        'is_active': true,
        'timezone': 'Asia/Kolkata',
        'home_count': 2,
        'device_count': 8,
        'online_device_count': 6,
        'permission_level': 'read_write',
      };

      final profile = ClientProfile.fromJson(json);

      expect(profile.id, equals('df0df9e3-0e47-4d46-810e-3c4f5c267d69'));
      expect(profile.name, equals('Abhishek Verma'));
      expect(profile.email, equals('abhishek@aurabrain.com'));
      expect(profile.phone, equals('+919876543210'));
      expect(profile.isActive, isTrue);
      expect(profile.timezone, equals('Asia/Kolkata'));
      expect(profile.homeCount, equals(2));
      expect(profile.deviceCount, equals(8));
      expect(profile.onlineDeviceCount, equals(6));
      expect(profile.permissionLevel, equals('read_write'));
      expect(profile.onlineRatio, closeTo(0.75, 0.01));
    });

    test('parses camelCase payload and calculates safe 0-device ratio', () {
      final json = {
        'id': 'df0df9e3-0e47-4d46-810e-3c4f5c267d69',
        'name': 'Resident User',
        'email': 'resident@example.com',
        'deviceCount': 0,
        'onlineDeviceCount': 0,
      };

      final profile = ClientProfile.fromJson(json);

      expect(profile.name, equals('Resident User'));
      expect(profile.deviceCount, equals(0));
      expect(profile.onlineDeviceCount, equals(0));
      expect(profile.onlineRatio, equals(0.0));
    });
  });

  group('3. ProfileService Tests', () {
    late FakeApiClient fakeApi;
    late ProfileService profileService;
    const validUuid = 'df0df9e3-0e47-4d46-810e-3c4f5c267d69';

    setUp(() {
      fakeApi = FakeApiClient();
      profileService = ProfileService(apiClient: fakeApi);
    });

    test('getClientProfile requests GET /api/v1/clients/{clientId}', () async {
      fakeApi.setResponse(ApiEndpoints.client(validUuid), {
        'success': true,
        'data': {
          'client_id': validUuid,
          'client_name': 'Abhishek Verma',
          'email': 'abhishek@aurabrain.com',
          'device_count': 10,
          'online_device_count': 7,
        },
      });

      final profile = await profileService.getClientProfile(validUuid);

      expect(profile, isNotNull);
      expect(profile!.name, equals('Abhishek Verma'));
      expect(profile.deviceCount, equals(10));
      expect(profile.onlineDeviceCount, equals(7));
      expect(fakeApi.requestedPaths, contains('/api/v1/clients/$validUuid'));
    });

    test('getClientProfile rejects non-UUID without network call', () async {
      final profile = await profileService.getClientProfile('anvyaaai_AEB3');
      expect(profile, isNull);
      expect(fakeApi.requestedPaths, isEmpty);
    });

    test(
      'getClientHomes requests GET /api/v1/clients/{clientId}/homes',
      () async {
        fakeApi.setResponse(ApiEndpoints.clientHomes(validUuid), {
          'success': true,
          'data': [
            {
              'id': 'home-1',
              'name': 'Greenwood Villa',
              'address': 'Private Address',
            },
          ],
        });

        final homes = await profileService.getClientHomes(validUuid);

        expect(homes.length, equals(1));
        expect(homes.first.name, equals('Greenwood Villa'));
        expect(
          fakeApi.requestedPaths,
          contains('/api/v1/clients/$validUuid/homes'),
        );
      },
    );
  });

  group('4. ProfileProvider State & Concurrency Tests', () {
    late FakeApiClient fakeApi;
    late ProfileService profileService;
    late ProfileProvider profileProvider;
    const validUuid = 'df0df9e3-0e47-4d46-810e-3c4f5c267d69';

    setUp(() {
      fakeApi = FakeApiClient();
      profileService = ProfileService(apiClient: fakeApi);
      profileProvider = ProfileProvider(profileService: profileService);
    });

    test('loadProfile fetches client profile and homes concurrently', () async {
      fakeApi.setResponse(ApiEndpoints.client(validUuid), {
        'success': true,
        'data': {
          'client_id': validUuid,
          'client_name': 'Abhishek Verma',
          'email': 'abhishek@aurabrain.com',
          'device_count': 4,
          'online_device_count': 3,
        },
      });

      fakeApi.setResponse(ApiEndpoints.clientHomes(validUuid), {
        'success': true,
        'data': [
          {'id': 'home-1', 'name': 'Smart Villa'},
        ],
      });

      await profileProvider.loadProfile(clientId: validUuid);

      expect(profileProvider.profile, isNotNull);
      expect(profileProvider.profile!.name, equals('Abhishek Verma'));
      expect(profileProvider.deviceCount, equals(4));
      expect(profileProvider.onlineDeviceCount, equals(3));
      expect(profileProvider.onlineRatio, equals(0.75));
      expect(profileProvider.homes.length, equals(1));
      expect(profileProvider.activeHome?.name, equals('Smart Villa'));
      expect(fakeApi.requestedPaths, contains('/api/v1/clients/$validUuid'));
      expect(
        fakeApi.requestedPaths,
        contains('/api/v1/clients/$validUuid/homes'),
      );
    });

    test(
      'selectAvatar updates selected avatar ID and saves to SharedPreferences',
      () async {
        expect(
          profileProvider.selectedAvatarId,
          equals(ProfileProvider.defaultAvatarId),
        );

        await profileProvider.selectAvatar('fire_safety');

        expect(profileProvider.selectedAvatarId, equals('fire_safety'));
        expect(profileProvider.currentAvatar.name, equals('Pyro'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('smart_homz_avatar_id'), equals('fire_safety'));
      },
    );
  });

  group('5. ProfileScreen Dark Theme Widget Tests', () {
    late AuthProvider authProvider;
    late ProfileProvider profileProvider;
    late DeviceProvider deviceProvider;
    late PropertyProvider propertyProvider;
    late ThemeProvider themeProvider;
    const validUuid = 'df0df9e3-0e47-4d46-810e-3c4f5c267d69';

    setUp(() {
      authProvider = AuthProvider();
      authProvider.setUserForTesting(
        AppUser(
          id: validUuid,
          name: 'Abhishek Verma',
          email: 'abhishek@aurabrain.com',
          phone: '+919876543210',
          role: UserRole.superAdmin,
          tenantId: 'aurabrain',
          avatarInitials: 'AV',
          towerId: 'Tower A',
          flatId: '101',
        ),
        clientId: validUuid,
      );

      profileProvider = ProfileProvider();
      profileProvider.setProfileForTesting(
        profile: const ClientProfile(
          id: validUuid,
          name: 'Abhishek Verma',
          email: 'abhishek@aurabrain.com',
          phone: '+919876543210',
          timezone: 'Asia/Kolkata',
          deviceCount: 4,
          onlineDeviceCount: 3,
          permissionLevel: 'read_write',
        ),
        homes: [HomeModel(id: 'home-1', name: 'Greenwood Villa')],
        deviceCount: 4,
        onlineDeviceCount: 3,
        floorCount: 2,
        roomCount: 6,
      );

      deviceProvider = DeviceProvider(repository: MemoryDeviceRepository());
      propertyProvider = PropertyProvider(
        repository: MemoryPropertyRepository(),
      );
      themeProvider = ThemeProvider(initialMode: ThemeMode.dark);
    });

    Widget createDarkWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
          ChangeNotifierProvider<PropertyProvider>.value(
            value: propertyProvider,
          ),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const ProfileScreen(),
        ),
      );
    }

    testWidgets(
      'renders Profile Hero in Dark theme with name, email, badges and online counter',
      (tester) async {
        await tester.pumpWidget(createDarkWidgetUnderTest());
        await tester.pumpAndSettle();

        // Scaffold background is #10151A
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFF10151A)));

        // Hero section
        expect(find.byType(ProfileHero), findsOneWidget);
        expect(find.text('Abhishek Verma'), findsWidgets);
        expect(find.text('abhishek@aurabrain.com'), findsWidgets);
        expect(find.text('3 / 4 DEVICES ONLINE'), findsOneWidget);
        expect(find.text('Super Admin'), findsWidgets);
        expect(find.text('READ_WRITE'), findsOneWidget);
        expect(find.text('Customize Profile'), findsOneWidget);

        // Verify no raw UUID is exposed in the UI
        expect(find.text(validUuid), findsNothing);
        expect(find.textContaining('df0df9e3'), findsNothing);

        // Verify no fake Plus Plan is fabricated
        expect(find.text('Plus Plan'), findsNothing);
      },
    );

    testWidgets(
      'renders 3 stat tiles with real device, online, and home counts',
      (tester) async {
        await tester.pumpWidget(createDarkWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(ProfileStats), findsOneWidget);
        expect(find.text('DEVICES'), findsOneWidget);
        expect(find.text('ONLINE'), findsOneWidget);
        expect(find.text('HOMES'), findsOneWidget);
        expect(find.text('4'), findsOneWidget); // devices
        expect(find.text('3'), findsOneWidget); // online
        expect(find.text('1'), findsOneWidget); // homes
      },
    );

    testWidgets('renders My Home card without exposing street address', (
      tester,
    ) async {
      await tester.pumpWidget(createDarkWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ProfileHomeCard), findsOneWidget);
      expect(find.text('MY HOME'), findsOneWidget);
      expect(find.text('Greenwood Villa'), findsOneWidget);
      expect(find.textContaining('floors'), findsOneWidget);
      expect(find.textContaining('rooms'), findsOneWidget);

      // Verify street address from HTML example is NOT present
      expect(find.text('Sector 62, Noida'), findsNothing);
    });

    testWidgets(
      'renders Account Details and Preferences sections in Dark theme',
      (tester) async {
        await tester.pumpWidget(createDarkWidgetUnderTest());
        await tester.pumpAndSettle();

        final accountDetailsFinder = find.text('ACCOUNT DETAILS');
        await tester.scrollUntilVisible(accountDetailsFinder, 200);
        expect(accountDetailsFinder, findsOneWidget);
        expect(find.text('+919876543210'), findsOneWidget);
        expect(find.text('Asia/Kolkata'), findsOneWidget);

        final preferencesFinder = find.text('PREFERENCES');
        await tester.scrollUntilVisible(preferencesFinder, 200);
        expect(preferencesFinder, findsOneWidget);
        expect(find.text('Theme'), findsOneWidget);
        expect(find.text('°C (Metric)'), findsOneWidget);
        expect(find.text('English (US)'), findsOneWidget);

        final supportFinder = find.text('SUPPORT & LEGAL');
        await tester.scrollUntilVisible(supportFinder, 200);
        expect(supportFinder, findsOneWidget);
        expect(find.text('Privacy & Terms'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Logout button and opens dark confirmation dialog on press',
      (tester) async {
        await tester.pumpWidget(createDarkWidgetUnderTest());
        await tester.pumpAndSettle();

        final logoutButtonFinder = find.byType(ProfileLogoutButton);
        await tester.scrollUntilVisible(logoutButtonFinder, 200);
        expect(logoutButtonFinder, findsOneWidget);

        final logoutFinder = find.widgetWithText(OutlinedButton, 'Log Out');
        expect(logoutFinder, findsOneWidget);

        await tester.tap(logoutFinder);
        await tester.pumpAndSettle();

        expect(find.text('Log out?'), findsOneWidget);
        expect(
          find.text(
            "You'll need to sign in again to access your Smart Homz account.",
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping avatar opens AvatarPickerSheet modal', (tester) async {
      await tester.pumpWidget(createDarkWidgetUnderTest());
      await tester.pumpAndSettle();

      final avatarRing = find.byType(AvatarProgressRing);
      expect(avatarRing, findsOneWidget);

      await tester.tap(avatarRing);
      await tester.pumpAndSettle();

      expect(find.byType(AvatarPickerSheet), findsOneWidget);
      expect(find.text('Choose Companion'), findsOneWidget);
      expect(find.text('Neo'), findsOneWidget);
      expect(find.text('Aura'), findsOneWidget);
      expect(find.text('Pyro'), findsOneWidget);
    });
  });

  group('6. ProfileScreen Light Theme & Dynamic Switching Tests', () {
    late AuthProvider authProvider;
    late ProfileProvider profileProvider;
    late DeviceProvider deviceProvider;
    late PropertyProvider propertyProvider;
    late ThemeProvider themeProvider;
    const validUuid = 'df0df9e3-0e47-4d46-810e-3c4f5c267d69';

    setUp(() {
      authProvider = AuthProvider();
      authProvider.setUserForTesting(
        AppUser(
          id: validUuid,
          name: 'Abhishek Verma',
          email: 'abhishek@aurabrain.com',
          phone: '+919876543210',
          role: UserRole.resident,
          tenantId: 'aurabrain',
          avatarInitials: 'AV',
          towerId: 'Tower B',
          flatId: '202',
        ),
        clientId: validUuid,
      );

      profileProvider = ProfileProvider();
      profileProvider.setProfileForTesting(
        profile: const ClientProfile(
          id: validUuid,
          name: 'Abhishek Verma',
          email: 'abhishek@aurabrain.com',
          phone: '+919876543210',
          timezone: 'Asia/Kolkata',
          deviceCount: 6,
          onlineDeviceCount: 5,
          permissionLevel: 'read',
        ),
        homes: [HomeModel(id: 'home-1', name: 'Sunnyvale Residence')],
        deviceCount: 6,
        onlineDeviceCount: 5,
        floorCount: 1,
        roomCount: 4,
      );

      deviceProvider = DeviceProvider(repository: MemoryDeviceRepository());
      propertyProvider = PropertyProvider(
        repository: MemoryPropertyRepository(),
      );
      themeProvider = ThemeProvider(initialMode: ThemeMode.light);
    });

    Widget createLightWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
          ChangeNotifierProvider<PropertyProvider>.value(
            value: propertyProvider,
          ),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          home: const ProfileScreen(),
        ),
      );
    }

    testWidgets(
      'renders Profile screen with Light theme palette (#F5FAF9 background, Light label)',
      (tester) async {
        await tester.pumpWidget(createLightWidgetUnderTest());
        await tester.pumpAndSettle();

        // Scaffold background is #F5FAF9
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFFF5FAF9)));

        // Hero section shows dynamic counts and role
        expect(find.text('5 / 6 DEVICES ONLINE'), findsOneWidget);
        expect(find.text('Resident'), findsWidgets);
        expect(find.text('READ'), findsOneWidget);
        expect(find.text('Sunnyvale Residence'), findsOneWidget);

        final preferencesFinder = find.text('PREFERENCES');
        await tester.scrollUntilVisible(preferencesFinder, 200);
        expect(preferencesFinder, findsOneWidget);
        expect(find.text('Light Mode'), findsOneWidget);
      },
    );

    testWidgets(
      'switches dynamically between Dark and Light mode without losing state',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<ProfileProvider>.value(
                value: profileProvider,
              ),
              ChangeNotifierProvider<DeviceProvider>.value(
                value: deviceProvider,
              ),
              ChangeNotifierProvider<PropertyProvider>.value(
                value: propertyProvider,
              ),
              ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ],
            child: Consumer<ThemeProvider>(
              builder: (context, tp, child) {
                return MaterialApp(
                  theme: ThemeData.light(),
                  darkTheme: ThemeData.dark(),
                  themeMode: tp.themeMode,
                  home: const ProfileScreen(),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial Light Mode
        var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFFF5FAF9)));
        expect(find.text('5 / 6 DEVICES ONLINE'), findsOneWidget);

        // 2. Switch to Dark Mode
        await themeProvider.setThemeMode(ThemeMode.dark);
        await tester.pumpAndSettle();

        scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFF10151A)));
        expect(find.text('5 / 6 DEVICES ONLINE'), findsOneWidget);
        expect(find.text('Abhishek Verma'), findsWidgets);

        // 3. Switch back to Light Mode
        await themeProvider.setThemeMode(ThemeMode.light);
        await tester.pumpAndSettle();

        scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFFF5FAF9)));
      },
    );
  });
}
