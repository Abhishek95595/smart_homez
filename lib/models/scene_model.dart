class SceneActionModel {
  final String deviceId;
  final String command;
  final dynamic value;

  SceneActionModel({required this.deviceId, required this.command, this.value});

  factory SceneActionModel.fromJson(Map<String, dynamic> json) {
    return SceneActionModel(
      deviceId: (json['deviceId'] ?? json['device_id'] ?? '').toString(),
      command: (json['command'] ?? 'on').toString(),
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'command': command,
      if (value != null) 'value': value,
    };
  }
}

class SceneModel {
  final String id;
  final String name;
  final String? clientId;
  final List<SceneActionModel> actions;

  SceneModel({
    required this.id,
    required this.name,
    this.clientId,
    this.actions = const [],
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
      name: (json['name'] ?? json['scene_name'] ?? 'Custom Scene').toString(),
      clientId: json['client_id']?.toString() ?? json['clientId']?.toString(),
      actions: parsedActions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (clientId != null) 'client_id': clientId,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }
}
