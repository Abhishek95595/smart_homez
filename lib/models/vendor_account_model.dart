class VendorAccountModel {
  const VendorAccountModel({
    required this.id,
    required this.vendorName,
    required this.createdAt,
  });

  final String id;
  final String vendorName;
  final DateTime createdAt;

  factory VendorAccountModel.fromJson(Map<String, dynamic> json) {
    return VendorAccountModel(
      id: json['id']?.toString() ?? '',
      vendorName: json['vendor_name']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
