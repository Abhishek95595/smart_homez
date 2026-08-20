import 'device.dart';

// ──────────────────────────────────────────────────
// ScheduleEntry — one device scheduled for one day
// ──────────────────────────────────────────────────

/// Represents a single scheduled device entry within a day.
/// Example: "Bedroom AC — ON at 10:00 PM, OFF at 6:00 AM"
class ScheduleEntry {
  final String id;
  final String deviceId;
  final String deviceName;
  final String roomId;
  final String roomName;
  final DeviceType deviceType;
  String onTime; // e.g. '10:00 PM'
  String offTime; // e.g. '6:00 AM'
  bool isEnabled;
  String startAction; // 'on' or 'off'
  Map<String, dynamic> customSettings;

  ScheduleEntry({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.roomId,
    required this.roomName,
    required this.deviceType,
    this.onTime = '07:00 AM',
    this.offTime = '09:30 AM',
    this.isEnabled = true,
    this.startAction = 'on',
    Map<String, dynamic>? customSettings,
  }) : customSettings = customSettings ?? {};

  // ── Convenience getters for custom settings ──
  int get brightness => (customSettings['brightness'] as num?)?.toInt() ?? 80;
  int get targetTemp => (customSettings['temperature'] as num?)?.toInt() ?? 24;
  int get fanSpeed => (customSettings['speed'] as num?)?.toInt() ?? 2;
  int get blindPercentage =>
      (customSettings['blindPercentage'] as num?)?.toInt() ?? 100;
  String get warmth => (customSettings['warmth'] as String?) ?? 'Warm 2700K';

  /// Human-readable summary for the card subtitle
  String get summaryDescription {
    if (!isEnabled) return 'Disabled';
    final timeRange = '$onTime → $offTime';
    if (startAction == 'off') return 'Turn OFF • $timeRange';

    if (deviceType == DeviceType.light) {
      return 'ON $brightness% • $warmth • $timeRange';
    }
    if (deviceType == DeviceType.ac) {
      return 'ON $targetTemp°C Cool • $timeRange';
    }
    if (deviceType == DeviceType.fan) {
      return 'ON Speed $fanSpeed • $timeRange';
    }
    final n = deviceName.toLowerCase();
    if (n.contains('curtain') || n.contains('blind')) {
      return 'Open $blindPercentage% • $timeRange';
    }
    return 'Turn ON • $timeRange';
  }

  ScheduleEntry copyWith({
    String? id,
    String? deviceId,
    String? deviceName,
    String? roomId,
    String? roomName,
    DeviceType? deviceType,
    String? onTime,
    String? offTime,
    bool? isEnabled,
    String? startAction,
    Map<String, dynamic>? customSettings,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      deviceType: deviceType ?? this.deviceType,
      onTime: onTime ?? this.onTime,
      offTime: offTime ?? this.offTime,
      isEnabled: isEnabled ?? this.isEnabled,
      startAction: startAction ?? this.startAction,
      customSettings:
          customSettings ?? Map<String, dynamic>.from(this.customSettings),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'roomId': roomId,
      'roomName': roomName,
      'deviceType': deviceType.name,
      'onTime': onTime,
      'offTime': offTime,
      'isEnabled': isEnabled,
      'startAction': startAction,
      'customSettings': customSettings,
    };
  }

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    DeviceType parseType(String? typeStr) {
      return DeviceType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => DeviceType.light,
      );
    }

    return ScheduleEntry(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: json['deviceId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? 'Device',
      roomId: json['roomId']?.toString() ?? 'room_default',
      roomName: json['roomName']?.toString() ?? 'Room',
      deviceType: parseType(json['deviceType']?.toString()),
      onTime: json['onTime']?.toString() ?? '07:00 AM',
      offTime: json['offTime']?.toString() ?? '09:30 AM',
      isEnabled: json['isEnabled'] as bool? ?? true,
      startAction: json['startAction']?.toString() ?? 'on',
      customSettings: json['customSettings'] is Map
          ? Map<String, dynamic>.from(json['customSettings'] as Map)
          : {},
    );
  }
}

// ──────────────────────────────────────────────────
// DaySchedule — all entries for a single day
// ──────────────────────────────────────────────────

