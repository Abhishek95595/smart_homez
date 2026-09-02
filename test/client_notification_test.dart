import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_homez/models/client_notification_model.dart';
import 'package:smart_homez/providers/auth_provider.dart';
import 'package:smart_homez/providers/client_notification_provider.dart';
import 'package:smart_homez/screens/notifications/notifications_inbox_screen.dart';
import 'package:smart_homez/services/client_notification_service.dart';
import 'package:smart_homez/widgets/notification_bell_button.dart';

class _FakeClientNotificationService extends Fake
    implements ClientNotificationService {
  final List<ClientNotification> mockItems;
  _FakeClientNotificationService(List<ClientNotification> items)
    : mockItems = items.map((e) => e.copyWith()).toList();

  @override
  Future<List<ClientNotification>> fetchNotifications({
    required String clientId,
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
  }) async {
    if (unreadOnly == true) {
      return mockItems.where((n) => !n.isRead).toList();
    }
    return List<ClientNotification>.from(mockItems);
  }

  @override
  Future<int> getUnreadCount(String clientId) async {
    return mockItems.where((n) => !n.isRead).length;
  }

  @override
  Future<bool> markAsRead({
    required String clientId,
    required String notificationId,
  }) async {
    final idx = mockItems.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      mockItems[idx] = mockItems[idx].copyWith(isRead: true);
    }
    return true;
  }

  @override
  Future<bool> markAllAsRead(String clientId) async {
    for (int i = 0; i < mockItems.length; i++) {
      mockItems[i] = mockItems[i].copyWith(isRead: true);
    }
    return true;
  }

  @override
  Future<bool> deleteNotification({
    required String clientId,
    required String notificationId,
  }) async {
    mockItems.removeWhere((n) => n.id == notificationId);
    return true;
  }

  @override
  Future<bool> clearAll(String clientId) async {
    mockItems.clear();
    return true;
  }

  @override
  Future<bool> registerPushToken({
    required String clientId,
    required String token,
    String platform = 'android',
  }) async => true;
}

