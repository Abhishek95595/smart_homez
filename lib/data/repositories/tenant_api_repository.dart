import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_endpoints.dart';
import '../../models/api_models.dart';
import '../../models/automation_model.dart';
import '../../models/client_model.dart';
import '../../models/device_model.dart';
import '../../models/home_model.dart';
import '../../models/vendor_account_model.dart';
import '../../models/vendor_node_model.dart';
import '../../services/api_service.dart';
import '../models/requests/add_vendor_account_request.dart';
import '../models/requests/automation_toggle_request.dart';
import '../models/requests/create_automation_request.dart';
import '../models/requests/move_device_request.dart';
import '../models/requests/pair_vendor_node_request.dart';
import '../models/requests/update_device_request.dart';
import '../models/requests/update_floor_request.dart';
import '../models/requests/update_home_request.dart';
import '../models/requests/update_room_request.dart';

class TenantApiRepository {
  TenantApiRepository({ApiService? apiService})
    : _api = apiService ?? ApiService();

  final ApiService _api;

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  Exception mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    debugPrint('API status: $statusCode');
    debugPrint('API response: $responseData');
    debugPrint('API path: ${error.requestOptions.path}');
    debugPrint('API URI: ${error.requestOptions.uri}');

    if (responseData is Map<String, dynamic>) {
      final apiError = responseData['error'];

      if (apiError is Map<String, dynamic>) {
        final message = apiError['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return Exception(message);
        }
      }

      if (apiError is String && apiError.isNotEmpty) {
        return Exception(apiError);
      }

      final message = responseData['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return Exception(message);
      }
    }