/// Holds the list of [ScheduleEntry] for one day of the week.
class DaySchedule {
  final String day; // 'MON', 'TUE', etc.
  List<ScheduleEntry> entries;

  DaySchedule({required this.day, List<ScheduleEntry>? entries})
    : entries = entries ?? [];

  int get enabledCount => entries.where((e) => e.isEnabled).length;
  bool get isEmpty => entries.isEmpty;

  /// Deep-copy all entries to a new DaySchedule for a different day
  DaySchedule copyTo(String targetDay) {
    return DaySchedule(
      day: targetDay,
      entries: entries
          .map(
            (e) => e.copyWith(
              id: '${targetDay}_${e.deviceId}_${DateTime.now().millisecondsSinceEpoch}',
            ),
          )
          .toList(),
    );
  }

  DaySchedule copyWith({String? day, List<ScheduleEntry>? entries}) {
    return DaySchedule(
      day: day ?? this.day,
      entries: entries ?? this.entries.map((e) => e.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'entries': entries.map((e) => e.toJson()).toList()};
  }

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day']?.toString() ?? 'MON',
      entries: json['entries'] is List
          ? (json['entries'] as List)
                .map((item) {
                  if (item is Map) {
                    return ScheduleEntry.fromJson(
                      Map<String, dynamic>.from(item),
                    );
                  }
                  return null;
                })
                .whereType<ScheduleEntry>()
                .toList()
          : [],
    );
  }
}

// ──────────────────────────────────────────────────
// Routine — the top-level routine model
// ──────────────────────────────────────────────────

/// All 7 day codes in order
const List<String> kAllDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// Represents the Smart Home Routine automation (per-day scheduling).
class Routine {
  final String id;
  final String name;
  final String type;
  bool isEnabled;
  String timezone;
  Map<String, DaySchedule> daySchedules; // 'MON' -> DaySchedule
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastExecutedAt;

  Routine({
    required this.id,
    required this.name,
    this.type = 'morning_routine',
    this.isEnabled = true,
    this.timezone = 'UTC',
    Map<String, DaySchedule>? daySchedules,
    this.createdAt,
    this.updatedAt,
    this.lastExecutedAt,
  }) : daySchedules =
           daySchedules ?? {for (final d in kAllDays) d: DaySchedule(day: d)};

  /// Total enabled entries across all days
  int get configuredDeviceCount {
    int count = 0;
    for (final ds in daySchedules.values) {
      count += ds.enabledCount;
    }
    return count;
  }

  /// Total entries across all days
  int get totalEntryCount {
    int count = 0;
    for (final ds in daySchedules.values) {
      count += ds.entries.length;
    }
    return count;
  }

  /// Days that have at least one entry
  List<String> get activeDays {
    return daySchedules.entries
        .where((e) => e.value.entries.isNotEmpty)
        .map((e) => e.key)
        .toList();
  }

