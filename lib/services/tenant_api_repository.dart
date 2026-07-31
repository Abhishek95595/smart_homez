import 'dart:convert';
import '../models/api_models.dart';
import 'api_service.dart';

class TenantApiRepository {
  final ApiService _api = ApiService();

  Future<ClientResolveResponse?> resolveClient({
    String? email,
    String? phone,
    String? name,
  }) async {
    final response = await _api.post(
      '/api/v1/clients/resolve',
      ClientResolveRequest(email: email, phone: phone, name: name),
    );

    if (response.statusCode == 200) {
      return ClientResolveResponse.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<ApiHomeResponse?> createHome(
    String clientId, {
    required String name,
    required String address,
    double? lat,
    double? lng,
  }) async {
    final response = await _api.post(
      '/api/v1/clients/$clientId/homes',
      CreateHomeRequest(
        name: name,
        address: address,
        latitude: lat,
        longitude: lng,
      ),
    );

    if (response.statusCode == 200) {
      return ApiHomeResponse.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<ApiFloorResponse?> createFloor(
    String clientId,
    String homeId, {
    required String name,
    required int floorNumber,
  }) async {
    final response = await _api.post(
      '/api/v1/clients/$clientId/homes/$homeId/floors',
      CreateFloorRequest(name: name, floorNumber: floorNumber),
    );

    if (response.statusCode == 200) {
      return ApiFloorResponse.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<ApiRoomResponse?> createRoom(
    String clientId,
    String homeId,
    String floorId, {
    required String name,
  }) async {
    final response = await _api.post(
      '/api/v1/clients/$clientId/homes/$homeId/floors/$floorId/rooms',
      CreateRoomRequest(name: name),
    );

    if (response.statusCode == 200) {
      return ApiRoomResponse.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
