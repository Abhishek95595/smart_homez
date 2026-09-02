import 'package:flutter/foundation.dart';

enum NotificationCategory {
  general,
  critical,
  plan,
  device,
  automation,
  system,
}

extension NotificationCategoryExtension on NotificationCategory {
  String get displayName {
    switch (this) {
      case NotificationCategory.general:
        return 'General';
      case NotificationCategory.critical:
        return 'Critical Safety';
      case NotificationCategory.plan:
        return 'Plan & Offers';
      case NotificationCategory.device:
        return 'Device Alert';
      case NotificationCategory.automation:
        return 'Automation';
      case NotificationCategory.system:
        return 'System';
    }
  }

  static NotificationCategory fromString(String? type) {
    if (type == null) return NotificationCategory.general;
    final lower = type.toLowerCase();
    if (lower.contains('crit') ||
        lower.contains('fire') ||
        lower.contains('gas') ||
        lower.contains('water') ||
        lower.contains('safety') ||
        lower.contains('leak')) {
      return NotificationCategory.critical;
    }
    if (lower.contains('plan') ||
        lower.contains('bill') ||
        lower.contains('subscrip') ||
        lower.contains('invoice') ||
        lower.contains('offer')) {
      return NotificationCategory.plan;
    }
    if (lower.contains('auto') || lower.contains('scene')) {
      return NotificationCategory.automation;
    }
    if (lower.contains('dev') || lower.contains('sensor')) {
      return NotificationCategory.device;
    }
    if (lower.contains('sys') || lower.contains('admin')) {
      return NotificationCategory.system;
    }
    return NotificationCategory.general;
  }
}

@immutable
class ClientNotification {
  final String id;
  final String? clientId;
  final String title;
  final String message;
  final NotificationCategory category;
  final String? rawType;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final String? deviceId;
  final String? homeId;
  final String? severity;

  const ClientNotification({
    required this.id,
    this.clientId,
    required this.title,
    required this.message,
    required this.category,
    this.rawType,
    required this.isRead,
    required this.createdAt,
    this.metadata,
    this.deviceId,
    this.homeId,
    this.severity,
  });

  ClientNotification copyWith({
    String? id,
    String? clientId,
    String? title,
    String? message,
    NotificationCategory? category,
    String? rawType,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    String? deviceId,
    String? homeId,
    String? severity,
  }) {
    return ClientNotification(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      rawType: rawType ?? this.rawType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      deviceId: deviceId ?? this.deviceId,
      homeId: homeId ?? this.homeId,
      severity: severity ?? this.severity,
    );
  }

  factory ClientNotification.fromJson(Map<String, dynamic> json) {
    final rawType =
        (json['type'] ?? json['category'] ?? json['notificationType'])
            ?.toString();
    final isReadVal =
        json['isRead'] ?? json['read'] ?? json['is_read'] ?? false;
    final createdAtStr =
        json['createdAt'] ??
        json['created_at'] ??
        json['timestamp'] ??
        json['date'];
    DateTime parsedDate;
    if (createdAtStr is String) {
      parsedDate = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final metadataMap = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : null;

    return ClientNotification(
      id: (json['id'] ?? json['notificationId'] ?? json['_id'] ?? '')
          .toString(),
      clientId: json['clientId']?.toString() ?? json['client_id']?.toString(),
      title: (json['title'] ?? json['subject'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['body'] ?? json['description'] ?? '')
          .toString(),
      category: NotificationCategoryExtension.fromString(rawType),
      rawType: rawType,
      isRead: isReadVal is bool
          ? isReadVal
          : (isReadVal.toString().toLowerCase() == 'true'),
      createdAt: parsedDate,
      metadata: metadataMap,
      deviceId: json['deviceId']?.toString() ?? json['device_id']?.toString(),
      homeId: json['homeId']?.toString() ?? json['home_id']?.toString(),
      severity: json['severity']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (clientId != null) 'clientId': clientId,
      'title': title,
      'message': message,
      'type': rawType ?? category.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (deviceId != null) 'deviceId': deviceId,
      if (homeId != null) 'homeId': homeId,
      if (severity != null) 'severity': severity,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isRead == other.isRead;

  @override
  int get hashCode => id.hashCode ^ isRead.hashCode;
}
