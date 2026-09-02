import 'package:flutter/foundation.dart';

import '../models/client_notification_model.dart';
import '../services/client_notification_service.dart';

class ClientNotificationProvider extends ChangeNotifier {
  ClientNotificationProvider({ClientNotificationService? service})
    : _service = service ?? ClientNotificationService();

  final ClientNotificationService _service;

  List<ClientNotification> _notifications = <ClientNotification>[];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _unreadOnlyFilter = false;
  int _currentPage = 1;
  bool _hasMore = true;

  List<ClientNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get unreadOnlyFilter => _unreadOnlyFilter;
  bool get hasMore => _hasMore;

  List<ClientNotification> get filteredNotifications {
    if (_unreadOnlyFilter) {
      return _notifications.where((n) => !n.isRead).toList();
    }
    return _notifications;
  }

  void setUnreadOnlyFilter(bool unreadOnly, {String? clientId}) {
    if (_unreadOnlyFilter == unreadOnly) return;
    _unreadOnlyFilter = unreadOnly;
    notifyListeners();
    if (clientId != null && clientId.isNotEmpty) {
      fetchNotifications(clientId: clientId, refresh: true);
    }
  }

  /// Fetches notifications for client.
  Future<void> fetchNotifications({
    required String clientId,
    bool refresh = false,
  }) async {
    if (clientId.isEmpty) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _isRefreshing = true;
    } else {
      if (_isLoading || !_hasMore) return;
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _service.fetchNotifications(
        clientId: clientId,
        page: _currentPage,
        pageSize: 20,
        unreadOnly: _unreadOnlyFilter ? true : null,
      );

      if (refresh) {
        _notifications = items;
      } else {
        final existingIds = _notifications.map((n) => n.id).toSet();
        final newItems = items
            .where((n) => !existingIds.contains(n.id))
            .toList();
        _notifications.addAll(newItems);
      }

      if (items.length < 20) {
        _hasMore = false;
      } else {
        _currentPage++;
      }

      // Sync unread count
      _syncLocalUnreadCount();
      // Also fetch authoritative unread count
      await fetchUnreadCount(clientId: clientId);
    } catch (e) {
      debugPrint('[ClientNotificationProvider] fetchNotifications error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Fetches authoritative live unread count.
  Future<void> fetchUnreadCount({required String clientId}) async {
    if (clientId.isEmpty) return;
    try {
      final count = await _service.getUnreadCount(clientId);
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      debugPrint('[ClientNotificationProvider] fetchUnreadCount error: $e');
    }
  }

  /// Marks a single notification as read.
  Future<void> markAsRead({
    required String clientId,
    required String notificationId,
  }) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    if (clientId.isNotEmpty) {
      await _service.markAsRead(
        clientId: clientId,
        notificationId: notificationId,
      );
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead({required String clientId}) async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    if (clientId.isNotEmpty) {
      await _service.markAllAsRead(clientId);
    }
  }

  /// Deletes a notification.
  Future<void> deleteNotification({
    required String clientId,
    required String notificationId,
  }) async {
    final target = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => ClientNotification(
        id: '',
        title: '',
        message: '',
        category: NotificationCategory.general,
        isRead: true,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    if (target.id.isNotEmpty && !target.isRead && _unreadCount > 0) {
      _unreadCount--;
    }

    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();

    if (clientId.isNotEmpty) {
      await _service.deleteNotification(
        clientId: clientId,
        notificationId: notificationId,
      );
    }
  }

  /// Clears all notifications.
  Future<void> clearAll({required String clientId}) async {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();

    if (clientId.isNotEmpty) {
      await _service.clearAll(clientId);
    }
  }

  void _syncLocalUnreadCount() {
    final unreadLocal = _notifications.where((n) => !n.isRead).length;
    if (unreadLocal > _unreadCount) {
      _unreadCount = unreadLocal;
    }
  }
}