  Routine copyWith({
    String? id,
    String? name,
    String? type,
    bool? isEnabled,
    String? timezone,
    Map<String, DaySchedule>? daySchedules,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastExecutedAt,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      timezone: timezone ?? this.timezone,
      daySchedules:
          daySchedules ??
          this.daySchedules.map((k, v) => MapEntry(k, v.copyWith())),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isEnabled': isEnabled,
      'timezone': timezone,
      'daySchedules': daySchedules.map((k, v) => MapEntry(k, v.toJson())),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastExecutedAt': lastExecutedAt?.toIso8601String(),
      '_schemaVersion': 2, // Marks new per-day format
    };
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    // ── Schema v2 (new per-day format) ──
    if (json['daySchedules'] is Map) {
      final rawSchedules = json['daySchedules'] as Map;
      final Map<String, DaySchedule> schedules = {};
      for (final day in kAllDays) {
        if (rawSchedules.containsKey(day) && rawSchedules[day] is Map) {
          schedules[day] = DaySchedule.fromJson(
            Map<String, dynamic>.from(rawSchedules[day] as Map),
          );
        } else {
          schedules[day] = DaySchedule(day: day);
        }
      }
      return Routine(
        id: json['id']?.toString() ?? 'good_morning_routine_1',
        name: json['name']?.toString() ?? 'Good Morning Routine',
        type: json['type']?.toString() ?? 'morning_routine',
        isEnabled: json['isEnabled'] as bool? ?? true,
        timezone: json['timezone']?.toString() ?? 'UTC',
        daySchedules: schedules,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
        lastExecutedAt: json['lastExecutedAt'] != null
            ? DateTime.tryParse(json['lastExecutedAt'].toString())
            : null,
      );
    }

    // ── Schema v1 MIGRATION (old flat format with turnOnTime / deviceActions) ──
    final onTime = json['turnOnTime']?.toString() ?? '07:00 AM';
    final offTime = json['turnOffTime']?.toString() ?? '09:30 AM';
    final repeatDays = json['repeatDays'] is List
        ? (json['repeatDays'] as List)
              .map((e) => _normalizeDay(e.toString()))
              .toList()
        : kAllDays;

    final Map<String, DaySchedule> migrated = {
      for (final d in kAllDays) d: DaySchedule(day: d),
    };

    // Convert old deviceActions into ScheduleEntries on the active repeat days
    if (json['deviceActions'] is List) {
      final oldActions = (json['deviceActions'] as List)
          .map((item) {
            if (item is Map) return Map<String, dynamic>.from(item);
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      for (final day in repeatDays) {
        final normalDay = _normalizeDay(day);
        final entries = <ScheduleEntry>[];
        for (final actionJson in oldActions) {
          final isIncluded = actionJson['isIncluded'] as bool? ?? true;
          if (!isIncluded) continue; // skip excluded devices

          DeviceType parseType(String? t) => DeviceType.values.firstWhere(
            (v) => v.name == t,
            orElse: () => DeviceType.light,
          );

          final deviceOnTime = actionJson['onTime']?.toString();
          final deviceOffTime = actionJson['offTime']?.toString();

          entries.add(
            ScheduleEntry(
              id: '${normalDay}_${actionJson['deviceId']}_migrated',
              deviceId: actionJson['deviceId']?.toString() ?? '',
              deviceName: actionJson['deviceName']?.toString() ?? 'Device',
              roomId: actionJson['roomId']?.toString() ?? 'room_default',
              roomName: actionJson['roomName']?.toString() ?? 'Room',
              deviceType: parseType(actionJson['deviceType']?.toString()),
              onTime: (deviceOnTime != null && deviceOnTime.trim().isNotEmpty)
                  ? deviceOnTime
                  : onTime,
              offTime:
                  (deviceOffTime != null && deviceOffTime.trim().isNotEmpty)
                  ? deviceOffTime
                  : offTime,
              isEnabled: true,
              startAction: actionJson['startAction']?.toString() ?? 'on',
              customSettings: actionJson['customSettings'] is Map
                  ? Map<String, dynamic>.from(
                      actionJson['customSettings'] as Map,
                    )
                  : {},
            ),
          );
        }
        migrated[normalDay] = DaySchedule(day: normalDay, entries: entries);
      }
    }

    return Routine(
      id: json['id']?.toString() ?? 'good_morning_routine_1',
      name: json['name']?.toString() ?? 'Good Morning Routine',
      type: json['type']?.toString() ?? 'morning_routine',
      isEnabled: json['isEnabled'] as bool? ?? true,
      timezone: json['timezone']?.toString() ?? 'UTC',
      daySchedules: migrated,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      lastExecutedAt: json['lastExecutedAt'] != null
          ? DateTime.tryParse(json['lastExecutedAt'].toString())
          : null,
    );
  }

  static String _normalizeDay(String raw) {
    final clean = raw.trim().toUpperCase();
    if (clean.startsWith('MON') || clean == 'M') return 'MON';
    if (clean.startsWith('TUE')) return 'TUE';
    if (clean.startsWith('WED') || clean == 'W') return 'WED';
    if (clean.startsWith('THU')) return 'THU';
    if (clean.startsWith('FRI') || clean == 'F') return 'FRI';
    if (clean.startsWith('SAT')) return 'SAT';
    if (clean.startsWith('SUN')) return 'SUN';
    return clean;
  }
}
