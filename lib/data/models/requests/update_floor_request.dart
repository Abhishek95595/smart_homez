class UpdateFloorRequest {
  const UpdateFloorRequest({required this.name, required this.floorNumber});

  final String name;
  final int floorNumber;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'floor_number': floorNumber,
  };
}
