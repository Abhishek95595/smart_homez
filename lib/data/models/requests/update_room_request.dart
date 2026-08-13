class UpdateRoomRequest {
  const UpdateRoomRequest({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name.trim()};
}
