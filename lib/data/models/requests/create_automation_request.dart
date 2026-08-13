class CreateAutomationRequest {
  const CreateAutomationRequest({
    this.tenantId,
    this.clientId,
    this.name,
    this.description,
    this.isActive = true,
    this.activateSceneId,
    this.conditions,
    this.actions,
  });

  final String? tenantId;
  final String? clientId;
  final String? name;
  final String? description;
  final bool isActive;
  final String? activateSceneId;
  final List<CreateAutomationConditionRequest>? conditions;
  final List<CreateAutomationActionRequest>? actions;

  Map<String, dynamic> toJson() => {
    if (tenantId?.trim().isNotEmpty == true) 'tenantId': tenantId!.trim(),
    if (clientId?.trim().isNotEmpty == true) 'clientId': clientId!.trim(),
    if (name?.trim().isNotEmpty == true) 'name': name!.trim(),
    if (description?.trim().isNotEmpty == true)
      'description': description!.trim(),
    'isActive': isActive,
    if (activateSceneId?.trim().isNotEmpty == true)
      'activateSceneId': activateSceneId!.trim(),
    if (conditions != null)
      'conditions': conditions!.map((e) => e.toJson()).toList(),
    if (actions != null) 'actions': actions!.map((e) => e.toJson()).toList(),
  };
}

class CreateAutomationConditionRequest {
  const CreateAutomationConditionRequest({
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

  final String? conditionType;
  final String? operator;
  final String? targetDeviceId;
  final String? propertyName;
  final String? expectedValue;
  final String? timeValue;
  final String? endTimeValue;
  final int? offsetMinutes;
  final int sortOrder;

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

class CreateAutomationActionRequest {
  const CreateAutomationActionRequest({
    this.actionType,
    this.targetDeviceId,
    this.command,
    this.commandValue,
    this.delaySeconds,
    this.activateSceneId,
    this.toggleOnActivate = false,
    this.sortOrder = 0,
  });

  final String? actionType;
  final String? targetDeviceId;
  final String? command;
  final String? commandValue;
  final int? delaySeconds;
  final String? activateSceneId;
  final bool toggleOnActivate;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
    if (actionType != null) 'actionType': actionType,
    if (targetDeviceId != null) 'targetDeviceId': targetDeviceId,
    if (command != null) 'command': command,
    if (commandValue != null) 'commandValue': commandValue,
    if (delaySeconds != null) 'delaySeconds': delaySeconds,
    if (activateSceneId != null) 'activateSceneId': activateSceneId,
    'toggleOnActivate': toggleOnActivate,
    'sortOrder': sortOrder,
  };
}