Widget _buildTestApp({
  required Widget child,
  required ClientNotificationProvider notifProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<ClientNotificationProvider>.value(
        value: notifProvider,
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

List<ClientNotification> _createSampleNotifications() => [
  ClientNotification(
    id: 'notif_1',
    clientId: 'client_123',
    title: 'Smoke Sensor Activated',
    message: 'Smoke detector detected high smoke density in Living Room.',
    category: NotificationCategory.critical,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
  ClientNotification(
    id: 'notif_2',
    clientId: 'client_123',
    title: 'Plan Expiring Soon',
    message: 'Your Premium Automation package renews in 3 days.',
    category: NotificationCategory.plan,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  ClientNotification(
    id: 'notif_3',
    clientId: 'client_123',
    title: 'Device Online',
    message: 'Living Room Smart Hub reconnected successfully.',
    category: NotificationCategory.general,
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

void main() {
  group('ClientNotification Model Tests', () {
    test('fromJson deserializes standard tenant api payload', () {
      final json = {
        'id': 'notif_abc',
        'clientId': 'client_999',
        'title': 'Gas Leak Warning',
        'body': 'Gas sensor triggered alert in Kitchen.',
        'type': 'critical_safety',
        'isRead': false,
        'createdAt': '2026-08-28T12:00:00Z',
      };

      final notif = ClientNotification.fromJson(json);
      expect(notif.id, 'notif_abc');
      expect(notif.clientId, 'client_999');
      expect(notif.title, 'Gas Leak Warning');
      expect(notif.message, 'Gas sensor triggered alert in Kitchen.');
      expect(notif.category, NotificationCategory.critical);
      expect(notif.isRead, isFalse);
    });

    test('toJson serializes correctly', () {
      final notif = _createSampleNotifications()[0];
      final json = notif.toJson();
      expect(json['id'], 'notif_1');
      expect(json['clientId'], 'client_123');
      expect(json['title'], 'Smoke Sensor Activated');
      expect(json['isRead'], isFalse);
    });
  });

  group('ClientNotificationProvider Unit Tests', () {
    test('fetchNotifications loads items and sets unreadCount', () async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);

      await provider.fetchNotifications(clientId: 'client_123', refresh: true);

      expect(provider.notifications.length, 3);
      expect(provider.unreadCount, 2);
    });

    test('markAsRead updates state and decrements unreadCount', () async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);

      await provider.fetchNotifications(clientId: 'client_123', refresh: true);
      expect(provider.unreadCount, 2);

      await provider.markAsRead(
        clientId: 'client_123',
        notificationId: 'notif_1',
      );

      expect(
        provider.notifications.firstWhere((n) => n.id == 'notif_1').isRead,
        isTrue,
      );
      expect(provider.unreadCount, 1);
    });

    test('markAllAsRead marks all read and resets unreadCount to 0', () async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);

      await provider.fetchNotifications(clientId: 'client_123', refresh: true);
      expect(provider.unreadCount, 2);

      await provider.markAllAsRead(clientId: 'client_123');

      expect(provider.notifications.every((n) => n.isRead), isTrue);
      expect(provider.unreadCount, 0);
    });

    test('deleteNotification removes item', () async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);

      await provider.fetchNotifications(clientId: 'client_123', refresh: true);
      expect(provider.notifications.length, 3);

      await provider.deleteNotification(
        clientId: 'client_123',
        notificationId: 'notif_2',
      );

      expect(provider.notifications.length, 2);
      expect(provider.notifications.any((n) => n.id == 'notif_2'), isFalse);
    });

    test('clearAll empties list and resets unreadCount', () async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);

      await provider.fetchNotifications(clientId: 'client_123', refresh: true);
      expect(provider.notifications.length, 3);

      await provider.clearAll(clientId: 'client_123');

      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
    });
  });

  group('NotificationBellButton Widget Tests', () {
    testWidgets('Renders badge with unread count when unreadCount > 0', (
      tester,
    ) async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);
      await provider.fetchNotifications(clientId: 'client_123', refresh: true);

      await tester.pumpWidget(
        _buildTestApp(
          child: const NotificationBellButton(),
          notifProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Hides badge when unreadCount is 0', (tester) async {
      final fakeService = _FakeClientNotificationService([]);
      final provider = ClientNotificationProvider(service: fakeService);

      await tester.pumpWidget(
        _buildTestApp(
          child: const NotificationBellButton(),
          notifProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('Tapping bell button opens NotificationsInboxScreen', (
      tester,
    ) async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);
      await provider.fetchNotifications(clientId: 'client_123', refresh: true);

      await tester.pumpWidget(
        _buildTestApp(
          child: const NotificationBellButton(),
          notifProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Smoke Sensor Activated'), findsOneWidget);
    });
  });

  group('NotificationsInboxScreen Widget Tests', () {
    testWidgets('Renders notification list and filter tabs', (tester) async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);
      await provider.fetchNotifications(clientId: 'client_123', refresh: true);

      await tester.pumpWidget(
        _buildTestApp(
          child: const NotificationsInboxScreen(),
          notifProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All Alerts'), findsOneWidget);
      expect(find.text('Unread Only'), findsOneWidget);
      expect(find.text('Smoke Sensor Activated'), findsOneWidget);
      expect(find.text('Plan Expiring Soon'), findsOneWidget);
      expect(find.text('Device Online'), findsOneWidget);
    });

    testWidgets('Tapping notification tile marks as read', (tester) async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);
      await provider.fetchNotifications(clientId: 'client_123', refresh: true);

      await tester.pumpWidget(
        _buildTestApp(
          child: const NotificationsInboxScreen(),
          notifProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.unreadCount, 2);

      await tester.tap(find.text('Smoke Sensor Activated'));
      await tester.pumpAndSettle();

      expect(provider.unreadCount, 1);
    });

    testWidgets('Switching to Unread Only filters read notifications', (
      tester,
    ) async {
      final fakeService = _FakeClientNotificationService(
        _createSampleNotifications(),
      );
      final provider = ClientNotificationProvider(service: fakeService);
      await provider.fetchNotifications(clientId: 'client_123', refresh: true);

      await tester.pumpWidget(
        _buildTestApp(
          child: const NotificationsInboxScreen(),
          notifProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Unread Only tab
      await tester.tap(find.text('Unread Only'));
      await tester.pumpAndSettle();

      expect(find.text('Smoke Sensor Activated'), findsOneWidget);
      expect(find.text('Plan Expiring Soon'), findsOneWidget);
      expect(find.text('Device Online'), findsNothing);
    });
  });
}
