import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/client_notification_model.dart';

class ClientNotificationService {
  ClientNotificationService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Fetches paginated notification list for a client.
  Future<List<ClientNotification>> fetchNotifications({
    required String clientId,
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
  }) async {
    try {
      final endpoint = ApiEndpoints.clientNotifications(
        clientId,
        page: page,
        pageSize: pageSize,
        unreadOnly: unreadOnly,
      );

      final Response<dynamic> response = await _api.get(endpoint);
      final dynamic data = response.data;

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) =>
                  ClientNotification.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final list = map['data'] ?? map['items'] ?? map['notifications'];
        if (list is List) {
          return list
              .whereType<Map>()
              .map(
                (item) => ClientNotification.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }

      return const <ClientNotification>[];
    } catch (error) {
      debugPrint(
        '[ClientNotificationService] fetchNotifications error: $error',
      );
      rethrow;
    }
  }

  /// Fetches live unread notification count for a client.
  Future<int> getUnreadCount(String clientId) async {
    try {
      final endpoint = ApiEndpoints.clientNotificationsUnreadCount(clientId);
      final Response<dynamic> response = await _api.get(endpoint);
      final dynamic data = response.data;

      if (data is int) return data;
      if (data is num) return data.toInt();

      if (data is Map) {
        final count =
            data['count'] ??
            data['unreadCount'] ??
            data['unread_count'] ??
            data['data'];
        if (count is num) return count.toInt();
        if (count is String) return int.tryParse(count) ?? 0;
      }

      if (data is String) return int.tryParse(data) ?? 0;

      return 0;
    } catch (error) {
      debugPrint('[ClientNotificationService] getUnreadCount error: $error');
      return 0;
    }
  }

  /// Marks a single notification as read.
  Future<bool> markAsRead({
    required String clientId,
    required String notificationId,
  }) async {
    try {
      final endpoint = ApiEndpoints.clientNotificationRead(
        clientId,
        notificationId,
      );
      final Response<dynamic> response = await _api.post(endpoint);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (error) {
      debugPrint('[ClientNotificationService] markAsRead error: $error');
      return false;
    }
  }

  /// Marks all notifications as read for a client.
  Future<bool> markAllAsRead(String clientId) async {
    try {
      final endpoint = ApiEndpoints.clientNotificationsReadAll(clientId);
      final Response<dynamic> response = await _api.post(endpoint);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (error) {
      debugPrint('[ClientNotificationService] markAllAsRead error: $error');
      return false;
    }
  }

  /// Deletes a single notification.
  Future<bool> deleteNotification({
    required String clientId,
    required String notificationId,
  }) async {
    try {
      final endpoint = ApiEndpoints.clientNotificationDelete(
        clientId,
        notificationId,
      );
      final Response<dynamic> response = await _api.delete(endpoint);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (error) {
      debugPrint(
        '[ClientNotificationService] deleteNotification error: $error',
      );
      return false;
    }
  }

  /// Bulk clears all notifications for a client.
  Future<bool> clearAll(String clientId) async {
    try {
      final endpoint = ApiEndpoints.clientNotificationsClear(clientId);
      final Response<dynamic> response = await _api.post(endpoint);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (error) {
      debugPrint('[ClientNotificationService] clearAll error: $error');
      return false;
    }
  }

  /// Registers native device push token for push alerts.
  Future<bool> registerPushToken({
    required String clientId,
    required String token,
    String platform = 'android',
  }) async {
    try {
      final endpoint = ApiEndpoints.clientNotificationPushTokens(clientId);
      final Response<dynamic> response = await _api.post(
        endpoint,
        data: {'token': token, 'platform': platform},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (error) {
      debugPrint('[ClientNotificationService] registerPushToken error: $error');
      return false;
    }
  }
}
