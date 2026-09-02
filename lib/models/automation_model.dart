import '../core/utils/command_utils.dart';

class AutomationConditionModel {
  final String? conditionType;
  final String? operator;
  final String? targetDeviceId;
  final String? propertyName;
  final String? expectedValue;
  final String? timeValue;
  final String? endTimeValue;
  final int? offsetMinutes;
  final int sortOrder;

  const AutomationConditionModel({
    this.conditionType,
    this.operator,
    this.targetDeviceId,
    this.propertyName,
    this.expectedValue,
    this.timeValue,
    this.endTimeValue,
    this.offsetMinutes,
    this.sortOrder = 0,
  });

  factory AutomationConditionModel.fromJson(Map<String, dynamic> json) {
    return AutomationConditionModel(
      conditionType: json['conditionType']?.toString(),
      operator: json['operator']?.toString(),
      targetDeviceId: json['targetDeviceId']?.toString(),
      propertyName: json['propertyName']?.toString(),
      expectedValue: json['expectedValue']?.toString(),
      timeValue: json['timeValue']?.toString(),
      endTimeValue: json['endTimeValue']?.toString(),
      offsetMinutes: _toInt(json['offsetMinutes']),
      sortOrder: _toInt(json['sortOrder']) ?? 0,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    if (conditionType != null) 'conditionType': conditionType,
    if (operator != null) 'operator': operator,
    if (targetDeviceId != null) 'targetDeviceId': targetDeviceId,
    if (propertyName != null) 'propertyName': propertyName,
    if (expectedValue != null) 'expectedValue': expectedValue,
    if (timeValue != null) 'timeValue': timeValue,
    if (endTimeValue != null) 'endTimeValue': endTimeValue,
    if (offsetMinutes != null) 'offsetMinutes': offsetMinutes,
    'sortOrder': sortOrder,
  };
}

class AutomationActionModel {
  final String? actionType;
  final String? targetDeviceId;
  final String? command;
  final String? commandValue;
  final int? delaySeconds;
  final String? activateSceneId;
  final bool toggleOnActivate;
  final int sortOrder;

  const AutomationActionModel({
    this.actionType,
    this.targetDeviceId,
    this.command,
    this.commandValue,
    this.delaySeconds,
    this.activateSceneId,
    this.toggleOnActivate = false,
    this.sortOrder = 0,
  });

  factory AutomationActionModel.fromJson(Map<String, dynamic> json) {
    return AutomationActionModel(
      actionType: json['actionType']?.toString(),
      targetDeviceId: json['targetDeviceId']?.toString(),
      command: json['command'] != null
          ? normalizeDeviceCommand(json['command'].toString())
          : null,
      commandValue: json['commandValue']?.toString(),
      delaySeconds: _toInt(json['delaySeconds']),
      activateSceneId: json['activateSceneId']?.toString(),
      toggleOnActivate: json['toggleOnActivate'] == true,
      sortOrder: _toInt(json['sortOrder']) ?? 0,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    if (actionType != null) 'actionType': actionType,
    if (targetDeviceId != null) 'targetDeviceId': targetDeviceId,
    if (command != null) 'command': normalizeDeviceCommand(command!),
    if (commandValue != null) 'commandValue': commandValue,
    if (delaySeconds != null) 'delaySeconds': delaySeconds,
    if (activateSceneId != null) 'activateSceneId': activateSceneId,
    'toggleOnActivate': toggleOnActivate,
    'sortOrder': sortOrder,
  };
}

class AutomationModel {
  const AutomationModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.conditions = const [],
    this.actions = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final List<AutomationConditionModel> conditions;
  final List<AutomationActionModel> actions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AutomationModel.fromJson(Map<String, dynamic> json) {
    return AutomationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString()
          : 'Untitled Automation',
      description: json['description']?.toString(),
      isActive: json['isActive'] == true || json['is_active'] == true,
      conditions: _parseConditions(json['conditions']),
      actions: _parseActions(json['actions']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  static List<AutomationConditionModel> _parseConditions(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (e) =>
              AutomationConditionModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  static List<AutomationActionModel> _parseActions(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (e) => AutomationActionModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'isActive': isActive,
    'conditions': conditions.map((e) => e.toJson()).toList(),
    'actions': actions.map((e) => e.toJson()).toList(),
    if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
  };
}
