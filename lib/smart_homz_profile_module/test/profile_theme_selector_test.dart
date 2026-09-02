import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_homez/models/app_user.dart';
import 'package:smart_homez/models/client_profile.dart';
import 'package:smart_homez/models/user_role.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/profile_provider.dart';
import 'package:smart_homez/providers/property_provider.dart';
import 'package:smart_homez/providers/theme_provider.dart';
import 'package:smart_homez/screens/profile/profile_screen.dart';
import 'package:smart_homez/services/device_repository.dart';
import 'package:smart_homez/services/property_repository.dart';
import 'package:smart_homez/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider Unit Tests', () {
    test('initializes with ThemeMode.light and themeName Light', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.isDarkMode, isFalse);
      expect(provider.themeName, equals('Light'));
    });

    test(
      'setThemeMode updates state and persists to SharedPreferences',
      () async {
        final provider = ThemeProvider();

        await provider.setThemeMode(ThemeMode.dark);
        expect(provider.themeMode, equals(ThemeMode.dark));
        expect(provider.isDarkMode, isTrue);
        expect(provider.themeName, equals('Dark'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), equals('dark'));

        await provider.setThemeMode(ThemeMode.light);
        expect(provider.themeMode, equals(ThemeMode.light));
        expect(provider.isDarkMode, isFalse);
        expect(provider.themeName, equals('Light'));
        expect(prefs.getString('theme_mode'), equals('light'));
      },
    );

    test(
      'loadThemePreference restores saved preference from SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

        final provider = ThemeProvider();
        await provider.loadThemePreference();

        expect(provider.themeMode, equals(ThemeMode.dark));
        expect(provider.isDarkMode, isTrue);
        expect(provider.themeName, equals('Dark'));
      },
    );

    test('toggleTheme alternates between Light and Dark', () async {
      final provider = ThemeProvider();
      expect(provider.themeMode, equals(ThemeMode.light));

      await provider.toggleTheme();
      expect(provider.themeMode, equals(ThemeMode.dark));

      await provider.toggleTheme();
      expect(provider.themeMode, equals(ThemeMode.light));
    });
  });

  group('Profile Screen Theme Preference Widget Tests', () {
    late AuthProvider authProvider;
    late ThemeProvider themeProvider;
    late ProfileProvider profileProvider;
    late DeviceProvider deviceProvider;
    late PropertyProvider propertyProvider;

    setUp(() {
      authProvider = AuthProvider();
      authProvider.setUserForTesting(
        AppUser(
          id: 'user-1',
          name: 'Abhishek Verma',
          email: 'abhishek@aurabrain.com',
          phone: '+919876543210',
          role: UserRole.superAdmin,
          tenantId: 'aurabrain',
          avatarInitials: 'AV',
          towerId: 'Tower A',
          flatId: '101',
        ),
        clientId: 'df0df9e3-0e47-4d46-810e-3c4f5c267d69',
      );

      themeProvider = ThemeProvider();
      profileProvider = ProfileProvider();
      profileProvider.setProfileForTesting(
        profile: const ClientProfile(
          id: 'df0df9e3-0e47-4d46-810e-3c4f5c267d69',
          name: 'Abhishek Verma',
          email: 'abhishek@aurabrain.com',
          phone: '+919876543210',
          timezone: 'Asia/Kolkata',
          deviceCount: 4,
          onlineDeviceCount: 3,
        ),
      );
      deviceProvider = DeviceProvider(repository: MemoryDeviceRepository());
      propertyProvider = PropertyProvider(
        repository: MemoryPropertyRepository(),
      );
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
          ChangeNotifierProvider<PropertyProvider>.value(
            value: propertyProvider,
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, tp, child) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: tp.themeMode,
              home: const ProfileScreen(),
            );
          },
        ),
      );
    }

    testWidgets('renders Profile Screen with Preferences -> Theme row', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets(
      'selecting Dark switches app theme to Dark immediately without restart',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Initial state is Light
        expect(themeProvider.themeMode, equals(ThemeMode.light));

        // Tap 'Dark'
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        // ThemeProvider updated to Dark
        expect(themeProvider.themeMode, equals(ThemeMode.dark));
        expect(find.text('Dark Mode'), findsOneWidget);

        // Scaffold background updated to Dark theme (#10151A)
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFF10151A)));

        // Tap 'Light'
        await tester.tap(find.text('Light'));
        await tester.pumpAndSettle();

        // ThemeProvider updated to Light
        expect(themeProvider.themeMode, equals(ThemeMode.light));
        expect(find.text('Light Mode'), findsOneWidget);

        // Scaffold background updated to Light theme (#F5FAF9)
        final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(lightScaffold.backgroundColor, equals(const Color(0xFFF5FAF9)));
      },
    );

    testWidgets('theme selection persists across SharedPreferences', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 'Dark'
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), equals('dark'));
    });
  });
}
