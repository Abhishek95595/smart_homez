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
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return ClientResolveResponse.fromJson(body['data']);
      }
    }
    return null;
  }

  Future<List<ApiHomeResponse>> getHomes(String clientId) async {
    final response = await _api.get('/api/v1/clients/$clientId/homes');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return (body['data'] as List)
            .map((item) => ApiHomeResponse.fromJson(item))
            .toList();
      }
    }
    return [];
  }

  Future<List<ApiFloorResponse>> getFloors(String clientId, String homeId) async {
    final response = await _api.get('/api/v1/clients/$clientId/homes/$homeId/floors');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return (body['data'] as List)
            .map((item) => ApiFloorResponse.fromJson(item))
            .toList();
      }
    }
    return [];
  }

  Future<List<ApiRoomResponse>> getRooms(String clientId, String homeId, String floorId) async {
    final response = await _api.get('/api/v1/clients/$clientId/homes/$homeId/floors/$floorId/rooms');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return (body['data'] as List)
            .map((item) => ApiRoomResponse.fromJson(item))
            .toList();
      }
    }
    return [];
  }

  Future<List<ApiDeviceResponse>> getDevices(String clientId) async {
    final response = await _api.get('/api/v1/clients/$clientId/devices');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return (body['data'] as List)
            .map((item) => ApiDeviceResponse.fromJson(item))
            .toList();
      }
    }
    return [];
  }

  Future<bool> toggleDevice(String deviceId, {int? state, int? brightness}) async {
    final response = await _api.post(
      '/api/v1/devices/toggle',
      ToggleRequest(deviceId: deviceId, state: state, brightness: brightness),
    );
    return response.statusCode == 200;
  }

  Future<bool> sendDeviceCommand(String clientId, String deviceId, String command, dynamic value) async {
    final response = await _api.post(
      '/api/v1/clients/$clientId/devices/$deviceId/command',
      DeviceCommandRequestV1(command: command, value: value),
    );
    return response.statusCode == 200;
  }

  Future<List<ApiAutomationResponse>> getAutomations() async {
    final response = await _api.get('/api/v1/automations');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return (body['data'] as List)
            .map((item) => ApiAutomationResponse.fromJson(item))
            .toList();
      }
    }
    return [];
  }

  Future<bool> toggleAutomation(String id, bool isActive) async {
    final response = await _api.post(
      '/api/v1/automations/$id/toggle',
      {'isActive': isActive},
    );
    return response.statusCode == 200;
  }

  Future<List<ApiSceneResponse>> getScenes() async {
    final response = await _api.get('/api/v1/scenes');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return (body['data'] as List)
            .map((item) => ApiSceneResponse.fromJson(item))
            .toList();
      }
    }
    return [];
  }

  Future<bool> activateScene(String id) async {
    final response = await _api.post('/api/v1/scenes/$id/activate', {});
    return response.statusCode == 200;
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
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return ApiHomeResponse.fromJson(body['data']);
      }
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
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return ApiFloorResponse.fromJson(body['data']);
      }
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
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return ApiRoomResponse.fromJson(body['data']);
      }
    }
    return null;
  }
}
