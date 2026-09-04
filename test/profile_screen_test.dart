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
import 'package:smart_homez/providers/subscription_provider.dart';
import 'package:smart_homez/providers/tariff_provider.dart';
import 'package:smart_homez/screens/profile/profile_screen.dart';
import 'package:smart_homez/screens/profile/profile_theme.dart';
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
    Options? options,
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
    Options? options,
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
    test('verifies Light theme palette constants', () {
      const light = ProfileTheme.light;
      expect(light.background, equals(const Color(0xFFF8FBFB)));
      expect(light.panel, equals(const Color(0xFFFFFFFF)));
      expect(light.raised, equals(const Color(0xFFF7F9FA)));
      expect(light.secondarySurface, equals(const Color(0xFFE7F8F5)));
      expect(light.accent, equals(const Color(0xFF00A38E)));
      expect(light.accentSoft, equals(const Color(0xFFE7F8F5)));
      expect(light.warmAccent, equals(const Color(0xFFFFB020)));
      expect(light.textPrimary, equals(const Color(0xFF0F172A)));
      expect(light.textSecondary, equals(const Color(0xFF64748B)));
      expect(light.textTertiary, equals(const Color(0xFF94A3B8)));
      expect(light.border, equals(const Color(0xFFE8EEF0)));
      expect(light.danger, equals(const Color(0xFFE5484D)));
    });

    testWidgets('resolves light theme', (tester) async {
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
      expect(resolved.background, equals(const Color(0xFFF8FBFB)));
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
    const validUuid = '6782976c-e9a4-41c9-a754-05e4ba0a97b2';

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
    const validUuid = '6782976c-e9a4-41c9-a754-05e4ba0a97b2';

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

  group('6. ProfileScreen Light Theme & Dynamic Switching Tests', () {
    late AuthProvider authProvider;
    late ProfileProvider profileProvider;
    late DeviceProvider deviceProvider;
    late PropertyProvider propertyProvider;
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
          ChangeNotifierProvider<SubscriptionProvider>(
            create: (_) => SubscriptionProvider(),
          ),
          ChangeNotifierProvider<TariffProvider>(
            create: (_) => TariffProvider(),
          ),
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
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createLightWidgetUnderTest());
        await tester.pumpAndSettle();

        // Scaffold background is #F8FBFB
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFFF8FBFB)));

        // Hero section shows dynamic counts and role
        expect(find.text('5 / 6 DEVICES ONLINE'), findsOneWidget);
        expect(find.text('Resident'), findsWidgets);
        expect(find.text('READ'), findsOneWidget);
        final preferencesFinder = find.text('PREFERENCES');
        expect(preferencesFinder, findsOneWidget);
      },
    );
  });
}
