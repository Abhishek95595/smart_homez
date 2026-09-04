import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_homez/models/device.dart';
import 'package:smart_homez/models/scene_model.dart';
import 'package:smart_homez/providers/alert_provider.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/device_provider.dart';
import 'package:smart_homez/providers/property_provider.dart';
import 'package:smart_homez/providers/scene_provider.dart';
import 'package:smart_homez/screens/scenes/scenes_screen.dart';
import 'package:smart_homez/services/device_repository.dart';
import 'package:smart_homez/services/property_repository.dart';
import 'package:smart_homez/services/scene_service.dart';
import 'package:smart_homez/theme/app_theme.dart';
import 'package:smart_homez/widgets/app_navigation_drawer.dart';

import 'package:smart_homez/models/property_hierarchy.dart';

class FakePropertyRepository implements PropertyRepository {
  @override
  Future<PropertySnapshot> load() async => const PropertySnapshot(
    properties: [
      ManagedProperty(
        id: 'test-client-id',
        name: 'My Home',
        address: '123 Smart St',
      ),
    ],
    floors: [],
    rooms: [],
  );

  @override
  Future<void> save(PropertySnapshot snapshot) async {}
}

class FakeSceneServiceForWidget implements SceneService {
  List<SceneModel> mockScenes = [
    SceneModel(
      id: 's_1',
      name: 'Movie Night',
      icon: 'film',
      isFavorite: true,
      actions: [
        SceneActionModel(deviceId: 'd_1', command: 'on'),
        SceneActionModel(
          deviceId: 'd_2',
          command: 'brightness',
          commandValue: 20,
        ),
      ],
    ),
    SceneModel(
      id: 's_2',
      name: 'Good Morning',
      icon: 'sun',
      isFavorite: false,
      isScheduleEnabled: true,
      scheduledTime: '07:00',
      actions: [SceneActionModel(deviceId: 'd_3', command: 'on')],
    ),
  ];

  @override
  Future<List<SceneModel>> getScenes(String clientId) async =>
      List.from(mockScenes);

  @override
  Future<SceneModel?> createScene(
    String clientId, {
    String? tenantId,
    required String name,
    String? description,
    String? icon,
    bool isFavorite = false,
    required List<SceneActionModel> actions,
    int recurrenceDays = 0,
    String? scheduledTime,
    int timezoneOffsetMinutes = 330,
    bool isScheduleEnabled = false,
    String? requestId,
  }) async {
    final created = SceneModel(
      id: 's_${mockScenes.length + 1}',
      name: name,
      description: description,
      icon: icon,
      isFavorite: isFavorite,
      actions: actions,
      recurrenceDays: recurrenceDays,
      scheduledTime: scheduledTime,
      timezoneOffsetMinutes: timezoneOffsetMinutes,
      isScheduleEnabled: isScheduleEnabled,
    );
    mockScenes.insert(0, created);
    return created;
  }

