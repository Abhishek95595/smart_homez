class AutomationToggleRequest {
  const AutomationToggleRequest({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => {'isActive': isActive};
}
