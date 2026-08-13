class UpdateDeviceRequest {
  const UpdateDeviceRequest({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name.trim()};
}
