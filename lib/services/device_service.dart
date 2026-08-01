import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/device_model.dart';

class DeviceService {
  final ApiClient _api = ApiClient();

  /// GET /api/v1/clients/{clientId}/devices (Phase 6)
  Future<List<DeviceModel>> getDevices(String clientId) async {
    final response = await _api.get(ApiEndpoints.clientDevices(clientId));
    final dynamic data = response.data;

    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return (data['data'] as List)
          .map((i) => DeviceModel.fromJson(i))
          .toList();
    } else if (data is List) {
      return data.map((i) => DeviceModel.fromJson(i)).toList();
    }
    return [];
  }

  /// POST /api/v1/clients/{clientId}/devices/{deviceId}/command (Phase 7)
  Future<bool> sendCommand(
    String clientId,
    String deviceId,
    String command, [
    dynamic value,
  ]) async {
    final response = await _api.post(
      ApiEndpoints.deviceCommand(clientId, deviceId),
      data: {'command': command, 'value': value},
    );
    return response.statusCode == 200;
  }
}
