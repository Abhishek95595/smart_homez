class UpdateHomeRequest {
  const UpdateHomeRequest({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'address': address.trim(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}
