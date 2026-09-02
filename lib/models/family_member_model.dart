class FamilyDevicePermissionEntry {
  final String deviceId;
  final String? deviceName;
  final bool canView;
  final bool canControl;

  const FamilyDevicePermissionEntry({
    required this.deviceId,
    this.deviceName,
    this.canView = true,
    this.canControl = true,
  });

  factory FamilyDevicePermissionEntry.fromJson(Map<String, dynamic> json) {
    return FamilyDevicePermissionEntry(
      deviceId:
          json['deviceId']?.toString() ??
          json['id']?.toString() ??
          json['device_id']?.toString() ??
          '',
      deviceName:
          json['deviceName']?.toString() ??
          json['name']?.toString() ??
          json['device_name']?.toString(),
      canView:
          json['canView'] == true ||
          json['can_view'] == true ||
          json['canView'] == null,
      canControl:
          json['canControl'] == true ||
          json['can_control'] == true ||
          json['canControl'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'deviceId': deviceId, 'canView': canView, 'canControl': canControl};
  }

  FamilyDevicePermissionEntry copyWith({
    String? deviceId,
    String? deviceName,
    bool? canView,
    bool? canControl,
  }) {
    return FamilyDevicePermissionEntry(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      canView: canView ?? this.canView,
      canControl: canControl ?? this.canControl,
    );
  }
}

class FamilyMember {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String role; // 'admin', 'member', 'viewer'
  final String status; // 'pending', 'joined', 'active', 'invited'
  final DateTime? createdAt;
  final DateTime? joinedAt;
  final DateTime? lastPresence;
  final String? presenceStatus;
  final List<FamilyDevicePermissionEntry> permissions;
  final bool allDevicesGranted;

  const FamilyMember({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.role = 'member',
    this.status = 'pending',
    this.createdAt,
    this.joinedAt,
    this.lastPresence,
    this.presenceStatus,
    this.permissions = const [],
    this.allDevicesGranted = true,
  });

  bool get isPending =>
      status.toLowerCase() == 'pending' || status.toLowerCase() == 'invited';
  bool get isActive =>
      status.toLowerCase() == 'joined' ||
      status.toLowerCase() == 'active' ||
      status.toLowerCase() == 'accepted';
  bool get isAdmin =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'owner';

  String get roleDisplay {
    if (isAdmin) return 'Admin';
    if (role.toLowerCase() == 'viewer') return 'Viewer';
    return 'Member';
  }

  String get statusDisplay {
    if (isActive) return 'Active';
    if (isPending) return 'Pending Invite';
    return status.toUpperCase();
  }

  String get presenceDisplay {
    if (presenceStatus != null && presenceStatus!.trim().isNotEmpty) {
      return presenceStatus!.trim();
    }
    if (lastPresence != null) {
      final now = DateTime.now();
      final diff = now.difference(lastPresence!);
      if (diff.isNegative || diff.inMinutes < 5) {
        return 'Active now';
      } else if (diff.inMinutes < 60) {
        return 'Active ${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return 'Active ${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return 'Active ${diff.inDays}d ago';
      } else {
        return 'Active on ${lastPresence!.day}/${lastPresence!.month}/${lastPresence!.year}';
      }
    }
    if (isPending) {
      return 'Invitation Sent';
    }
    return 'Offline';
  }

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email!.trim();
    }
    if (phone != null && phone!.trim().isNotEmpty) {
      return phone!.trim();
    }
    return 'Family Member';
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    List<FamilyDevicePermissionEntry> parsedPermissions = [];
    final dynamic rawPermissions =
        json['permissions'] ??
        json['devicePermissions'] ??
        json['device_permissions'];
    if (rawPermissions is List) {
      parsedPermissions = rawPermissions
          .whereType<Map>()
          .map(
            (item) => FamilyDevicePermissionEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is DateTime) return date;
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return null;
      }
    }

    // Parse presence
    DateTime? parsedPresence = parseDate(
      json['lastPresence'] ??
          json['last_presence'] ??
          json['lastSeenAt'] ??
          json['last_seen_at'] ??
          json['lastActive'] ??
          json['last_active'],
    );

    String? statusPresence;
    if (json['presence'] is String) {
      statusPresence = json['presence'].toString();
    } else if (json['presence'] is Map) {
      final pMap = Map<String, dynamic>.from(json['presence'] as Map);
      statusPresence = pMap['status']?.toString();
      parsedPresence ??= parseDate(pMap['lastSeenAt'] ?? pMap['timestamp']);
    }

    final parsedStatus =
        json['status']?.toString() ??
        json['joinStatus']?.toString() ??
        json['inviteStatus']?.toString() ??
        (json['isJoined'] == true ? 'joined' : 'pending');

    return FamilyMember(
      id:
          json['id']?.toString() ??
          json['memberId']?.toString() ??
          json['userId']?.toString() ??
          json['_id']?.toString() ??
          '',
      name:
          json['name']?.toString() ??
          json['fullName']?.toString() ??
          json['displayName']?.toString(),
      phone:
          json['phone']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['contactPhone']?.toString(),
      email: json['email']?.toString() ?? json['contactEmail']?.toString(),
      role:
          json['role']?.toString() ??
          json['roleType']?.toString() ??
          json['accessLevel']?.toString() ??
          'member',
      status: parsedStatus,
      createdAt: parseDate(
        json['createdAt'] ??
            json['created_at'] ??
            json['invitedAt'] ??
            json['invited_at'],
      ),
      joinedAt: parseDate(json['joinedAt'] ?? json['joined_at']),
      lastPresence: parsedPresence,
      presenceStatus: statusPresence,
      permissions: parsedPermissions,
      allDevicesGranted:
          json['allDevicesGranted'] == true ||
          (parsedPermissions.isEmpty && json['hasAllAccess'] != false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'joinedAt': joinedAt?.toIso8601String(),
      'lastPresence': lastPresence?.toIso8601String(),
      'presenceStatus': presenceStatus,
      'permissions': permissions.map((p) => p.toJson()).toList(),
      'allDevicesGranted': allDevicesGranted,
    };
  }

  FamilyMember copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? status,
    DateTime? createdAt,
    DateTime? joinedAt,
    DateTime? lastPresence,
    String? presenceStatus,
    List<FamilyDevicePermissionEntry>? permissions,
    bool? allDevicesGranted,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      joinedAt: joinedAt ?? this.joinedAt,
      lastPresence: lastPresence ?? this.lastPresence,
      presenceStatus: presenceStatus ?? this.presenceStatus,
      permissions: permissions ?? this.permissions,
      allDevicesGranted: allDevicesGranted ?? this.allDevicesGranted,
    );
  }
}
