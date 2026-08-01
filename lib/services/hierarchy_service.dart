import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/home_model.dart';
import '../models/floor_model.dart';
import '../models/room_model.dart';

class HierarchyService {
  final ApiClient _api = ApiClient();

  /// GET /api/v1/clients/{clientId}/homes (Phase 3)
  Future<List<HomeModel>> getHomes(String clientId) async {
    final response = await _api.get(ApiEndpoints.clientHomes(clientId));
    final dynamic data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return (data['data'] as List).map((i) => HomeModel.fromJson(i)).toList();
    } else if (data is List) {
      return data.map((i) => HomeModel.fromJson(i)).toList();
    }
    return [];
  }

  /// POST /api/v1/clients/{clientId}/homes (Phase 8)
  Future<HomeModel?> createHome(
    String clientId,
    String name,
    String address,
  ) async {
    final response = await _api.post(
      ApiEndpoints.clientHomes(clientId),
      data: {'name': name, 'address': address},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return HomeModel.fromJson(data['data']);
      }
      return HomeModel.fromJson(data);
    }
    return null;
  }

  /// DELETE /api/v1/clients/{clientId}/homes/{homeId} (Phase 8)
  Future<bool> deleteHome(String clientId, String homeId) async {
    final response = await _api.delete(
      '/api/v1/clients/$clientId/homes/$homeId',
    );
    return response.statusCode == 200;
  }

  /// GET /api/v1/clients/{clientId}/homes/{homeId}/floors (Phase 4)
  Future<List<FloorModel>> getFloors(String clientId, String homeId) async {
    final response = await _api.get(ApiEndpoints.homeFloors(clientId, homeId));
    final dynamic data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return (data['data'] as List).map((i) => FloorModel.fromJson(i)).toList();
    } else if (data is List) {
      return data.map((i) => FloorModel.fromJson(i)).toList();
    }
    return [];
  }

  /// POST /api/v1/clients/{clientId}/homes/{homeId}/floors (Phase 8)
  Future<FloorModel?> createFloor(
    String clientId,
    String homeId,
    String name,
    int number,
  ) async {
    final response = await _api.post(
      ApiEndpoints.homeFloors(clientId, homeId),
      data: {'name': name, 'floor_number': number},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return FloorModel.fromJson(data['data']);
      }
      return FloorModel.fromJson(data);
    }
    return null;
  }

  /// GET /api/v1/clients/{clientId}/homes/{homeId}/floors/{floorId}/rooms (Phase 5)
  Future<List<RoomModel>> getRooms(
    String clientId,
    String homeId,
    String floorId,
  ) async {
    final response = await _api.get(
      ApiEndpoints.floorRooms(clientId, homeId, floorId),
    );
    final dynamic data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return (data['data'] as List).map((i) => RoomModel.fromJson(i)).toList();
    } else if (data is List) {
      return data.map((i) => RoomModel.fromJson(i)).toList();
    }
    return [];
  }

  /// POST /api/v1/clients/{clientId}/homes/{homeId}/floors/{floorId}/rooms (Phase 8)
  Future<RoomModel?> createRoom(
    String clientId,
    String homeId,
    String floorId,
    String name,
  ) async {
    final response = await _api.post(
      ApiEndpoints.floorRooms(clientId, homeId, floorId),
      data: {'name': name},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return RoomModel.fromJson(data['data']);
      }
      return RoomModel.fromJson(data);
    }
    return null;
  }
}