    switch (statusCode) {
      case 400:
        return Exception('Invalid vendor request.');
      case 401:
        return Exception('Authentication expired.');
      case 403:
        return Exception('You do not have permission to access vendor data.');
      case 404:
        return Exception('Vendor resource was not found.');
      case 500:
        return Exception('Vendor service is currently unavailable.');
      default:
        return Exception('Unable to connect to the vendor service.');
    }
  }

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> map = Map<String, dynamic>.from(responseData);
    final success = map['success'];

    if (success == false) {
      final error = map['error'];
      if (error is Map) {
        throw Exception(error['message']?.toString() ?? 'API request failed.');
      }
      throw Exception(error?.toString() ?? 'API request failed.');
    }

    final data = map['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return map;
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }

    if (responseData is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(responseData);
      final success = map['success'];
      if (success == false) {
        final error = map['error'];
        if (error is Map) {
          throw Exception(
            error['message']?.toString() ?? 'API request failed.',
          );
        }
        throw Exception(error?.toString() ?? 'API request failed.');
      }

      final data = map['data'];
      if (data is List) {
        return data;
      }
    }

    return const <dynamic>[];
  }

  // ============================================================
  // CLIENTS
  // ============================================================

  Future<ClientResolveResponse?> resolveClient({
    String? email,
    String? phone,
    String? name,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.resolveClient,
        body: ClientResolveRequest(
          email: email,
          phone: phone,
          name: name,
        ).toJson(),
      );

      final data = _extractData(response.data);
      return ClientResolveResponse.fromJson(data);
    } on DioException catch (e) {
      debugPrint('[TenantApiRepository] Resolve client error: $e');
      return null;
    } catch (e) {
      debugPrint('[TenantApiRepository] Resolve client error: $e');
      rethrow;
    }
  }

  Future<List<ClientModel>> getClients() async {
    try {
      final response = await _api.get(ApiEndpoints.clients);
      return _extractList(
        response.data,
      ).whereType<Map<String, dynamic>>().map(ClientModel.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<ClientModel> getClient(String clientId) async {
    try {
      final response = await _api.get(ApiEndpoints.client(clientId));
      return ClientModel.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ============================================================
  // HOMES
  // ============================================================

  Future<List<ApiHomeResponse>> getHomes(String clientId) async {
    try {
      final response = await _api.get(ApiEndpoints.clientHomes(clientId));
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(ApiHomeResponse.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw mapDioException(e);
    }
  }

  Future<ApiHomeResponse?> createHome(
    String clientId, {
    required String name,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.clientHomes(clientId),
        body: CreateHomeRequest(
          name: name,
          address: address,
          latitude: latitude,
          longitude: longitude,
        ).toJson(),
      );
      return ApiHomeResponse.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<HomeModel> getHome({
    required String clientId,
    required String homeId,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.clientHome(clientId, homeId),
      );
      return HomeModel.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> updateHome({
    required String clientId,
    required String homeId,
    required UpdateHomeRequest request,
  }) async {
    try {
      final response = await _api.put(
        ApiEndpoints.clientHome(clientId, homeId),
        body: request.toJson(),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteHome({
    required String clientId,
    required String homeId,
  }) async {
    try {
      final response = await _api.delete(
        ApiEndpoints.clientHome(clientId, homeId),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ============================================================
  // FLOORS
  // ============================================================

  Future<List<ApiFloorResponse>> getFloors(
    String clientId,
    String homeId,
  ) async {
    try {
      final response = await _api.get(
        ApiEndpoints.homeFloors(clientId, homeId),
      );
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(ApiFloorResponse.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw mapDioException(e);
    }
  }

  Future<ApiFloorResponse?> createFloor(
    String clientId,
    String homeId, {
    required String name,
    required int floorNumber,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.homeFloors(clientId, homeId),
        body: CreateFloorRequest(name: name, floorNumber: floorNumber).toJson(),
      );
      return ApiFloorResponse.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> updateFloor({
    required String clientId,
    required String homeId,
    required String floorId,
    required UpdateFloorRequest request,
  }) async {
    try {
      final response = await _api.put(
        ApiEndpoints.homeFloor(clientId, homeId, floorId),
        body: request.toJson(),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteFloor({
    required String clientId,
    required String homeId,
    required String floorId,
  }) async {
    try {
      final response = await _api.delete(
        ApiEndpoints.homeFloor(clientId, homeId, floorId),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ============================================================
  // ROOMS
  // ============================================================

  Future<List<ApiRoomResponse>> getRooms(
    String clientId,
    String homeId,
    String floorId,
  ) async {
    try {
      final response = await _api.get(
        ApiEndpoints.floorRooms(clientId, homeId, floorId),
      );
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(ApiRoomResponse.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw mapDioException(e);
    }
  }

  Future<ApiRoomResponse?> createRoom(
    String clientId,
    String homeId,
    String floorId, {
    required String name,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.floorRooms(clientId, homeId, floorId),
        body: CreateRoomRequest(name: name).toJson(),
      );
      return ApiRoomResponse.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> updateRoom({
    required String clientId,
    required String homeId,
    required String floorId,
    required String roomId,
    required UpdateRoomRequest request,
  }) async {
    try {
      final response = await _api.put(
        ApiEndpoints.floorRoom(clientId, homeId, floorId, roomId),
        body: request.toJson(),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteRoom({
    required String clientId,
    required String homeId,
    required String floorId,
    required String roomId,
  }) async {
    try {
      final response = await _api.delete(
        ApiEndpoints.floorRoom(clientId, homeId, floorId, roomId),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ============================================================
  // DEVICES
  // ============================================================

  Future<List<ApiDeviceResponse>> getDevices(
    String clientId, {
    String? homeId,
    String? roomId,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (homeId != null && homeId.trim().isNotEmpty) {
        queryParameters['homeId'] = homeId.trim();
      }
      if (roomId != null && roomId.trim().isNotEmpty) {
        queryParameters['roomId'] = roomId.trim();
      }

      final response = await _api.get(
        ApiEndpoints.clientDevices(clientId),
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(ApiDeviceResponse.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw mapDioException(e);
    }
  }

  Future<DeviceModel> getDevice({
    required String clientId,
    required String deviceId,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.clientDevice(clientId, deviceId),
      );
      return DeviceModel.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> updateDeviceName({
    required String clientId,
    required String deviceId,
    required String name,
  }) async {
    try {
      final response = await _api.put(
        ApiEndpoints.clientDevice(clientId, deviceId),
        body: UpdateDeviceRequest(name: name).toJson(),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteDevice({
    required String clientId,
    required String deviceId,
  }) async {
    try {
      final response = await _api.delete(
        ApiEndpoints.clientDevice(clientId, deviceId),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> moveDevice({
    required String clientId,
    required String deviceId,
    required MoveDeviceRequest request,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.moveDevice(clientId, deviceId),
        body: request.toJson(),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<bool> executeDeviceCommand({
    required String clientId,
    required String deviceId,
    required String command,
    dynamic value,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.deviceCommand(clientId, deviceId),
        body: {'command': command, 'value': value},
      );
      _extractData(response.data);
      return true;
    } on DioException catch (e) {
      debugPrint('[TenantApiRepository] Device command error: $e');
      return false;
    }
  }

  // Helper methods for common commands
  Future<bool> turnDeviceOn({
    required String clientId,
    required String deviceId,
  }) => executeDeviceCommand(
    clientId: clientId,
    deviceId: deviceId,
    command: 'on',
  );

  Future<bool> turnDeviceOff({
    required String clientId,
    required String deviceId,
  }) => executeDeviceCommand(
    clientId: clientId,
    deviceId: deviceId,
    command: 'off',
  );

  Future<bool> toggleDevice({
    required String clientId,
    required String deviceId,
  }) => executeDeviceCommand(
    clientId: clientId,
    deviceId: deviceId,
    command: 'toggle',
  );

  // ============================================================
  // VENDOR METHODS
  // ============================================================

  Future<List<VendorAccountModel>> getVendorAccounts(String clientId) async {
    try {
      final response = await _api.get(ApiEndpoints.vendorAccounts(clientId));
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(VendorAccountModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<VendorAccountModel> addVendorAccount({
    required String clientId,
    required AddVendorAccountRequest request,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.vendorAccounts(clientId),
        body: request.toJson(),
      );
      return VendorAccountModel.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteVendorAccount({
    required String clientId,
    required String accountId,
  }) async {
    try {
      final response = await _api.delete(
        ApiEndpoints.vendorAccount(clientId, accountId),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> syncVendorAccounts(String clientId) async {
    try {
      final response = await _api.post(ApiEndpoints.vendorSync(clientId));
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<VendorNodeModel>> getUnpairedVendorNodes(String clientId) async {
    try {
      final response = await _api.get(ApiEndpoints.vendorNodes(clientId));
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(VendorNodeModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> pairVendorNode({
    required String clientId,
    required String nodeId,
    required PairVendorNodeRequest request,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.pairVendorNode(clientId, nodeId),
        body: request.toJson(),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ============================================================
  // AUTOMATIONS & SCENES
  // ============================================================

  Future<List<AutomationModel>> getAutomations() async {
    try {
      final response = await _api.get(ApiEndpoints.automations);
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(AutomationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AutomationModel> createAutomation(
    CreateAutomationRequest request,
  ) async {
    try {
      final response = await _api.post(
        ApiEndpoints.automations,
        body: request.toJson(),
      );
      return AutomationModel.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AutomationModel> getAutomation(String id) async {
    try {
      final response = await _api.get(ApiEndpoints.automation(id));
      return AutomationModel.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AutomationModel> updateAutomation({
    required String automationId,
    required CreateAutomationRequest request,
  }) async {
    try {
      final response = await _api.put(
        ApiEndpoints.automation(automationId),
        body: request.toJson(),
      );
      return AutomationModel.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteAutomation(String id) async {
    try {
      final response = await _api.delete(ApiEndpoints.automation(id));
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> toggleAutomation({
    required String automationId,
    required bool isActive,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.toggleAutomation(automationId),
        body: AutomationToggleRequest(isActive: isActive).toJson(),
      );
      _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<ApiSceneResponse>> getScenes() async {
    try {
      final response = await _api.get('/api/v1/scenes');
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(ApiSceneResponse.fromJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<bool> activateScene(String sceneId) async {
    try {
      final response = await _api.post('/api/v1/scenes/$sceneId/activate');
      _extractData(response.data);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>?> setupHomeFromTemplate({
    required String template,
    required String homeName,
    String? address,
    String? structureType,
    List<Map<String, dynamic>>? customRooms,
    List<Map<String, dynamic>>? customFloors,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final payload = <String, dynamic>{
        'template': template,
        'home_name': homeName.trim(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
        if (structureType != null && structureType.isNotEmpty)
          'structure_type': structureType,
        if (customRooms != null && customRooms.isNotEmpty) 'rooms': customRooms,
        if (customFloors != null && customFloors.isNotEmpty)
          'floors': customFloors,
        ...?extraData,
      };

      final response = await _api.post(
        ApiEndpoints.homesTemplateSetup,
        data: payload,
      );
      return _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<bool> bulkAssignDevicesToRooms(
    List<Map<String, String>> assignments,
  ) async {
    try {
      final response = await _api.post(
        ApiEndpoints.bulkAssignRooms,
        data: {'assignments': assignments},
      );
      final data = _extractData(response.data);
      return data['success'] != false;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> bulkAssignDevicesToRoomsWithResult(
    List<Map<String, String>> assignments,
  ) async {
    try {
      final response = await _api.post(
        ApiEndpoints.bulkAssignRooms,
        data: {'assignments': assignments},
      );
      return _extractData(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getUnassignedDevices(String homeId) async {
    try {
      final response = await _api.get(ApiEndpoints.unassignedDevices(homeId));
      final list = _extractList(response.data);
      return list.whereType<Map<String, dynamic>>().toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
