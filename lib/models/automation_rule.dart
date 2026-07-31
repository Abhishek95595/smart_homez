class AutomationRule {
  final String id;
  final String name;
  final String trigger;
  final String action;
  final String repeat;
  final String scene;
  final bool enabled;

  const AutomationRule({
    required this.id,
    required this.name,
    required this.trigger,
    required this.action,
    required this.repeat,
    required this.scene,
    this.enabled = true,
  });

  AutomationRule copyWith({bool? enabled}) {
    return AutomationRule(
      id: id,
      name: name,
      trigger: trigger,
      action: action,
      repeat: repeat,
      scene: scene,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trigger': trigger,
    'action': action,
    'repeat': repeat,
    'scene': scene,
    'enabled': enabled,
  };

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'] as String,
      name: json['name'] as String,
      trigger: json['trigger'] as String? ?? '08:00',
      action: json['action'] as String? ?? 'Run selected devices',
      repeat: json['repeat'] as String? ?? 'Daily',
      scene: json['scene'] as String? ?? 'Custom',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
