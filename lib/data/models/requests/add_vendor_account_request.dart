/// Request model for adding a vendor account based on Swagger schema.
class AddVendorAccountRequest {
  const AddVendorAccountRequest({
    required this.vendorDefinitionId,
    this.apiKey,
  });

  final String vendorDefinitionId;
  final String? apiKey;

  Map<String, dynamic> toJson() => {
    'vendor_definition_id': vendorDefinitionId,
    'api_key': apiKey,
  };
}