  @override
  Future<SceneModel?> updateScene(
    String clientId, {
    required String sceneId,
    String? tenantId,
    String? name,
    String? description,
    String? icon,
    bool? isFavorite,
    List<SceneActionModel>? actions,
    int? recurrenceDays,
    String? scheduledTime,
    int? timezoneOffsetMinutes,
    bool? isScheduleEnabled,
    String? requestId,
  }) async {
    final index = mockScenes.indexWhere((s) => s.id == sceneId);
    if (index == -1) return null;
    final old = mockScenes[index];
    final updated = SceneModel(
      id: old.id,
      tenantId: tenantId ?? old.tenantId,
      clientId: clientId,
      name: name ?? old.name,
      description: description ?? old.description,
      icon: icon ?? old.icon,
      isFavorite: isFavorite ?? old.isFavorite,
      actions: actions ?? old.actions,
      recurrenceDays: recurrenceDays ?? old.recurrenceDays,
      scheduledTime: scheduledTime ?? old.scheduledTime,
      timezoneOffsetMinutes: timezoneOffsetMinutes ?? old.timezoneOffsetMinutes,
      isScheduleEnabled: isScheduleEnabled ?? old.isScheduleEnabled,
    );
    mockScenes[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteScene(String clientId, String sceneId) async {
    mockScenes.removeWhere((s) => s.id == sceneId);
    return true;
  }

  @override
  Future<bool> activateScene(String clientId, String sceneId) async => true;

  @override
  Future<SceneModel?> getScene(String clientId, String sceneId) async {
    return mockScenes.firstWhere((s) => s.id == sceneId);
  }

  @override
  Future<SceneExecutionStatus> getSceneStatus(
    String clientId,
    String sceneId,
  ) async {
    return SceneExecutionStatus.idle(sceneId: sceneId);
  }
}

class FakeDeviceRepository implements DeviceRepository {
  @override
  Future<List<Device>> load() async {
    return [
      Device(
        deviceId: 'd_1',
        type: DeviceType.light,
        name: 'Ceiling Light',
        firmwareVersion: '1.0',
        macAddress: 'AA:BB:CC:DD:EE:01',
        tenantId: 't1',
        buildingId: 'b1',
        zone: 'Living Room',
        roomName: 'Living Room',
        lastHeartbeat: DateTime.now(),
      ),
      Device(
        deviceId: 'd_2',
        type: DeviceType.fan,
        name: 'Ceiling Fan',
        firmwareVersion: '1.0',
        macAddress: 'AA:BB:CC:DD:EE:02',
        tenantId: 't1',
        buildingId: 'b1',
        zone: 'Bedroom',
        roomName: 'Bedroom',
        lastHeartbeat: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> save(dynamic snapshot) async {}
}

class FakeAuthProvider extends AuthProvider {
  @override
  String? get resolvedClientUuid => 'test-client-id';
}

void main() {
  group('ScenesScreen Widget Tests', () {
    late FakeSceneServiceForWidget fakeService;
    late SceneProvider sceneProvider;
    late DeviceProvider deviceProvider;

    setUp(() {
      fakeService = FakeSceneServiceForWidget();
      sceneProvider = SceneProvider(sceneService: fakeService);
      deviceProvider = DeviceProvider(repository: FakeDeviceRepository());
    });

    Widget createWidgetUnderTest({ThemeData? theme}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => FakeAuthProvider(),
          ),
          ChangeNotifierProvider<PropertyProvider>(
            create: (_) =>
                PropertyProvider(repository: FakePropertyRepository()),
          ),
          ChangeNotifierProvider<AlertProvider>(create: (_) => AlertProvider()),
          ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
          ChangeNotifierProvider<SceneProvider>.value(value: sceneProvider),
        ],
        child: MaterialApp(
          theme: theme ?? ThemeData.light(),
          home: const ScenesScreen(),
        ),
      );
    }

    testWidgets('renders Scenes screen with hero and loaded scene cards', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Scenes'), findsOneWidget);
      expect(find.text('Your home, set in one tap.'), findsOneWidget);
      expect(find.text('My Scenes'), findsOneWidget);
      expect(find.text('Movie Night'), findsOneWidget);
      expect(find.text('Good Morning'), findsOneWidget);
    });

    testWidgets('search filters scenes list dynamically', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final searchFinder = find.byType(TextField);
      expect(searchFinder, findsOneWidget);

      await tester.enterText(searchFinder, 'Movie');
      await tester.pumpAndSettle();

      expect(find.text('Movie Night'), findsOneWidget);
      expect(find.text('Good Morning'), findsNothing);
    });

    testWidgets('tapping Create opens SceneEditorScreen', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final createBtn = find.text('Create');
      expect(createBtn, findsOneWidget);

      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Create Scene'), findsOneWidget);
      expect(find.text('SCENE SETUP'), findsOneWidget);
    });

    testWidgets('renders in Hasomi Light Theme mode without layout issues', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(theme: AppTheme.lightTheme),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
      expect(find.text('Movie Night'), findsOneWidget);
    });

    testWidgets('tapping hamburger menu icon opens AppNavigationDrawer', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final menuButton = find.byTooltip('Menu');
      expect(menuButton, findsOneWidget);

      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      expect(find.byType(AppNavigationDrawer), findsOneWidget);
      expect(find.text('Your Home. Smarter.'), findsOneWidget);
    });
  });
}
