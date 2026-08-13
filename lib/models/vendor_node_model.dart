class VendorNodeModel {
  const VendorNodeModel({
    required this.id,
    required this.name,
    this.type,
    this.vendorId,
  });

  final String id;
  final String name;
  final String? type;
  final String? vendorId;

  factory VendorNodeModel.fromJson(Map<String, dynamic> json) {
    return VendorNodeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Node',
      type: json['type']?.toString(),
      vendorId: json['vendor_id']?.toString(),
    );
  }
}
