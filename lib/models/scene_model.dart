import '../core/utils/command_utils.dart';

class SceneActionModel {
  final String deviceId;
  final String command;
  final dynamic commandValue;
  final bool toggleOnActivate;
  final int sortOrder;
  final int delaySeconds;

  SceneActionModel({
    required this.deviceId,
    required String command,
    dynamic commandValue,
    dynamic value,
    this.toggleOnActivate = false,
    this.sortOrder = 0,
    this.delaySeconds = 0,
  }) : command = normalizeDeviceCommand(command),
       commandValue = commandValue ?? value;

  /// Backwards-compatible getter for legacy value field
  dynamic get value => commandValue;

  factory SceneActionModel.fromJson(Map<String, dynamic> json) {
    return SceneActionModel(
      deviceId: (json['deviceId'] ?? json['device_id'] ?? '').toString(),
      command: (json['command'] ?? 'on').toString(),
      commandValue:
          json['commandValue'] ?? json['command_value'] ?? json['value'],
      toggleOnActivate:
          json['toggleOnActivate'] ?? json['toggle_on_activate'] ?? false,
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) is num
          ? (json['sortOrder'] ?? json['sort_order'] ?? 0).toInt()
          : 0,
      delaySeconds: (json['delaySeconds'] ?? json['delay_seconds'] ?? 0) is num
          ? (json['delaySeconds'] ?? json['delay_seconds'] ?? 0).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'command': normalizeDeviceCommand(command),
      'commandValue': commandValue?.toString(),
      'toggleOnActivate': toggleOnActivate,
      'sortOrder': sortOrder,
      'delaySeconds': delaySeconds,
    };
  }
}

class SceneModel {
  final String id;
  final String? tenantId;
  final String? clientId;
  final String name;
  final String? description;
  final String? icon;
  final bool isFavorite;
  final List<SceneActionModel> actions;
  final int recurrenceDays;
  final String? scheduledTime;
  final int timezoneOffsetMinutes;
  final bool isScheduleEnabled;

  SceneModel({
    required this.id,
    required this.name,
    this.tenantId,
    this.clientId,
    this.description,
    this.icon,
    this.isFavorite = false,
    this.actions = const [],
    this.recurrenceDays = 0,
    this.scheduledTime,
    this.timezoneOffsetMinutes = 330,
    this.isScheduleEnabled = false,
  });

  factory SceneModel.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];
    List<SceneActionModel> parsedActions = [];
    if (rawActions is List) {
      parsedActions = rawActions
          .whereType<Map>()
          .map(
            (item) =>
                SceneActionModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    return SceneModel(
      id: (json['id'] ?? json['scene_id'] ?? '').toString(),
      tenantId: json['tenantId']?.toString() ?? json['tenant_id']?.toString(),
      clientId: json['clientId']?.toString() ?? json['client_id']?.toString(),
      name: (json['name'] ?? json['scene_name'] ?? 'Custom Scene').toString(),
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      isFavorite: json['isFavorite'] ?? json['is_favorite'] ?? false,
      actions: parsedActions,
      recurrenceDays:
          (json['recurrenceDays'] ?? json['recurrence_days'] ?? 0) is num
          ? (json['recurrenceDays'] ?? json['recurrence_days'] ?? 0).toInt()
          : 0,
      scheduledTime:
          json['scheduledTime']?.toString() ??
          json['scheduled_time']?.toString(),
      timezoneOffsetMinutes:
          (json['timezoneOffsetMinutes'] ??
                  json['timezone_offset_minutes'] ??
                  330)
              is num
          ? (json['timezoneOffsetMinutes'] ??
                    json['timezone_offset_minutes'] ??
                    330)
                .toInt()
          : 330,
      isScheduleEnabled:
          json['isScheduleEnabled'] ?? json['is_schedule_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tenantId != null) 'tenantId': tenantId,
      if (clientId != null) 'clientId': clientId,
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      'isFavorite': isFavorite,
      'actions': actions.map((a) => a.toJson()).toList(),
      'recurrenceDays': recurrenceDays,
      'scheduledTime': scheduledTime,
      'timezoneOffsetMinutes': timezoneOffsetMinutes,
      'isScheduleEnabled': isScheduleEnabled,
    };
  }
}

class SceneExecutionStatus {
  final String? sceneId;
  final String status;
  final int currentStep;
  final int totalSteps;
  final double percentage;
  final bool isIdle;

  const SceneExecutionStatus({
    this.sceneId,
    required this.status,
    required this.currentStep,
    required this.totalSteps,
    required this.percentage,
    required this.isIdle,
  });

  factory SceneExecutionStatus.fromJson(Map<String, dynamic> json) {
    final current = json['current_step'] ?? json['currentStep'] ?? 0;
    final total = json['total_steps'] ?? json['totalSteps'] ?? 0;
    final pct = json['percentage'] ?? json['progress'] ?? 0.0;
    final currentStep = (current is num) ? current.toInt() : 0;
    final totalSteps = (total is num) ? total.toInt() : 0;
    final percentage = (pct is num) ? pct.toDouble() : 0.0;
    final status = (json['status'] ?? 'idle').toString();

    return SceneExecutionStatus(
      sceneId: (json['scene_id'] ?? json['sceneId'])?.toString(),
      status: status,
      currentStep: currentStep,
      totalSteps: totalSteps,
      percentage: percentage,
      isIdle: status.toLowerCase() == 'idle' || totalSteps == 0,
    );
  }

  factory SceneExecutionStatus.idle({String? sceneId}) => SceneExecutionStatus(
    sceneId: sceneId,
    status: 'idle',
    currentStep: 0,
    totalSteps: 0,
    percentage: 0.0,
    isIdle: true,
  );

  Map<String, dynamic> toJson() => {
    if (sceneId != null) 'scene_id': sceneId,
    'status': status,
    'current_step': currentStep,
    'total_steps': totalSteps,
    'percentage': percentage,
    'is_idle': isIdle,
  };
}
